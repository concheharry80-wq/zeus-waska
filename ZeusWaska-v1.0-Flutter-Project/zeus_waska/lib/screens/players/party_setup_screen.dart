import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:zeus_waska/core/services/sound_service.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/models/enums.dart';
import 'package:zeus_waska/models/player.dart';
import 'package:zeus_waska/providers/app_providers.dart';
import 'package:zeus_waska/screens/games/party_hub_screen.dart';
import 'package:zeus_waska/widgets/neon_widgets.dart';

const _uuid = Uuid();

class PartySetupScreen extends ConsumerStatefulWidget {
  final GameMode initialMode;
  const PartySetupScreen({
    super.key,
    this.initialMode = GameMode.doubleRoulette,
  });

  @override
  ConsumerState<PartySetupScreen> createState() => _PartySetupScreenState();
}

class _PartySetupScreenState extends ConsumerState<PartySetupScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _groupNameCtrl =
      TextEditingController(text: 'Noche ZEUS WASKA');

  final List<Player> _players = [];
  IntensityLevel _intensity = IntensityLevel.party;
  late GameMode _selectedMode;
  String _selectedAvatar = AppColors.playerAvatars.first;
  int _selectedColor = AppColors.playerPalette.first.toARGB32();

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  void _addPlayer() {
    if (_players.length >= 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 30 jugadores por partida.')),
      );
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    ref.read(soundServiceProvider).playSfx(SoundEffect.buttonTap);
    setState(() {
      _players.add(
        Player(
          id: _uuid.v4(),
          name: name,
          avatar: _selectedAvatar,
          colorValue: _selectedColor,
        ),
      );
      _nameCtrl.clear();
      _selectedAvatar =
          AppColors.playerAvatars[_players.length % AppColors.playerAvatars.length];
      _selectedColor = AppColors
          .playerPalette[_players.length % AppColors.playerPalette.length]
          .toARGB32();
    });
  }

  void _editPlayerDialog(int index) {
    final p = _players[index];
    final ctrl = TextEditingController(text: p.name);
    String avatar = p.avatar;
    int colorVal = p.colorValue;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Editar jugador'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: 'Nombre o apodo'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AppColors.playerAvatars.take(12).map((a) {
                    final active = a == avatar;
                    return GestureDetector(
                      onTap: () => setModalState(() => avatar = a),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? AppColors.electricPurple.withValues(alpha: 0.4)
                              : Colors.transparent,
                          border: Border.all(
                            color: active
                                ? AppColors.electricBlue
                                : Colors.white24,
                          ),
                        ),
                        child: Text(a, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: AppColors.playerPalette.take(8).map((c) {
                    final active = c.toARGB32() == colorVal;
                    return GestureDetector(
                      onTap: () => setModalState(() => colorVal = c.toARGB32()),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: active
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = ctrl.text.trim();
                if (txt.isEmpty) return;
                setState(() {
                  _players[index] = p.copyWith(
                    name: txt,
                    avatar: avatar,
                    colorValue: colorVal,
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startParty() async {
    if (_players.length < _selectedMode.minPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Agrega al menos ${_selectedMode.minPlayers} jugadores para ${_selectedMode.title}.',
          ),
        ),
      );
      return;
    }

    await ref.read(gameSessionProvider.notifier).startNewParty(
          players: _players,
          intensity: _intensity,
          initialMode: _selectedMode,
          groupName: _groupNameCtrl.text.trim(),
        );
    await ref.read(soundServiceProvider).playSfx(SoundEffect.victory);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PartyHubScreen()),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _groupNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedGroups = ref.watch(savedGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PREPARAR FIESTA')),
      body: NeonBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Grupos guardados
            if (savedGroups.isNotEmpty) ...[
              const Text(
                'GRUPOS GUARDADOS',
                style: TextStyle(
                  color: AppColors.electricBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: savedGroups.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final g = savedGroups[i];
                    return ActionChip(
                      backgroundColor: AppColors.surfaceLight,
                      side: BorderSide(
                        color: AppColors.electricPurple.withValues(alpha: 0.6),
                      ),
                      label: Text('${g.name} (${g.players.length})'),
                      onPressed: () {
                        setState(() {
                          _groupNameCtrl.text = g.name;
                          _players
                            ..clear()
                            ..addAll(g.players);
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Nombre del grupo
            TextField(
              controller: _groupNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del grupo (se guarda automáticamente)',
                prefixIcon: Icon(Icons.groups_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Agregar jugador
            GlassCard(
              borderColor: AppColors.electricPurple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'JUGADORES (2–30)',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${_players.length} / 30',
                        style: const TextStyle(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (_) => _addPlayer(),
                          decoration: const InputDecoration(
                            hintText: 'Nombre o apodo...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _addPlayer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonPink,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppColors.playerAvatars.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final av = AppColors.playerAvatars[i];
                        final active = av == _selectedAvatar;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = av),
                          child: Container(
                            width: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? AppColors.electricPurple.withValues(alpha: 0.45)
                                  : AppColors.background,
                              border: Border.all(
                                color: active
                                    ? AppColors.electricBlue
                                    : Colors.white12,
                              ),
                            ),
                            child: Text(av, style: const TextStyle(fontSize: 18)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_players.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Agrega al menos 2 amigos para comenzar la fiesta.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_players.length, (i) {
                        final p = _players[i];
                        return InputChip(
                          avatar: Text(p.avatar),
                          label: Text(p.name),
                          backgroundColor: p.color.withValues(alpha: 0.22),
                          side: BorderSide(color: p.color),
                          onPressed: () => _editPlayerDialog(i),
                          onDeleted: () => setState(() => _players.removeAt(i)),
                        );
                      }),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // NIVELES DE INTENSIDAD
            const Text(
              'NIVEL DE INTENSIDAD',
              style: TextStyle(
                color: AppColors.electricBlue,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.55,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: IntensityLevel.values.map((lvl) {
                final selected = _intensity == lvl;
                return GlassCard(
                  borderColor: selected ? lvl.color : Colors.white12,
                  padding: const EdgeInsets.all(12),
                  onTap: () => setState(() => _intensity = lvl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(lvl.icon, color: lvl.color, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            lvl.label,
                            style: TextStyle(
                              color: lvl.color,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lvl.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // MODO INICIAL
            const Text(
              'MODO DE JUEGO INICIAL',
              style: TextStyle(
                color: AppColors.electricBlue,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GameMode.values.map((mode) {
                final active = _selectedMode == mode;
                return ChoiceChip(
                  selected: active,
                  selectedColor: mode.accentColor.withValues(alpha: 0.35),
                  side: BorderSide(
                    color: active ? mode.accentColor : Colors.white24,
                  ),
                  label: Text(mode.title),
                  onSelected: (_) => setState(() => _selectedMode = mode),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            NeonButton(
              label: '¡INICIAR FIESTA!',
              icon: Icons.rocket_launch_rounded,
              onPressed: _startParty,
            ),
          ],
        ),
      ),
    );
  }
}
