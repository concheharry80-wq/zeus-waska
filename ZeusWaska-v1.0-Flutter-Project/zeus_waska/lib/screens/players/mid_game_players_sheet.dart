import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/providers/app_providers.dart';

class MidGamePlayersSheet extends ConsumerStatefulWidget {
  const MidGamePlayersSheet({super.key});

  @override
  ConsumerState<MidGamePlayersSheet> createState() =>
      _MidGamePlayersSheetState();
}

class _MidGamePlayersSheetState extends ConsumerState<MidGamePlayersSheet> {
  final TextEditingController _newNameCtrl = TextEditingController();

  @override
  void dispose() {
    _newNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final notifier = ref.read(gameSessionProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'JUGADORES EN PARTIDA (${session.players.length}/30)',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.electricBlue,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newNameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Agregar nuevo jugador...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final txt = _newNameCtrl.text.trim();
                  if (txt.isEmpty) return;
                  final idx = session.players.length;
                  notifier.addPlayerMidGame(
                    txt,
                    AppColors.playerAvatars[idx % AppColors.playerAvatars.length],
                    AppColors.playerPalette[idx % AppColors.playerPalette.length]
                        .toARGB32(),
                  );
                  _newNameCtrl.clear();
                },
                child: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: session.players.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12),
              itemBuilder: (_, i) {
                final p = session.players[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: p.color.withValues(alpha: 0.25),
                    child: Text(p.avatar),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${p.score} pts • ${p.challengesCompleted} retos • ${p.minigameWins} victorias',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: session.players.length > 2
                      ? IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.dangerRed,
                          ),
                          onPressed: () => notifier.removePlayerMidGame(p.id),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
