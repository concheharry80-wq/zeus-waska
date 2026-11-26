import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus_waska/core/services/sound_service.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/models/enums.dart';
import 'package:zeus_waska/providers/app_providers.dart';
import 'package:zeus_waska/screens/games/all_other_modes.dart';
import 'package:zeus_waska/screens/games/double_roulette_view.dart';
import 'package:zeus_waska/screens/games/impostor_and_duel_modes.dart';
import 'package:zeus_waska/screens/players/mid_game_players_sheet.dart';
import 'package:zeus_waska/screens/stats/party_summary_screen.dart';
import 'package:zeus_waska/widgets/neon_widgets.dart';

class PartyHubScreen extends ConsumerStatefulWidget {
  const PartyHubScreen({super.key});

  @override
  ConsumerState<PartyHubScreen> createState() => _PartyHubScreenState();
}

class _PartyHubScreenState extends ConsumerState<PartyHubScreen> {
  bool _confetti = false;

  void _triggerConfetti() {
    setState(() => _confetti = false);
    Future.microtask(() {
      if (mounted) setState(() => _confetti = true);
    });
  }

  Future<void> _finishParty() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Finalizar fiesta?'),
        content: const Text(
          'Se guardarán las estadísticas y verás el ranking animado con premios de la noche.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir jugando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ver resultados'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final entry = await ref.read(gameSessionProvider.notifier).finishParty();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PartySummaryScreen(entry: entry)),
    );
  }

  Widget _buildActiveMode(GameMode mode) {
    switch (mode) {
      case GameMode.doubleRoulette:
        return DoubleRouletteView(onTriggerConfetti: _triggerConfetti);
      case GameMode.truthOrDare:
        return TruthOrDareMode(onTriggerConfetti: _triggerConfetti);
      case GameMode.neverHaveIEver:
        return NeverHaveIEverMode(onTriggerConfetti: _triggerConfetti);
      case GameMode.mostLikely:
        return MostLikelyMode(onTriggerConfetti: _triggerConfetti);
      case GameMode.theBomb:
        return TheBombMode(onTriggerConfetti: _triggerConfetti);
      case GameMode.anonymousConfessions:
        return AnonymousConfessionsMode(onTriggerConfetti: _triggerConfetti);
      case GameMode.duel:
        return DuelMode(onTriggerConfetti: _triggerConfetti);
      case GameMode.mysteryRoulette:
        return MysteryRouletteMode(onTriggerConfetti: _triggerConfetti);
      case GameMode.fiveSeconds:
        return FiveSecondsMode(onTriggerConfetti: _triggerConfetti);
      case GameMode.impostor:
        return ImpostorMode(onTriggerConfetti: _triggerConfetti);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              session.currentMode.title.toUpperCase(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            Text(
              'Ronda ${session.roundNumber} • ${session.intensity.label}',
              style: TextStyle(
                fontSize: 11,
                color: session.intensity.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Jugadores',
            icon: const Icon(Icons.group_add_rounded),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const MidGamePlayersSheet(),
              );
            },
          ),
          IconButton(
            tooltip: 'Carta especial',
            icon: const Icon(Icons.style_rounded, color: AppColors.warningAmber),
            onPressed: () async {
              final card = ref
                  .read(gameSessionProvider.notifier)
                  .rollSpecialCard(force: true);
              if (card != null && context.mounted) {
                await ref
                    .read(soundServiceProvider)
                    .playSfx(SoundEffect.specialCard);
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (_) => SpecialCardDialog(card: card),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Finalizar fiesta',
            icon: const Icon(Icons.flag_rounded, color: AppColors.neonGreen),
            onPressed: _finishParty,
          ),
        ],
      ),
      body: NeonBackground(
        child: Stack(
          children: [
            Column(
              children: [
                // Selector rápido de los 10 modos de juego
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    scrollDirection: Axis.horizontal,
                    itemCount: GameMode.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final mode = GameMode.values[i];
                      final active = mode == session.currentMode;
                      return ChoiceChip(
                        avatar: Icon(
                          mode.icon,
                          size: 16,
                          color: active ? Colors.white : mode.accentColor,
                        ),
                        label: Text(
                          mode.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: active,
                        selectedColor: mode.accentColor.withValues(alpha: 0.4),
                        side: BorderSide(
                          color: active ? mode.accentColor : Colors.white12,
                        ),
                        onSelected: (_) {
                          if (session.players.length < mode.minPlayers) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${mode.title} requiere mínimo ${mode.minPlayers} jugadores.',
                                ),
                              ),
                            );
                            return;
                          }
                          ref
                              .read(soundServiceProvider)
                              .playSfx(SoundEffect.buttonTap);
                          ref.read(gameSessionProvider.notifier).setMode(mode);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: KeyedSubtree(
                      key: ValueKey(session.currentMode),
                      child: _buildActiveMode(session.currentMode),
                    ),
                  ),
                ),
              ],
            ),
            ConfettiBurst(trigger: _confetti),
          ],
        ),
      ),
    );
  }
}
