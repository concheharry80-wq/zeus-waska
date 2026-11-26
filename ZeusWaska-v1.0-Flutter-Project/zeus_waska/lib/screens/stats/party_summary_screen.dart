import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/models/content_item.dart';
import 'package:zeus_waska/models/player.dart';
import 'package:zeus_waska/widgets/neon_widgets.dart';

class PartySummaryScreen extends StatefulWidget {
  final GameHistoryEntry entry;
  const PartySummaryScreen({super.key, required this.entry});

  @override
  State<PartySummaryScreen> createState() => _PartySummaryScreenState();
}

class _PartySummaryScreenState extends State<PartySummaryScreen> {
  final GlobalKey _captureKey = GlobalKey();
  bool _sharing = false;

  Player? get _winner => widget.entry.finalStandings.isEmpty
      ? null
      : widget.entry.finalStandings.first;

  Player? get _challengeMaster {
    if (widget.entry.finalStandings.isEmpty) return null;
    final list = [...widget.entry.finalStandings]
      ..sort((a, b) => b.challengesCompleted.compareTo(a.challengesCompleted));
    return list.first;
  }

  Player? get _minigameKing {
    if (widget.entry.finalStandings.isEmpty) return null;
    final list = [...widget.entry.finalStandings]
      ..sort((a, b) => b.minigameWins.compareTo(a.minigameWins));
    return list.first;
  }

  Player? get _mostCompetitive {
    if (widget.entry.finalStandings.isEmpty) return null;
    final list = [...widget.entry.finalStandings]..sort((a, b) =>
        (b.score + b.minigameWins * 10 + b.challengesCompleted * 5)
            .compareTo(a.score + a.minigameWins * 10 + a.challengesCompleted * 5));
    return list.first;
  }

  Future<void> _shareResultImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/zeus_waska_resultado.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '🏆 Resultados de nuestra fiesta ZEUS WASKA — Ganador: ${widget.entry.winnerName} (${widget.entry.winnerScore} pts)!',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo generar la imagen en este dispositivo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RESUMEN DE LA FIESTA')),
      body: NeonBackground(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _captureKey,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.electricPurple.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'ZEUS WASKA',
                            style: TextStyle(
                              color: AppColors.electricBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '🏆 GANADOR DE LA NOCHE',
                            style: TextStyle(
                              color: AppColors.warningAmber,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _winner != null
                                ? '${_winner!.avatar} ${_winner!.name}'
                                : widget.entry.winnerName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${widget.entry.winnerScore} puntos • ${widget.entry.totalRounds} rondas • ${widget.entry.durationMinutes} min',
                            style: const TextStyle(
                              color: AppColors.neonGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 1.8,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            children: [
                              _AwardTile(
                                title: 'Más Competitivo',
                                player: _mostCompetitive,
                                color: AppColors.neonPink,
                              ),
                              _AwardTile(
                                title: 'Maestro de Retos',
                                player: _challengeMaster,
                                color: AppColors.electricBlue,
                              ),
                              _AwardTile(
                                title: 'Rey Minijuegos',
                                player: _minigameKing,
                                color: AppColors.warningAmber,
                              ),
                              _AwardTile(
                                title: 'Intensidad',
                                customText: widget.entry.intensity.label,
                                color: widget.entry.intensity.color,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'CLASIFICACIÓN GENERAL',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(widget.entry.finalStandings.length,
                              (i) {
                            final p = widget.entry.finalStandings[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 26,
                                    child: Text(
                                      '#${i + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: i == 0
                                            ? AppColors.warningAmber
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(p.avatar,
                                      style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${p.score} pts',
                                    style: const TextStyle(
                                      color: AppColors.neonGreen,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  NeonButton(
                    label: _sharing
                        ? 'GENERANDO IMAGEN...'
                        : 'COMPARTIR IMAGEN DEL RESULTADO',
                    icon: Icons.share_rounded,
                    onPressed: _sharing ? null : _shareResultImage,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
            const ConfettiBurst(trigger: true),
          ],
        ),
      ),
    );
  }
}

class _AwardTile extends StatelessWidget {
  final String title;
  final Player? player;
  final String? customText;
  final Color color;

  const _AwardTile({
    required this.title,
    this.player,
    this.customText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            customText ??
                (player != null ? '${player!.avatar} ${player!.name}' : '-'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
