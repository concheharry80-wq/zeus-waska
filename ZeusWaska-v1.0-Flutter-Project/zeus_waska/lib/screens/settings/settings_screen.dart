import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/models/enums.dart';
import 'package:zeus_waska/providers/app_providers.dart';
import 'package:zeus_waska/screens/custom/custom_challenges_screen.dart';
import 'package:zeus_waska/widgets/neon_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('CONFIGURACIÓN')),
      body: NeonBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
          children: [
            // Tema visual
            GlassCard(
              borderColor: AppColors.electricPurple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TEMA VISUAL',
                    style: TextStyle(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppVisualTheme.values.map((t) {
                      final active = settings.visualTheme == t;
                      return ChoiceChip(
                        label: Text(t.label),
                        selected: active,
                        onSelected: (_) =>
                            notifier.update(settings.copyWith(visualTheme: t)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Audio y vibración
            GlassCard(
              borderColor: AppColors.neonPink,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Efectos de sonido'),
                    subtitle: const Text('Ruletas, botones, victoria y confeti'),
                    value: settings.soundEnabled,
                    onChanged: (v) =>
                        notifier.update(settings.copyWith(soundEnabled: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Música ambiental'),
                    subtitle: const Text('Fondo nocturno suave offline'),
                    value: settings.musicEnabled,
                    onChanged: (v) =>
                        notifier.update(settings.copyWith(musicEnabled: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vibraciones'),
                    subtitle: const Text('Feedback háptico al detener ruletas'),
                    value: settings.vibrationEnabled,
                    onChanged: (v) =>
                        notifier.update(settings.copyWith(vibrationEnabled: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cartas especiales aleatorias'),
                    subtitle: const Text('Escudo, Doble puntuación, Robo y más'),
                    value: settings.specialCardsEnabled,
                    onChanged: (v) => notifier
                        .update(settings.copyWith(specialCardsEnabled: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Velocidad de ruletas y duración
            GlassCard(
              borderColor: AppColors.electricBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VELOCIDAD DE LAS RULETAS (${settings.rouletteSpeed.toStringAsFixed(1)}x)',
                    style: const TextStyle(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  Slider(
                    value: settings.rouletteSpeed,
                    min: 0.6,
                    max: 1.6,
                    divisions: 5,
                    label: '${settings.rouletteSpeed.toStringAsFixed(1)}x',
                    onChanged: (v) =>
                        notifier.update(settings.copyWith(rouletteSpeed: v)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'DURACIÓN OBJETIVO DE PARTIDA (RONDAS)',
                    style: TextStyle(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [10, 20, 30, 50].map((r) {
                      return ChoiceChip(
                        label: Text('$r rondas'),
                        selected: settings.targetRounds == r,
                        onSelected: (_) =>
                            notifier.update(settings.copyWith(targetRounds: r)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Categorías activas
            GlassCard(
              borderColor: AppColors.neonGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CATEGORÍAS ACTIVAS',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ContentCategory.values.map((c) {
                      final active = settings.enabledCategories.contains(c);
                      return FilterChip(
                        label: Text('${c.emoji} ${c.label}'),
                        selected: active,
                        onSelected: (_) => notifier.toggleCategory(c),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Gestión de datos
            GlassCard(
              borderColor: AppColors.dangerRed,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.electricBlue,
                    ),
                    title: const Text('Administrar retos personalizados'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomChallengesScreen(),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.restart_alt_rounded,
                      color: AppColors.warningAmber,
                    ),
                    title: const Text('Restablecer estadísticas e historial'),
                    onTap: () async {
                      await ref.read(historyProvider.notifier).clearHistory();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Estadísticas restablecidas.'),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(color: Colors.white12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.dangerRed,
                    ),
                    title: const Text(
                      'Eliminar todos los datos guardados',
                      style: TextStyle(color: AppColors.dangerRed),
                    ),
                    onTap: () async {
                      await ref.read(storageServiceProvider).clearAllData();
                      await ref.read(historyProvider.notifier).clearHistory();
                      await ref.read(savedGroupsProvider.notifier).clearAll();
                      await ref
                          .read(customChallengesProvider.notifier)
                          .clearAll();
                      await ref
                          .read(gameSessionProvider.notifier)
                          .abandonSession();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Todos los datos locales eliminados.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
