import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus_waska/core/services/sound_service.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/models/enums.dart';
import 'package:zeus_waska/models/player.dart';
import 'package:zeus_waska/providers/app_providers.dart';
import 'package:zeus_waska/widgets/neon_widgets.dart';

// ============================================================
// MODO 2: VERDAD O RETO
// ============================================================
class TruthOrDareMode extends ConsumerStatefulWidget {
  final VoidCallback onTriggerConfetti;
  const TruthOrDareMode({super.key, required this.onTriggerConfetti});

  @override
  ConsumerState<TruthOrDareMode> createState() => _TruthOrDareModeState();
}

class _TruthOrDareModeState extends ConsumerState<TruthOrDareMode> {
  int _turnIdx = 0;
  String? _choiceType; // 'VERDAD' | 'RETO'
  String? _promptText;

  Future<void> _pick(String type) async {
    final db = await ref.read(contentDatabaseProvider.future);
    final session = ref.read(gameSessionProvider);
    final settings = ref.read(settingsProvider);
    final custom = ref.read(customChallengesProvider);
    final repo = ref.read(contentRepositoryProvider);

    final item = repo.nextItem(
      source: type == 'VERDAD' ? db.truths : db.dares,
      customItems: custom,
      customType: type == 'VERDAD' ? 'truth' : 'dare',
      intensity: session.intensity,
      enabledCategories: settings.enabledCategories,
    );
    await ref.read(soundServiceProvider).playSfx(SoundEffect.buttonTap);
    setState(() {
      _choiceType = type;
      _promptText = item.text;
    });
  }

  Future<void> _resolve(bool completed) async {
    final players = ref.read(gameSessionProvider).players;
    final player = players[_turnIdx % players.length];
    if (completed) {
      await ref
          .read(gameSessionProvider.notifier)
          .completeChallenge(player.id);
      await ref.read(soundServiceProvider).playSfx(SoundEffect.victory);
      widget.onTriggerConfetti();
    } else {
      await ref.read(gameSessionProvider.notifier).skipChallenge(player.id);
      await ref.read(soundServiceProvider).playSfx(SoundEffect.defeat);
    }
    setState(() {
      _turnIdx = (_turnIdx + 1) % players.length;
      _choiceType = null;
      _promptText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final player = session.players[_turnIdx % session.players.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            borderColor: player.color,
            child: Column(
              children: [
                const Text(
                  'TURNO ACTUAL',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(player.avatar, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 6),
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${player.score} puntos',
                  style: TextStyle(
                    color: player.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_promptText == null) ...[
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'VERDAD',
                    icon: Icons.chat_bubble_rounded,
                    height: 66,
                    colors: const [
                      AppColors.electricBlue,
                      AppColors.electricPurple,
                    ],
                    onPressed: () => _pick('VERDAD'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeonButton(
                    label: 'RETO',
                    icon: Icons.local_fire_department_rounded,
                    height: 66,
                    colors: const [AppColors.neonPink, Color(0xFFFF5E3A)],
                    onPressed: () => _pick('RETO'),
                  ),
                ),
              ],
            ),
          ] else ...[
            GlassCard(
              borderColor: _choiceType == 'VERDAD'
                  ? AppColors.electricBlue
                  : AppColors.neonPink,
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Text(
                    _choiceType!,
                    style: TextStyle(
                      color: _choiceType == 'VERDAD'
                          ? AppColors.electricBlue
                          : AppColors.neonPink,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _promptText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NeonButton(
              label: '¡Cumplido! (+10 pts)',
              icon: Icons.check_circle_rounded,
              colors: const [AppColors.neonGreen, Color(0xFF00B25A)],
              onPressed: () => _resolve(true),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(_choiceType!),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Cambiar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerRed,
                      side: const BorderSide(color: AppColors.dangerRed),
                    ),
                    onPressed: () => _resolve(false),
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Pasar (-5)'),
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
// MODO 3: YO NUNCA NUNCA
// ============================================================
class NeverHaveIEverMode extends ConsumerStatefulWidget {
  final VoidCallback onTriggerConfetti;
  const NeverHaveIEverMode({super.key, required this.onTriggerConfetti});

  @override
  ConsumerState<NeverHaveIEverMode> createState() => _NeverHaveIEverModeState();
}

class _NeverHaveIEverModeState extends ConsumerState<NeverHaveIEverMode> {
  String _phrase = '';
  final Set<String> _admittedIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_nextPhrase);
  }

  Future<void> _nextPhrase() async {
    final db = await ref.read(contentDatabaseProvider.future);
    final session = ref.read(gameSessionProvider);
    final settings = ref.read(settingsProvider);
    final custom = ref.read(customChallengesProvider);
    final item = ref.read(contentRepositoryProvider).nextItem(
          source: db.neverHaveIEver,
          customItems: custom,
          customType: 'neverHaveIEver',
          intensity: session.intensity,
          enabledCategories: settings.enabledCategories,
        );
    setState(() {
      _phrase = item.text;
      _admittedIds.clear();
    });
  }

  Future<void> _confirmRound() async {
    final notifier = ref.read(gameSessionProvider.notifier);
    for (final id in _admittedIds) {
      await notifier.awardPoints(id, 5, advanceRound: false);
    }
    await notifier.advanceRoundOnly();
    await ref.read(soundServiceProvider).playSfx(SoundEffect.buttonTap);
    await _nextPhrase();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            borderColor: AppColors.electricBlue,
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Text(
                  'YO NUNCA NUNCA',
                  style: TextStyle(
                    color: AppColors.electricBlue,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _phrase.isEmpty ? 'Cargando frase...' : _phrase,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Toca voluntariamente a quienes SÍ lo han hecho (+5 pts por sinceridad)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: session.players.map((p) {
              final selected = _admittedIds.contains(p.id);
              return FilterChip(
                avatar: Text(p.avatar),
                label: Text(p.name),
                selected: selected,
                selectedColor: AppColors.neonPink.withValues(alpha: 0.35),
                side: BorderSide(
                  color: selected ? AppColors.neonPink : Colors.white24,
                ),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _admittedIds.add(p.id);
                    } else {
                      _admittedIds.remove(p.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          NeonButton(
            label: 'Siguiente frase',
            icon: Icons.arrow_forward_rounded,
            onPressed: _confirmRound,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MODO 4: ¿QUIÉN ES MÁS PROBABLE?
// ============================================================
class MostLikelyMode extends ConsumerStatefulWidget {
  final VoidCallback onTriggerConfetti;
  const MostLikelyMode({super.key, required this.onTriggerConfetti});

  @override
  ConsumerState<MostLikelyMode> createState() => _MostLikelyModeState();
}

class _MostLikelyModeState extends ConsumerState<MostLikelyMode> {
  String _question = '';
  final Map<String, int> _votes = {};
  Player? _roundWinner;

  @override
  void initState() {
    super.initState();
    Future.microtask(_nextQuestion);
  }

  Future<void> _nextQuestion() async {
    final db = await ref.read(contentDatabaseProvider.future);
    final session = ref.read(gameSessionProvider);
    final settings = ref.read(settingsProvider);
    final custom = ref.read(customChallengesProvider);
    final item = ref.read(contentRepositoryProvider).nextItem(
          source: db.mostLikely,
          customItems: custom,
          customType: 'mostLikely',
          intensity: session.intensity,
          enabledCategories: settings.enabledCategories,
        );
    setState(() {
      _question = item.text;
      _votes.clear();
      _roundWinner = null;
    });
  }

  Future<void> _finishVoting() async {
    final players = ref.read(gameSessionProvider).players;
    if (_votes.isEmpty) return;
    final topEntry =
        _votes.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final winner = players.firstWhere((p) => p.id == topEntry.key);
    await ref.read(gameSessionProvider.notifier).awardPoints(winner.id, 10);
    await ref.read(soundServiceProvider).playSfx(SoundEffect.victory);
    widget.onTriggerConfetti();
    setState(() => _roundWinner = winner);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            borderColor: AppColors.neonGreen,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  '¿QUIÉN ES MÁS PROBABLE?',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _question.isEmpty ? 'Cargando pregunta...' : _question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_roundWinner != null) ...[
            GlassCard(
              borderColor: AppColors.warningAmber,
              child: Column(
                children: [
                  const Text(
                    '🏆 MÁS VOTADO DE LA RONDA',
                    style: TextStyle(
                      color: AppColors.warningAmber,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_roundWinner!.avatar} ${_roundWinner!.name}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_votes[_roundWinner!.id] ?? 0} votos • +10 puntos',
                    style: const TextStyle(color: AppColors.neonGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NeonButton(
              label: 'Siguiente pregunta',
              icon: Icons.arrow_forward_rounded,
              onPressed: _nextQuestion,
            ),
          ] else ...[
            const Text(
              'Toca a cada jugador para sumar votos:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: session.players.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, i) {
                final p = session.players[i];
                final count = _votes[p.id] ?? 0;
                return GlassCard(
                  borderColor: count > 0 ? p.color : Colors.white12,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onTap: () {
                    ref.read(soundServiceProvider).playSfx(SoundEffect.buttonTap);
                    setState(() => _votes[p.id] = count + 1);
                  },
                  child: Row(
                    children: [
                      Text(p.avatar, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: p.color.withValues(alpha: 0.35),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            NeonButton(
              label: 'Cerrar votación',
              icon: Icons.how_to_vote_rounded,
              onPressed: _votes.isEmpty ? null : _finishVoting,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// MODO 5: LA BOMBA
// ============================================================
class TheBombMode extends ConsumerStatefulWidget {
  final VoidCallback onTriggerConfetti;
  const TheBombMode({super.key, required this.onTriggerConfetti});

  @override
  ConsumerState<TheBombMode> createState() => _TheBombModeState();
}

class _TheBombModeState extends ConsumerState<TheBombMode> {
  final Random _random = Random();
  Timer? _timer;
  bool _running = false;
  bool _exploded = false;
  int _remainingSeconds = 0;
  int _holderIndex = 0;
  String _categoryPrompt = 'Presiona Iniciar para activar la bomba';

  Future<void> _startBomb() async {
    final db = await ref.read(contentDatabaseProvider.future);
    final prompt = ref.read(contentRepositoryProvider).nextBombPrompt(db);
    final totalSec = 10 + _random.nextInt(15); // 10 a 24 seg aleatorios

    _timer?.cancel();
    setState(() {
      _categoryPrompt = prompt;
      _remainingSeconds = totalSec;
      _running = true;
      _exploded = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      _remainingSeconds--;
      if (_remainingSeconds <= 0) {
        t.cancel();
        await ref.read(soundServiceProvider).playSfx(SoundEffect.bombExplosion);
        await ref.read(soundServiceProvider).vibrateHeavy();
        final players = ref.read(gameSessionProvider).players;
        final loser = players[_holderIndex % players.length];
        await ref.read(gameSessionProvider.notifier).skipChallenge(loser.id);
        if (mounted) {
          setState(() {
            _running = false;
            _exploded = true;
          });
        }
      } else {
        await ref.read(soundServiceProvider).playSfx(SoundEffect.countdownTick);
        await ref.read(soundServiceProvider).vibrateLight();
        if (mounted) setState(() {});
      }
    });
  }

  void _passPhone() {
    if (!_running) return;
    final players = ref.read(gameSessionProvider).players;
    ref.read(soundServiceProvider).playSfx(SoundEffect.buttonTap);
    setState(() => _holderIndex = (_holderIndex + 1) % players.length);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final holder = session.players[_holderIndex % session.players.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            borderColor: _exploded ? AppColors.dangerRed : const Color(0xFFFF5E3A),
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Text(
                  _exploded ? '💥 ¡BOOM!' : '💣 LA BOMBA',
                  style: TextStyle(
                    color: _exploded
                        ? AppColors.dangerRed
                        : const Color(0xFFFF5E3A),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _categoryPrompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _running ? 116 : 96,
                  height: _running ? 116 : 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_exploded
                            ? AppColors.dangerRed
                            : const Color(0xFFFF5E3A))
                        .withValues(alpha: 0.25),
                    border: Border.all(
                      color: _exploded
                          ? AppColors.dangerRed
                          : const Color(0xFFFF5E3A),
                      width: 3,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _exploded ? '💥' : '💣',
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _exploded
                      ? 'Le explotó a ${holder.avatar} ${holder.name} (-5 pts)'
                      : 'Teléfono en manos de: ${holder.avatar} ${holder.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_running)
            NeonButton(
              label: '¡RESPONDÍ! PASAR AL SIGUIENTE',
              icon: Icons.send_rounded,
              height: 62,
              colors: const [AppColors.neonGreen, AppColors.electricBlue],
              onPressed: _passPhone,
            )
          else
            NeonButton(
              label: _exploded ? 'NUEVA RONDA DE BOMBA' : 'ACTIVAR BOMBA',
              icon: Icons.play_arrow_rounded,
              colors: const [Color(0xFFFF5E3A), AppColors.neonPink],
              onPressed: _startBomb,
            ),
        ],
      ),
    );
  }
}

// ============================================================
// MODO 6: CONFESIONES ANÓNIMAS (NUNCA SE GUARDAN EN DISCO)
// ============================================================
class _EphemeralConfession {
  final String authorId;
  final String authorName;
  final String text;
  _EphemeralConfession(this.authorId, this.authorName, this.text);
}

class AnonymousConfessionsMode extends ConsumerStatefulWidget {
  final VoidCallback onTriggerConfetti;
  const AnonymousConfessionsMode({super.key, required this.onTriggerConfetti});

  @override
  ConsumerState<AnonymousConfessionsMode> createState() =>
      _AnonymousConfessionsModeState();
}

class _AnonymousConfessionsModeState
    extends ConsumerState<AnonymousConfessionsMode> {
  final List<_EphemeralConfession> _confessions = [];
  final TextEditingController _ctrl = TextEditingController();
  int _writerIndex = 0;
  bool _guessingPhase = false;
  int _revealIndex = 0;
  bool _authorRevealed = false;

  @override
  void dispose() {
    // Privacidad garantizada: se limpia de memoria al salir
    _confessions.clear();
    _ctrl.dispose();
    super.dispose();
  }

  void _submitConfession({bool skip = false}) {
    final players = ref.read(gameSessionProvider).players;
    final current = players[_writerIndex];
    if (!skip && _ctrl.text.trim().isNotEmpty) {
      _confessions.add(
        _EphemeralConfession(current.id, current.name, _ctrl.text.trim()),
      );
    }
    _ctrl.clear();
    if (_writerIndex + 1 < players.length) {
      setState(() => _writerIndex++);
    } else {
      _confessions.shuffle();
      setState(() {
        _guessingPhase = true;
        _revealIndex = 0;
        _authorRevealed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);

    if (!_guessingPhase) {
      final writer = session.players[_writerIndex % session.players.length];
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          borderColor: const Color(0xFFE040FB),
          child: Column(
            children: [
              const Text(
                '🔒 CONFESIÓN ANÓNIMA (TEMPORAL)',
                style: TextStyle(
                  color: Color(0xFFE040FB),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pasa el teléfono a ${writer.avatar} ${writer.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Voluntario. No se guarda ningún texto al finalizar la partida.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Escribe una confesión divertida y anónima...',
                ),
              ),
              const SizedBox(height: 16),
              NeonButton(
                label: 'Guardar en secreto y pasar',
                icon: Icons.lock_rounded,
                onPressed: () => _submitConfession(),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _submitConfession(skip: true),
                child: const Text('Omitir mi confesión'),
              ),
            ],
          ),
        ),
      );
    }

    if (_confessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No se enviaron confesiones en esta ronda.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              NeonButton(
                label: 'Nueva ronda',
                onPressed: () => setState(() {
                  _writerIndex = 0;
                  _guessingPhase = false;
                }),
              ),
            ],
          ),
        ),
      );
    }

    final current = _confessions[_revealIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            borderColor: const Color(0xFFE040FB),
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Text(
                  'CONFESIÓN ${_revealIndex + 1} DE ${_confessions.length}',
                  style: const TextStyle(
                    color: Color(0xFFE040FB),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '"${current.text}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_authorRevealed) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Autor: ${current.authorName}',
                    style: const TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_authorRevealed)
            NeonButton(
              label: 'Revelar quién la escribió',
              icon: Icons.visibility_rounded,
              onPressed: () {
                ref.read(soundServiceProvider).playSfx(SoundEffect.surpriseEvent);
                setState(() => _authorRevealed = true);
              },
            )
          else ...[
            const Text(
              '¿Quién adivinó? Tócalo para darle +10 pts:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: session.players
                  .where((p) => p.id != current.authorId)
                  .map((p) => ActionChip(
                        avatar: Text(p.avatar),
                        label: Text(p.name),
                        onPressed: () async {
                          await ref
                              .read(gameSessionProvider.notifier)
                              .awardPoints(p.id, 10, advanceRound: false);
                          widget.onTriggerConfetti();
                          _advanceConfession();
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _advanceConfession,
              child: const Text('Nadie adivinó — Siguiente'),
            ),
          ],
        ],
      ),
    );
  }

  void _advanceConfession() {
    if (_revealIndex + 1 < _confessions.length) {
      setState(() {
        _revealIndex++;
        _authorRevealed = false;
      });
    } else {
      ref.read(gameSessionProvider.notifier).advanceRoundOnly();
      setState(() {
        _confessions.clear();
        _writerIndex = 0;
        _guessingPhase = false;
      });
    }
  }
}

// ============================================================
// MODO 8: RULETA MISTERIOSA (8 EVENTOS)
// ============================================================
class MysteryRouletteMode extends ConsumerStatefulWidget {
  final VoidCallback onTriggerConfetti;
  const MysteryRouletteMode({super.key, required this.onTriggerConfetti});

  @override
  ConsumerState<MysteryRouletteMode> createState() =>
      _MysteryRouletteModeState();
}

class _MysteryRouletteModeState extends ConsumerState<MysteryRouletteMode>
    with SingleTickerProviderStateMixin {
  static const List<Map<String, dynamic>> _events = [
    {'title': 'Ganar puntos', 'desc': '¡Sumas +15 puntos virtuales al instante!', 'icon': Icons.trending_up_rounded, 'color': AppColors.neonGreen},
    {'title': 'Perder puntos', 'desc': 'Pierdes 10 puntos virtuales (o cumples un reto rápido).', 'icon': Icons.trending_down_rounded, 'color': AppColors.dangerRed},
    {'title': 'Reto grupal', 'desc': '¡Todos los jugadores cumplen juntos un reto grupal!', 'icon': Icons.groups_rounded, 'color': AppColors.neonPink},
    {'title': 'Duelo', 'desc': 'Desafía a cualquier jugador en un Duelo relámpago.', 'icon': Icons.sports_esports_rounded, 'color': AppColors.warningAmber},
    {'title': 'Pregunta sorpresa', 'desc': 'Responde una pregunta de Verdad por +10 puntos.', 'icon': Icons.help_rounded, 'color': AppColors.electricBlue},
    {'title': 'Comodín', 'desc': '¡Recibes un Escudo protector para omitir un futuro reto!', 'icon': Icons.shield_rounded, 'color': Color(0xFFE040FB)},
    {'title': 'Minijuego', 'desc': 'Activa una ronda exprés de Cinco Segundos por +15 pts.', 'icon': Icons.speed_rounded, 'color': AppColors.electricPurple},
    {'title': 'Intercambio de puntos', 'desc': 'Intercambias tu puntaje con un jugador al azar.', 'icon': Icons.swap_horiz_rounded, 'color': AppColors.electricBlue},
  ];

  late AnimationController _ctrl;
  final Random _random = Random();
  double _angle = 0;
  double _start = 0;
  double _target = 0;
  int _playerIdx = 0;
  int? _selectedEventIdx;
  String? _extraDetail;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addListener(() {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        setState(() => _angle = _start + (_target - _start) * t);
      });
  }

  Future<void> _spin() async {
    if (_ctrl.isAnimating) return;
    final idx = _random.nextInt(_events.length);
    _start = _angle;
    final sweep = (2 * pi) / _events.length;
    final desired = ((-pi / 2) - (idx + 0.5) * sweep) % (2 * pi);
    double delta = desired - (_start % (2 * pi));
    if (delta < 0) delta += 2 * pi;
    _target = _start + 5 * 2 * pi + delta;

    setState(() {
      _selectedEventIdx = null;
      _extraDetail = null;
    });

    await ref.read(soundServiceProvider).playSfx(SoundEffect.surpriseEvent);
    await _ctrl.forward(from: 0);
    if (!mounted) return;
    await ref.read(soundServiceProvider).vibrateHeavy();

    final session = ref.read(gameSessionProvider);
    final player = session.players[_playerIdx % session.players.length];
    final notifier = ref.read(gameSessionProvider.notifier);
    String? detail;

    switch (idx) {
      case 0:
        await notifier.awardPoints(player.id, 15);
        widget.onTriggerConfetti();
        break;
      case 1:
        await notifier.awardPoints(player.id, -10);
        break;
      case 2:
        final db = await ref.read(contentDatabaseProvider.future);
        final item = ref.read(contentRepositoryProvider).nextItem(
              source: db.groupChallenges,
              intensity: session.intensity,
              enabledCategories: ref.read(settingsProvider).enabledCategories,
            );
        detail = item.text;
        await notifier.advanceRoundOnly();
        break;
      case 3:
        detail = 'Pulsa el botón para saltar directo al modo Duelo.';
        break;
      case 4:
        final db = await ref.read(contentDatabaseProvider.future);
        final item = ref.read(contentRepositoryProvider).nextItem(
              source: db.truths,
              intensity: session.intensity,
              enabledCategories: ref.read(settingsProvider).enabledCategories,
            );
        detail = item.text;
        await notifier.awardPoints(player.id, 10);
        break;
      case 5:
        await notifier.grantShield(player.id);
        await notifier.advanceRoundOnly();
        break;
      case 6:
        detail = 'Pulsa el botón para jugar una ronda de Cinco Segundos.';
        break;
      case 7:
        if (session.players.length >= 2) {
          final others =
              session.players.where((p) => p.id != player.id).toList();
          final other = others[_random.nextInt(others.length)];
          await notifier.swapPointsBetween(player.id, other.id);
          detail = '${player.name} intercambió puntos con ${other.name}.';
          await notifier.advanceRoundOnly();
        }
        break;
    }

    setState(() {
      _selectedEventIdx = idx;
      _extraDetail = detail;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final player = session.players[_playerIdx % session.players.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Turno de ${player.avatar} ${player.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: _angle,
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [
                          AppColors.electricPurple,
                          AppColors.neonPink,
                          AppColors.electricBlue,
                          AppColors.neonGreen,
                          AppColors.warningAmber,
                          AppColors.electricPurple,
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Center(
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.background,
                        child: Text('?', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 0,
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          NeonButton(
            label: _ctrl.isAnimating ? 'GIRANDO...' : 'GIRAR RULETA MISTERIOSA',
            icon: Icons.casino_rounded,
            onPressed: _ctrl.isAnimating ? null : _spin,
          ),
          if (_selectedEventIdx != null) ...[
            const SizedBox(height: 16),
            GlassCard(
              borderColor: _events[_selectedEventIdx!]['color'] as Color,
              child: Column(
                children: [
                  Icon(
                    _events[_selectedEventIdx!]['icon'] as IconData,
                    color: _events[_selectedEventIdx!]['color'] as Color,
                    size: 38,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _events[_selectedEventIdx!]['title'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _extraDetail ??
                        (_events[_selectedEventIdx!]['desc'] as String),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedEventIdx == 3)
                    NeonButton(
                      label: 'Ir a Duelo',
                      height: 44,
                      onPressed: () => ref
                          .read(gameSessionProvider.notifier)
                          .setMode(GameMode.duel),
                    )
                  else if (_selectedEventIdx == 6)
                    NeonButton(
                      label: 'Ir a Cinco Segundos',
                      height: 44,
                      onPressed: () => ref
                          .read(gameSessionProvider.notifier)
                          .setMode(GameMode.fiveSeconds),
                    )
                  else
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _playerIdx = (_playerIdx + 1) % session.players.length;
                          _selectedEventIdx = null;
                        });
                      },
                      child: const Text('Siguiente jugador'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// MODO 9: CINCO SEGUNDOS
// ============================================================
class FiveSecondsMode extends ConsumerStatefulWidget {
  final VoidCallback onTriggerConfetti;
  const FiveSecondsMode({super.key, required this.onTriggerConfetti});

  @override
  ConsumerState<FiveSecondsMode> createState() => _FiveSecondsModeState();
}

class _FiveSecondsModeState extends ConsumerState<FiveSecondsMode> {
  Timer? _timer;
  double _timeLeft = 5.0;
  bool _running = false;
  bool _finished = false;
  int _playerIdx = 0;
  String _prompt = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPrompt);
  }

  Future<void> _loadPrompt() async {
    final db = await ref.read(contentDatabaseProvider.future);
    final session = ref.read(gameSessionProvider);
    final settings = ref.read(settingsProvider);
    final item = ref.read(contentRepositoryProvider).nextItem(
          source: db.fiveSeconds,
          intensity: session.intensity,
          enabledCategories: settings.enabledCategories,
        );
    setState(() {
      _prompt = item.text;
      _timeLeft = 5.0;
      _running = false;
      _finished = false;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 5.0;
      _running = true;
      _finished = false;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      _timeLeft = max(0.0, _timeLeft - 0.1);
      if ((_timeLeft * 10).round() % 10 == 0 && _timeLeft > 0) {
        await ref.read(soundServiceProvider).playSfx(SoundEffect.countdownTick);
      }
      if (_timeLeft <= 0) {
        t.cancel();
        await ref.read(soundServiceProvider).playSfx(SoundEffect.defeat);
        await ref.read(soundServiceProvider).vibrateHeavy();
        if (mounted) {
          setState(() {
            _running = false;
            _finished = true;
          });
        }
      } else {
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _resolve(bool won) async {
    _timer?.cancel();
    final players = ref.read(gameSessionProvider).players;
    final p = players[_playerIdx % players.length];
    if (won) {
      await ref
          .read(gameSessionProvider.notifier)
          .awardPoints(p.id, 10, isMinigameWin: true);
      await ref.read(soundServiceProvider).playSfx(SoundEffect.victory);
      widget.onTriggerConfetti();
    } else {
      await ref.read(gameSessionProvider.notifier).advanceRoundOnly();
    }
    setState(() => _playerIdx = (_playerIdx + 1) % players.length);
    await _loadPrompt();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final player = session.players[_playerIdx % session.players.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Turno de ${player.avatar} ${player.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          GlassCard(
            borderColor: AppColors.neonPink,
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Text(
                  '⏱️ CINCO SEGUNDOS',
                  style: TextStyle(
                    color: AppColors.neonPink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _prompt.isEmpty ? 'Cargando...' : _prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _timeLeft / 5.0,
                        strokeWidth: 8,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _timeLeft > 2
                              ? AppColors.electricBlue
                              : AppColors.dangerRed,
                        ),
                      ),
                      Text(
                        _timeLeft.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!_running && !_finished)
            NeonButton(
              label: '¡INICIAR 5 SEGUNDOS!',
              icon: Icons.timer_rounded,
              onPressed: _startTimer,
            )
          else ...[
            NeonButton(
              label: '¡LO LOGRÓ! (+10 pts)',
              icon: Icons.check_rounded,
              colors: const [AppColors.neonGreen, Color(0xFF00B25A)],
              onPressed: () => _resolve(true),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _resolve(false),
              child: const Text('No llegó a tiempo — Siguiente'),
            ),
          ],
        ],
      ),
    );
  }
}
