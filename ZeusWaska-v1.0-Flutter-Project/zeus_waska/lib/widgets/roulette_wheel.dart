import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/models/player.dart';

/// Ruleta animada neón construida con CustomPainter optimizada para 2 a 30 jugadores.
class NeonRouletteWheel extends StatelessWidget {
  final List<Player> players;
  final double angle;
  final String title;
  final Color accentColor;
  final int? highlightedIndex;
  final double size;

  const NeonRouletteWheel({
    super.key,
    required this.players,
    required this.angle,
    required this.title,
    required this.accentColor,
    this.highlightedIndex,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.65)),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: size,
          height: size + 16,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Resplandor exterior
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(
                        alpha: highlightedIndex != null ? 0.55 : 0.25,
                      ),
                      blurRadius: highlightedIndex != null ? 24 : 14,
                    ),
                  ],
                ),
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _RouletteWheelPainter(
                    players: players,
                    angle: angle,
                    accentColor: accentColor,
                    highlightedIndex: highlightedIndex,
                  ),
                ),
              ),
              // Puntero superior neón
              Positioned(
                top: 0,
                child: CustomPaint(
                  size: const Size(24, 22),
                  painter: _PointerPainter(accentColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;
  _PointerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 2)
      ..lineTo(size.width, 2)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RouletteWheelPainter extends CustomPainter {
  final List<Player> players;
  final double angle;
  final Color accentColor;
  final int? highlightedIndex;

  _RouletteWheelPainter({
    required this.players,
    required this.angle,
    required this.accentColor,
    this.highlightedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    if (players.isEmpty) return;

    final sweep = (2 * pi) / players.length;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      final startAngle = i * sweep;
      final isWinner = highlightedIndex == i;

      final segColor = AppColors.playerPalette[i % AppColors.playerPalette.length];
      final paint = Paint()
        ..color = isWinner ? segColor : segColor.withValues(alpha: 0.78)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );

      // Separador
      final borderPaint = Paint()
        ..color = isWinner ? Colors.white : AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = isWinner ? 2.4 : 1.2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        sweep,
        true,
        borderPaint,
      );

      // Nombre del jugador radial
      final textAngle = startAngle + sweep / 2;
      canvas.save();
      canvas.rotate(textAngle);

      final maxLen = players.length > 14 ? 5 : (players.length > 8 ? 7 : 10);
      final shortName = player.name.length > maxLen
          ? '${player.name.substring(0, maxLen - 1)}…'
          : player.name;
      final fontSize = players.length > 18
          ? 7.5
          : (players.length > 10 ? 9.0 : 11.0);

      final tp = TextPainter(
        text: TextSpan(
          text: shortName,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: isWinner ? FontWeight.w900 : FontWeight.w700,
            shadows: const [
              Shadow(color: Colors.black87, blurRadius: 3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * 0.65);

      tp.paint(canvas, Offset(radius * 0.30, -tp.height / 2));
      canvas.restore();
    }

    canvas.restore();

    // Aro exterior neón
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );

    // Centro metálico oscuro con brillo
    canvas.drawCircle(
      center,
      radius * 0.19,
      Paint()..color = AppColors.background,
    );
    canvas.drawCircle(
      center,
      radius * 0.19,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant _RouletteWheelPainter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.highlightedIndex != highlightedIndex ||
      oldDelegate.players.length != players.length;
}
