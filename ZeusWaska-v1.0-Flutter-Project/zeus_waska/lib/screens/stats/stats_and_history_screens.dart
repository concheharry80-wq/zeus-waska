import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/providers/app_providers.dart';
import 'package:zeus_waska/screens/stats/party_summary_screen.dart';
import 'package:zeus_waska/widgets/neon_widgets.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final groups = ref.watch(savedGroupsProvider);
    final custom = ref.watch(customChallengesProvider);
    final dbAsync = ref.watch(contentDatabaseProvider);

    final totalParties = history.length;
    final totalRounds = history.fold<int>(0, (sum, e) => sum + e.totalRounds);
    final totalMinutes =
        history.fold<int>(0, (sum, e) => sum + e.durationMinutes);

    final Map<String, int> winsByPlayer = {};
    for (final h in history) {
      if (h.winnerName.isNotEmpty) {
        winsByPlayer[h.winnerName] = (winsByPlayer[h.winnerName] ?? 0) + 1;
      }
    }
    final topWinners = winsByPlayer.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('ESTADÍSTICAS')),
      body: NeonBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _StatCard(
                  label: 'Partidas jugadas',
                  value: '$totalParties',
                  color: AppColors.electricPurple,
                ),
                _StatCard(
                  label: 'Rondas totales',
                  value: '$totalRounds',
                  color: AppColors.neonPink,
                ),
                _StatCard(
                  label: 'Minutos de fiesta',
                  value: '$totalMinutes',
                  color: AppColors.electricBlue,
                ),
                _StatCard(
                  label: 'Grupos guardados',
                  value: '${groups.length}',
                  color: AppColors.neonGreen,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              borderColor: AppColors.warningAmber,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏆 TOP CAMPEONES HISTÓRICOS',
                    style: TextStyle(
                      color: AppColors.warningAmber,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (topWinners.isEmpty)
                    const Text(
                      'Finaliza tu primera partida para ver el salón de la fama.',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    ...topWinners.take(5).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${e.value} victorias',
                                style: const TextStyle(
                                  color: AppColors.neonGreen,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            dbAsync.when(
              data: (db) => GlassCard(
                borderColor: AppColors.electricBlue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📚 BASE DE DATOS OFFLINE',
                      style: TextStyle(
                        color: AppColors.electricBlue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• ${db.dares.length} retos divertidos\n'
                      '• ${db.truths.length} preguntas de verdad\n'
                      '• ${db.neverHaveIEver.length} frases de Yo nunca nunca\n'
                      '• ${db.mostLikely.length} preguntas de ¿Quién es más probable?\n'
                      '• ${db.fiveSeconds.length} retos de Cinco segundos\n'
                      '• ${db.impostorWords.length} palabras para Impostor\n'
                      '• ${db.groupChallenges.length} retos grupales\n'
                      '• ${custom.length} retos personalizados creados por ti',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('HISTORIAL DE PARTIDAS')),
      body: NeonBackground(
        child: history.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    'Todavía no hay partidas finalizadas.\nCuando termines una fiesta aparecerá aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final h = history[i];
                  return GlassCard(
                    borderColor: h.intensity.color,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PartySummaryScreen(entry: h),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: h.intensity.color.withValues(alpha: 0.2),
                          ),
                          child: Icon(h.intensity.icon, color: h.intensity.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🏆 ${h.winnerName} (${h.winnerScore} pts)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${h.playedAt.day}/${h.playedAt.month}/${h.playedAt.year} • ${h.totalRounds} rondas • ${h.durationMinutes} min • ${h.intensity.label}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
