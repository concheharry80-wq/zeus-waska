import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus_waska/core/services/sound_service.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/models/content_item.dart';
import 'package:zeus_waska/models/player.dart';
import 'package:zeus_waska/providers/app_providers.dart';
import 'package:zeus_waska/widgets/neon_widgets.dart';

// ============================================================
// MODO 7: DUELO (REFLEJOS, MEMORIA Y ADIVINANZAS)
// ============================================================
class DuelMode extends ConsumerStatefulWidget {
  final VoidCallback onTriggerConfetti;
  const DuelMode({super.key, required this.onTriggerConfetti});

  @override
  ConsumerState<DuelMode> createState() => _DuelModeState();
}

class _DuelModeState extends ConsumerState<DuelMode> {
  final Random _random = Random();
  Player? _playerA;
  Player? _playerB;
  int _selectedSubgame = 0; // 0: Reflejos, 1: Memoria, 2: Adivinanzas

  // Reflejos
  bool _reflexArmed = false;
  bool _reflexGo = false;
  Timer? _reflexTimer;

  // Memoria
  List<int> _sequence = [];
  bool _showingSequence = false;
  int _activeLit = -1;
  int _stepInput = 0;

  // Adivinanza
  DuelRiddle? _riddle;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_rollDuelists);
  }

  void _rollDuelists() {
    final players = ref.read(gameSessionProvider).players;
    if (players.length < 2) return;
    final shuffled = [...players]..shuffle(_random);
    setState(() {
      _playerA = shuffled[0];
      _playerB = shuffled[1];
      _reflexArmed = false;
      _reflexGo = false;
      _sequence = [];
      _riddle = null;
      _showAnswer = false;
    });
  }

  Future<void> _crownWinner(Player winner) async {
    _reflexTimer?.cancel();
    await ref
        .read(gameSessionProvider.notifier)
        .awardPoints(winner.id, 15, isMinigameWin: true);
    await ref.read(soundServiceProvider).playSfx(SoundEffect.victory);
    widget.onTriggerConfetti();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🏆 ¡${winner.name} ganó el Duelo! (+15 pts)'),
        ),
      );
      _rollDuelists();
    }
  }

  void _startReflex() {
    _reflexTimer?.cancel();
    setState(() {
      _reflexArmed = true;
      _reflexGo = false;
    });
    final delayMs = 1400 + _random.nextInt(2600);
    _reflexTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      ref.read(soundServiceProvider).playSfx(SoundEffect.playerSelected);
      ref.read(soundServiceProvider).vibrateMedium();
      setState(() => _reflexGo = true);
    });
  }

  Future<void> _startMemory() async {
    final seq = List.generate(4, (_) => _random.nextInt(4));
    setState(() {
      _sequence = seq;
      _showingSequence = true;
      _stepInput = 0;
      _activeLit = -1;
    });
    for (final colorIdx in seq) {
      if (!mounted) return;
      setState(() => _activeLit = colorIdx);
      await ref.read(soundServiceProvider).playSfx(SoundEffect.buttonTap);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() => _activeLit = -1);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (mounted) setState(() => _showingSequence = false);
  }

  Future<void> _loadRiddle() async {
    final db = await ref.read(contentDatabaseProvider.future);
    final r = ref.read(contentRepositoryProvider).nextDuelRiddle(db);
    setState(() {
      _riddle = r;
      _showAnswer = false;
    });
  }

  @override
  void dispose() {
    _reflexTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_playerA == null || _playerB == null) {
      return const Center(child: Text('Se necesitan al menos 2 jugadores.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            borderColor: AppColors.warningAmber,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(_playerA!.avatar, style: const TextStyle(fontSize: 30)),
                      Text(
                        _playerA!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.warningAmber,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(_playerB!.avatar, style: const TextStyle(fontSize: 30)),
                      Text(
                        _playerB!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cambiar duelistas',
                  icon: const Icon(Icons.shuffle_rounded),
                  onPressed: _rollDuelists,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Reflejos')),
              ButtonSegment(value: 1, label: Text('Memoria')),
              ButtonSegment(value: 2, label: Text('Adivinanzas')),
            ],
            selected: {_selectedSubgame},
            onSelectionChanged: (s) {
              setState(() => _selectedSubgame = s.first);
              if (s.first == 2 && _riddle == null) _loadRiddle();
            },
          ),
          const SizedBox(height: 16),

          // SUBJUEGO 1: REFLEJOS
          if (_selectedSubgame == 0) ...[
            if (!_reflexArmed)
              NeonButton(
                label: 'INICIAR DUELO DE REFLEJOS',
                icon: Icons.flash_on_rounded,
                colors: const [AppColors.warningAmber, AppColors.neonPink],
                onPressed: _startReflex,
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _reflexGo
                      ? AppColors.neonGreen.withValues(alpha: 0.25)
                      : AppColors.dangerRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _reflexGo ? AppColors.neonGreen : AppColors.dangerRed,
                    width: 2,
                  ),
                ),
                child: Text(
                  _reflexGo ? '⚡ ¡TOCA AHORA!' : '⏳ ESPERA AL VERDE...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _reflexGo ? AppColors.neonGreen : AppColors.dangerRed,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      label: _playerA!.name,
                      height: 76,
                      colors: [_playerA!.color, AppColors.electricPurple],
                      onPressed: () =>
                          _crownWinner(_reflexGo ? _playerA! : _playerB!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeonButton(
                      label: _playerB!.name,
                      height: 76,
                      colors: [_playerB!.color, AppColors.neonPink],
                      onPressed: () =>
                          _crownWinner(_reflexGo ? _playerB! : _playerA!),
                    ),
                  ),
                ],
              ),
            ],
          ],

          // SUBJUEGO 2: MEMORIA
          if (_selectedSubgame == 1) ...[
            GlassCard(
              borderColor: AppColors.electricBlue,
              child: Column(
                children: [
                  const Text(
                    'MEMORIA NEÓN (4 PASOS)',
                    style: TextStyle(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sequence.isEmpty
                        ? 'Observa la secuencia de 4 colores y repítela sin fallar.'
                        : (_showingSequence
                            ? 'Observa atentamente...'
                            : 'Paso ${_stepInput + 1} de ${_sequence.length}'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.0,
                    children: List.generate(4, (idx) {
                      const cols = [
                        AppColors.electricPurple,
                        AppColors.neonPink,
                        AppColors.electricBlue,
                        AppColors.neonGreen,
                      ];
                      final lit = _activeLit == idx;
                      return GestureDetector(
                        onTap: (_sequence.isEmpty || _showingSequence)
                            ? null
                            : () {
                                ref
                                    .read(soundServiceProvider)
                                    .playSfx(SoundEffect.buttonTap);
                                if (_sequence[_stepInput] == idx) {
                                  if (_stepInput + 1 == _sequence.length) {
                                    _crownWinner(_playerA!);
                                  } else {
                                    setState(() => _stepInput++);
                                  }
                                } else {
                                  _crownWinner(_playerB!);
                                }
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: lit
                                ? cols[idx]
                                : cols[idx].withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: cols[idx], width: 2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  NeonButton(
                    label: 'Mostrar secuencia para ${_playerA!.name}',
                    height: 46,
                    onPressed: _showingSequence ? null : _startMemory,
                  ),
                ],
              ),
            ),
          ],

          // SUBJUEGO 3: PREGUNTAS RÁPIDAS / ADIVINANZAS
          if (_selectedSubgame == 2) ...[
            GlassCard(
              borderColor: AppColors.neonPink,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'PREGUNTA RÁPIDA / ADIVINANZA',
                    style: TextStyle(
                      color: AppColors.neonPink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _riddle?.question ?? 'Cargando...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_showAnswer && _riddle != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Respuesta: ${_riddle!.answer}',
                      style: const TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => setState(() => _showAnswer = !_showAnswer),
                    child: Text(_showAnswer ? 'Ocultar' : 'Ver respuesta'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'Ganó ${_playerA!.name}',
                    height: 48,
                    colors: const [AppColors.neonGreen, Color(0xFF00B25A)],
                    onPressed: () => _crownWinner(_playerA!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NeonButton(
                    label: 'Ganó ${_playerB!.name}',
                    height: 48,
                    colors: const [
                      AppColors.electricBlue,
                      AppColors.electricPurple,
                    ],
                    onPressed: () => _crownWinner(_playerB!),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// MODO 10: IMPOSTOR
// ============================================================
class ImpostorMode extends ConsumerStatefulWidget {
  final VoidCallback onTriggerConfetti;
  const ImpostorMode({super.key, required this.onTriggerConfetti});

  @override
  ConsumerState<ImpostorMode> createState() => _ImpostorModeState();
}

class _ImpostorModeState extends ConsumerState<ImpostorMode> {
  final Random _random = Random();
  ImpostorWord? _secretWord;
  String? _impostorId;
  int _revealIdx = 0;
  bool _cardVisible = false;
  String _phase = 'reveal'; // 'reveal' | 'vote' | 'result'
  String? _votedPlayerId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_startNewRound);
  }

  Future<void> _startNewRound() async {
    final players = ref.read(gameSessionProvider).players;
    if (players.length < 3) return;
    final db = await ref.read(contentDatabaseProvider.future);
    final word = ref.read(contentRepositoryProvider).nextImpostorWord(db);
    final impostor = players[_random.nextInt(players.length)];
    setState(() {
      _secretWord = word;
      _impostorId = impostor.id;
      _revealIdx = 0;
      _cardVisible = false;
      _phase = 'reveal';
      _votedPlayerId = null;
    });
  }

  Future<void> _castVote(Player suspect) async {
    final players = ref.read(gameSessionProvider).players;
    final notifier = ref.read(gameSessionProvider.notifier);
    final caught = suspect.id == _impostorId;

    if (caught) {
      for (final p in players) {
        if (p.id != _impostorId) {
          await notifier.awardPoints(p.id, 10, advanceRound: false);
        }
      }
      await ref.read(soundServiceProvider).playSfx(SoundEffect.victory);
      widget.onTriggerConfetti();
    } else if (_impostorId != null) {
      await notifier.awardPoints(_impostorId!, 20,
          isMinigameWin: true, advanceRound: false);
      await ref.read(soundServiceProvider).playSfx(SoundEffect.surpriseEvent);
    }
    await notifier.advanceRoundOnly();
    setState(() {
      _votedPlayerId = suspect.id;
      _phase = 'result';
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    if (session.players.length < 3) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'El modo Impostor requiere al menos 3 jugadores. Agrega uno desde el icono de jugadores arriba.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_secretWord == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_phase == 'reveal') {
      final current = session.players[_revealIdx];
      final isImpostor = current.id == _impostorId;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          borderColor: AppColors.electricPurple,
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Text(
                'ROL SECRETO (${_revealIdx + 1}/${session.players.length})',
                style: const TextStyle(
                  color: AppColors.electricBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pasa el teléfono a ${current.avatar} ${current.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              if (!_cardVisible)
                NeonButton(
                  label: 'VER MI PALABRA SECRETA',
                  icon: Icons.visibility_rounded,
                  onPressed: () {
                    ref.read(soundServiceProvider).playSfx(SoundEffect.buttonTap);
                    setState(() => _cardVisible = true);
                  },
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (isImpostor
                            ? AppColors.dangerRed
                            : AppColors.neonGreen)
                        .withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isImpostor
                          ? AppColors.dangerRed
                          : AppColors.neonGreen,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isImpostor ? '🕵️ ¡ERES EL IMPOSTOR!' : '🔑 PALABRA SECRETA',
                        style: TextStyle(
                          color: isImpostor
                              ? AppColors.dangerRed
                              : AppColors.neonGreen,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isImpostor ? '???' : _secretWord!.word,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pista de categoría: ${_secretWord!.hintCategory}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                NeonButton(
                  label: _revealIdx + 1 < session.players.length
                      ? 'Ocultar y pasar al siguiente'
                      : '¡Listo! Empezar pistas y votación',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    setState(() {
                      _cardVisible = false;
                      if (_revealIdx + 1 < session.players.length) {
                        _revealIdx++;
                      } else {
                        _phase = 'vote';
                      }
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_phase == 'vote') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              borderColor: AppColors.neonPink,
              child: Column(
                children: [
                  const Text(
                    'DEBATE Y VOTACIÓN',
                    style: TextStyle(
                      color: AppColors.neonPink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Categoría: ${_secretWord!.hintCategory}',
                    style: const TextStyle(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cada jugador dice una pista de una palabra sin delatarla demasiado. Luego toquen al sospechoso elegido por mayoría:',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...session.players.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    borderColor: p.color,
                    onTap: () => _castVote(p),
                    child: Row(
                      children: [
                        Text(p.avatar, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Text(
                          'ACUSAR',
                          style: TextStyle(
                            color: AppColors.neonPink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      );
    }

    final impostor =
        session.players.firstWhere((p) => p.id == _impostorId);
    final caught = _votedPlayerId == _impostorId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        borderColor: caught ? AppColors.neonGreen : AppColors.dangerRed,
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Text(
              caught
                  ? '🎉 ¡IMPOSTOR DESCUBIERTO!'
                  : '🕵️ ¡EL IMPOSTOR ESCAPÓ!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: caught ? AppColors.neonGreen : AppColors.dangerRed,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'El impostor era: ${impostor.avatar} ${impostor.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'La palabra secreta era: ${_secretWord!.word}',
              style: const TextStyle(
                color: AppColors.electricBlue,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              caught
                  ? 'Todos los jugadores inocentes ganaron +10 puntos.'
                  : '${impostor.name} ganó +20 puntos por despistar al grupo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            NeonButton(
              label: 'Nueva ronda de Impostor',
              icon: Icons.refresh_rounded,
              onPressed: _startNewRound,
            ),
          ],
        ),
      ),
    );
  }
}
