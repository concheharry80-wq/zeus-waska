import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/models/content_item.dart';
import 'package:zeus_waska/models/enums.dart';
import 'package:zeus_waska/providers/app_providers.dart';
import 'package:zeus_waska/widgets/neon_widgets.dart';

class CustomChallengesScreen extends ConsumerWidget {
  const CustomChallengesScreen({super.key});

  static const _typeLabels = {
    'dare': 'Reto',
    'truth': 'Verdad',
    'group': 'Reto Grupal',
    'neverHaveIEver': 'Yo Nunca Nunca',
    'mostLikely': '¿Quién es más probable?',
  };

  void _openEditor(
    BuildContext context,
    WidgetRef ref, {
    CustomChallenge? existing,
  }) {
    final ctrl = TextEditingController(text: existing?.text ?? '');
    String type = existing?.type ?? 'dare';
    ContentCategory category = existing?.category ?? ContentCategory.humor;
    IntensityLevel intensity = existing?.intensity ?? IntensityLevel.party;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            existing == null ? 'Nuevo reto personalizado' : 'Editar reto',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: _typeLabels.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => type = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ContentCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: ContentCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.emoji} ${c.label}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => category = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<IntensityLevel>(
                  value: intensity,
                  decoration: const InputDecoration(labelText: 'Intensidad'),
                  items: IntensityLevel.values
                      .map((i) => DropdownMenuItem(
                            value: i,
                            child: Text(i.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => intensity = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Texto del reto o pregunta',
                    hintText: 'Escribe algo divertido y seguro...',
                  ),
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
                final text = ctrl.text.trim();
                if (text.isEmpty) return;
                final notifier = ref.read(customChallengesProvider.notifier);
                if (existing == null) {
                  notifier.add(
                    type: type,
                    text: text,
                    category: category,
                    intensity: intensity,
                  );
                } else {
                  notifier.updateItem(
                    existing.copyWith(
                      type: type,
                      text: text,
                      category: category,
                      intensity: intensity,
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(customChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('RETOS PERSONALIZADOS')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.neonPink,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Crear reto',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: NeonBackground(
        child: items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: GlassCard(
                    borderColor: AppColors.electricPurple,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_fix_high_rounded,
                          size: 48,
                          color: AppColors.neonPink,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Aún no tienes retos propios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Crea retos, verdades o preguntas internas de tu grupo de amigos. Aparecerán automáticamente en tus partidas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        NeonButton(
                          label: 'Crear mi primer reto',
                          onPressed: () => _openEditor(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return GlassCard(
                    borderColor: item.intensity.color,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${_typeLabels[item.type] ?? item.type} • ${item.intensity.label}',
                                    style: TextStyle(
                                      color: item.intensity.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item.category.emoji} ${item.category.label}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.text,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.electricBlue,
                          ),
                          onPressed: () =>
                              _openEditor(context, ref, existing: item),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.dangerRed,
                          ),
                          onPressed: () => ref
                              .read(customChallengesProvider.notifier)
                              .remove(item.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
