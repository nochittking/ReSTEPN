import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/restep_theme.dart';

/// ムーブ画面の速度計ゲージ(円弧+針)。
/// 適正レンジ部分をミント色で強調し、現在速度の位置を針で示す。
class SpeedGauge extends StatelessWidget {
  const SpeedGauge({
    super.key,
    required this.speedKmh,
    required this.minRange,
    required this.maxRange,
    this.maxSpeed = 25,
    this.size = 120,
  });

  final double speedKmh;
  final double minRange;
  final double maxRange;
  final double maxSpeed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.62),
      painter: _GaugePainter(
        speed: speedKmh.clamp(0, maxSpeed),
        min: minRange,
        max: maxRange,
        cap: maxSpeed,
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.speed,
    required this.min,
    required this.max,
    required this.cap,
  });

  final double speed;
  final double min;
  final double max;
  final double cap;

  // ゲージは左下(150°)→右下(30°)の240°円弧
  static const startDeg = 150.0;
  static const sweepDeg = 240.0;

  double _angle(double value) =>
      (startDeg + sweepDeg * (value / cap)) * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.88);
    final radius = size.width * 0.44;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = size.width * 0.10;

    // ベース円弧(グレー)
    canvas.drawArc(
      rect,
      startDeg * pi / 180,
      sweepDeg * pi / 180,
      false,
      Paint()
        ..color = const Color(0xFF515156)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // 適正レンジ部分(ミントのグラデーション)
    final rangeStart = _angle(min);
    final rangeSweep = _angle(max) - _angle(min);
    canvas.drawArc(
      rect,
      rangeStart,
      rangeSweep,
      false,
      Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: rangeStart,
          endAngle: rangeStart + rangeSweep,
          colors: const [Color(0xFF2E7D5B), RS.mint],
          transform: GradientRotation(0),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // 針
    final needleAngle = _angle(speed);
    final needleEnd = Offset(
      center.dx + cos(needleAngle) * radius * 0.72,
      center.dy + sin(needleAngle) * radius * 0.72,
    );
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = RS.white
        ..strokeWidth = size.width * 0.035
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, size.width * 0.05, Paint()..color = RS.white);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.speed != speed || old.min != min || old.max != max;
}
