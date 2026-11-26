import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus_waska/core/services/sound_service.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/models/enums.dart';
import 'package:zeus_waska/providers/app_providers.dart';
import 'package:zeus_waska/screens/custom/custom_challenges_screen.dart';
import 'package:zeus_waska/screens/games/party_hub_screen.dart';
import 'package:zeus_waska/screens/players/party_setup_screen.dart';
import 'package:zeus_waska/screens/settings/settings_screen.dart';
import 'package:zeus_waska/screens/stats/stats_and_history_screens.dart';
import 'package:zeus_waska/widgets/neon_widgets.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeDashboardTab(
        onSelectTab: (idx) => setState(() => _tabIndex = idx),
      ),
      const _MinigamesCatalogTab(),
      const CustomChallengesScreen(),
      const StatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(
              color: AppColors.electricPurple.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: _tabIndex,
          indicatorColor: AppColors.electricPurple.withValues(alpha: 0.28),
          onDestinationSelected: (i) {
            ref.read(soundServiceProvider).playSfx(SoundEffect.buttonTap);
            setState(() => _tabIndex = i);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.neonPink),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_esports_outlined),
              selectedIcon: Icon(
                Icons.sports_esports_rounded,
                color: AppColors.electricBlue,
              ),
              label: 'Modos',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_outlined),
              selectedIcon: Icon(
                Icons.edit_note_rounded,
                color: AppColors.neonGreen,
              ),
              label: 'Retos',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(
                Icons.bar_chart_rounded,
                color: AppColors.warningAmber,
              ),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(
                Icons.tune_rounded,
                color: AppColors.electricPurple,
              ),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDashboardTab extends ConsumerStatefulWidget {
  final ValueChanged<int> onSelectTab;
  const _HomeDashboardTab({required this.onSelectTab});

  @override
  ConsumerState<_HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends ConsumerState<_HomeDashboardTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              // Logotipo animado de ZEUS WASKA
              Center(
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) {
                    final scale = 0.97 + 0.05 * _pulseCtrl.value;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 126,
                        height: 126,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.electricPurple
                                  .withValues(alpha: 0.45),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: AppColors.neonPink.withValues(alpha: 0.30),
                              blurRadius: 22,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo_transparent.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.casino_rounded,
                              size: 72,
                              color: AppColors.neonPink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [
                            AppColors.electricPurple,
                            AppColors.neonPink,
                            AppColors.electricBlue,
                          ],
                        ).createShader(rect),
                        child: const Text(
                          'ZEUS WASKA',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Text(
                        'DOBLE RULETA • 10 MODOS DE FIESTA OFFLINE',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 1. Iniciar fiesta
              NeonButton(
                label: 'INICIAR FIESTA',
                icon: Icons.play_arrow_rounded,
                height: 60,
                onPressed: () {
                  ref.read(soundServiceProvider).playSfx(SoundEffect.buttonTap);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PartySetupScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 2. Continuar partida
              NeonButton(
                label: session.isActive
                    ? 'CONTINUAR PARTIDA (${session.players.length} jug. • R${session.roundNumber})'
                    : 'CONTINUAR PARTIDA',
                icon: Icons.restore_rounded,
                height: 52,
                colors: const [AppColors.electricBlue, AppColors.electricPurple],
                onPressed: session.isActive
                    ? () {
                        ref
                            .read(soundServiceProvider)
                            .playSfx(SoundEffect.buttonTap);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PartyHubScreen(),
                          ),
                        );
                      }
                    : null,
              ),
              const SizedBox(height: 18),

              // Resto de las 7 opciones del menú principal
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.48,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _MenuCard(
                    title: 'Minijuegos',
                    subtitle: '10 modos completos',
                    icon: Icons.sports_esports_rounded,
                    color: AppColors.electricBlue,
                    onTap: () => widget.onSelectTab(1),
                  ),
                  _MenuCard(
                    title: 'Retos propios',
                    subtitle: 'Crear y editar',
                    icon: Icons.auto_fix_high_rounded,
                    color: AppColors.neonPink,
                    onTap: () => widget.onSelectTab(2),
                  ),
                  _MenuCard(
                    title: 'Historial',
                    subtitle: 'Partidas pasadas',
                    icon: Icons.history_rounded,
                    color: AppColors.neonGreen,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                  ),
                  _MenuCard(
                    title: 'Estadísticas',
                    subtitle: 'Ranking y récords',
                    icon: Icons.leaderboard_rounded,
                    color: AppColors.warningAmber,
                    onTap: () => widget.onSelectTab(3),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassCard(
                borderColor: AppColors.electricPurple,
                onTap: () => widget.onSelectTab(4),
                child: const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.electricPurple),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configuración',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Tema, sonido, vibración, velocidad y categorías',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: color,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MinigamesCatalogTab extends ConsumerWidget {
  const _MinigamesCatalogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('10 MODOS DE JUEGO')),
      body: NeonBackground(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          itemCount: GameMode.values.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final mode = GameMode.values[i];
            return GlassCard(
              borderColor: mode.accentColor,
              onTap: () async {
                ref.read(soundServiceProvider).playSfx(SoundEffect.buttonTap);
                if (session.isActive &&
                    session.players.length >= mode.minPlayers) {
                  await ref.read(gameSessionProvider.notifier).setMode(mode);
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PartyHubScreen()),
                    );
                  }
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PartySetupScreen(initialMode: mode),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: mode.accentColor.withValues(alpha: 0.2),
                    ),
                    child: Icon(mode.icon, color: mode.accentColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ${mode.title}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          mode.subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_circle_fill_rounded, size: 28),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
