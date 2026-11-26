import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/models/enums.dart';

/// Fondo oscuro neón #0A0A12 con degradados ambientales y partículas animadas ligeras.
class NeonBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;

  const NeonBackground({
    super.key,
    required this.child,
    this.showParticles = true,
  });

  @override
  State<NeonBackground> createState() => _NeonBackgroundState();
}

class _NeonBackgroundState extends State<NeonBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            gradient: RadialGradient(
              center: Alignment(-0.7, -0.8),
              radius: 1.35,
              colors: [
                Color(0xFF1D1038),
                Color(0xFF0A0A12),
              ],
            ),
          ),
        ),
        Positioned(
          right: -90,
          bottom: -70,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.neonPink.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -70,
          top: 140,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.electricBlue.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        if (widget.showParticles)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  painter: _ParticlesPainter(_controller.value),
                ),
              ),
            ),
          ),
        widget.child,
      ],
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double progress;
  _ParticlesPainter(this.progress);

  static const _colors = [
    AppColors.electricPurple,
    AppColors.neonPink,
    AppColors.electricBlue,
    AppColors.neonGreen,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 22; i++) {
      final seed = i * 37.0;
      final xFrac = ((sin(seed) + 1) / 2);
      final baseY = ((cos(seed * 1.3) + 1) / 2);
      final yFrac = (baseY - progress * (0.4 + (i % 4) * 0.15)) % 1.0;
      final dx = xFrac * size.width + sin(progress * 2 * pi + seed) * 14;
      final dy = (yFrac < 0 ? yFrac + 1.0 : yFrac) * size.height;
      final radius = 1.6 + (i % 3) * 1.1;
      paint.color = _colors[i % _colors.length].withValues(alpha: 0.28);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Tarjeta translúcida con degradado y borde neón sutil.
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.borderColor,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final glow = borderColor ?? AppColors.electricPurple;
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceLight.withValues(alpha: 0.72),
            AppColors.surface.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: glow.withValues(alpha: 0.42),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: box,
      ),
    );
  }
}

/// Botón con degradado neón y resplandor luminoso.
class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final List<Color> colors;
  final double height;
  final bool expanded;

  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.colors = const [AppColors.electricPurple, AppColors.neonPink],
    this.height = 54,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: enabled
              ? colors
              : [Colors.grey.shade800, Colors.grey.shade700],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Explosión de confeti neón animada con CustomPainter (60fps offline).
class ConfettiBurst extends StatefulWidget {
  final bool trigger;

  const ConfettiBurst({super.key, required this.trigger});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.trigger) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          if (_controller.value == 0 || _controller.value == 1) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_controller.value),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static const _colors = [
    AppColors.electricPurple,
    AppColors.neonPink,
    AppColors.electricBlue,
    AppColors.neonGreen,
    AppColors.warningAmber,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final origin = Offset(size.width / 2, size.height * 0.35);
    for (int i = 0; i < 42; i++) {
      final angle = (i / 42) * 2 * pi + (i % 3) * 0.12;
      final speed = 130 + (i % 7) * 38.0;
      final dx = origin.dx + cos(angle) * speed * t;
      final dy = origin.dy + sin(angle) * speed * t + 260 * t * t;
      final alpha = (1.0 - t).clamp(0.0, 1.0);
      paint.color = _colors[i % _colors.length].withValues(alpha: alpha);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(t * 8 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromCenter(center: Offset.zero, width: 10, height: 6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}

/// Diálogo animado con efecto 3D para las 9 cartas de eventos especiales.
class SpecialCardDialog extends StatefulWidget {
  final SpecialCardType card;
  final String? targetPlayerName;

  const SpecialCardDialog({
    super.key,
    required this.card,
    this.targetPlayerName,
  });

  @override
  State<SpecialCardDialog> createState() => _SpecialCardDialogState();
}

class _SpecialCardDialogState extends State<SpecialCardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final v = Curves.easeOutBack.transform(_controller.value);
        final angle = (1 - _controller.value) * pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle)
            ..scale(0.6 + 0.4 * v),
          child: child,
        );
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          borderColor: widget.card.color,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.card.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.card.color),
                ),
                child: Text(
                  'CARTA ESPECIAL',
                  style: TextStyle(
                    color: widget.card.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.card.color.withValues(alpha: 0.5),
                      widget.card.color.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(color: widget.card.color, width: 2),
                ),
                child: Icon(widget.card.icon, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 16),
              Text(
                widget.card.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.targetPlayerName != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Para ${widget.targetPlayerName}',
                  style: TextStyle(
                    color: widget.card.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                widget.card.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              NeonButton(
                label: '¡ACTIVAR CARTA!',
                colors: [widget.card.color, AppColors.electricPurple],
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
