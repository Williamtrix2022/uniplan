// ============================================
// WIDGET: ANILLO DE PROGRESO
// ============================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Anillo circular de progreso. Reutiliza la técnica de pintura del timer
/// Pomodoro (ver `_CircularProgressPainter` en home_screen.dart).
///
/// [progress] debe estar entre 0.0 y 1.0. El tamaño está fijo mediante
/// [SizedBox] para evitar errores de restricciones no acotadas dentro de
/// un [CustomPaint].
class ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.size = 120,
    this.strokeWidth = 10,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress.clamp(0.0, 1.0),
                color: color,
                backgroundColor: backgroundColor,
                strokeWidth: strokeWidth,
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
