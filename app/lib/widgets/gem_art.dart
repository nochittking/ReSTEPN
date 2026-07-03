import 'package:flutter/material.dart';

import '../models/gem.dart';
import '../theme/restep_theme.dart';

/// ジェムのイラスト(自作CustomPaint)。
/// Lv1=三角錐、Lv2以上=八面体(ひし形)。色はジェム種別ごと。
class GemArt extends StatelessWidget {
  const GemArt({super.key, required this.type, this.level = 1, this.size = 48});

  final GemType type;
  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GemPainter(color: type.color, level: level),
    );
  }
}

class _GemPainter extends CustomPainter {
  _GemPainter({required this.color, required this.level});

  final Color color;
  final int level;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outline = Paint()
      ..color = RS.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeJoin = StrokeJoin.round;
    final light = HSLColor.fromColor(color).withLightness(0.82).toColor();
    final dark = HSLColor.fromColor(color)
        .withLightness(
            (HSLColor.fromColor(color).lightness - 0.18).clamp(0.0, 1.0))
        .toColor();

    if (level <= 1) {
      // 三角錐(左面=明・右面=基本色)
      final apex = Offset(w * 0.5, h * 0.12);
      final left = Offset(w * 0.10, h * 0.85);
      final right = Offset(w * 0.90, h * 0.85);
      final mid = Offset(w * 0.5, h * 0.85);

      canvas.drawPath(
          Path()
            ..moveTo(apex.dx, apex.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(mid.dx, mid.dy)
            ..close(),
          Paint()..color = light);
      canvas.drawPath(
          Path()
            ..moveTo(apex.dx, apex.dy)
            ..lineTo(right.dx, right.dy)
            ..lineTo(mid.dx, mid.dy)
            ..close(),
          Paint()..color = color);
      final tri = Path()
        ..moveTo(apex.dx, apex.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
      canvas.drawPath(tri, outline);
      canvas.drawLine(apex, mid, outline..strokeWidth = w * 0.03);
    } else {
      // 八面体(上下ピラミッド、面ごとに明暗)
      final top = Offset(w * 0.5, h * 0.06);
      final bottom = Offset(w * 0.5, h * 0.94);
      final left = Offset(w * 0.10, h * 0.46);
      final right = Offset(w * 0.90, h * 0.46);
      final center = Offset(w * 0.5, h * 0.46);

      canvas.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(center.dx, center.dy + h * 0.06)
            ..close(),
          Paint()..color = light);
      canvas.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..lineTo(right.dx, right.dy)
            ..lineTo(center.dx, center.dy + h * 0.06)
            ..close(),
          Paint()..color = color);
      canvas.drawPath(
          Path()
            ..moveTo(bottom.dx, bottom.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(center.dx, center.dy + h * 0.06)
            ..close(),
          Paint()..color = color);
      canvas.drawPath(
          Path()
            ..moveTo(bottom.dx, bottom.dy)
            ..lineTo(right.dx, right.dy)
            ..lineTo(center.dx, center.dy + h * 0.06)
            ..close(),
          Paint()..color = dark);
      final diamond = Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(right.dx, right.dy)
        ..lineTo(bottom.dx, bottom.dy)
        ..lineTo(left.dx, left.dy)
        ..close();
      canvas.drawPath(diamond, outline);
    }
  }

  @override
  bool shouldRepaint(_GemPainter old) =>
      old.color != color || old.level != level;
}

/// シューズ詳細カード4隅の八角形ソケット。
class GemSocket extends StatelessWidget {
  const GemSocket({
    super.key,
    required this.type,
    this.gem,
    this.size = 56,
    this.onTap,
  });

  final GemType type;
  final Gem? gem;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final base = type.color;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _SocketPainter(
            color: gem != null
                ? base
                : HSLColor.fromColor(base).withSaturation(0.25).toColor(),
          ),
          child: Center(
            child: gem != null
                ? GemArt(type: type, level: gem!.level, size: size * 0.55)
                : Icon(Icons.add, size: size * 0.4, color: RS.white),
          ),
        ),
      ),
    );
  }
}

class _SocketPainter extends CustomPainter {
  _SocketPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = w * 0.30; // 八角形の切り欠き
    final path = Path()
      ..moveTo(c, 0)
      ..lineTo(w - c, 0)
      ..lineTo(w, c)
      ..lineTo(w, w - c)
      ..lineTo(w - c, w)
      ..lineTo(c, w)
      ..lineTo(0, w - c)
      ..lineTo(0, c)
      ..close();
    canvas.drawPath(
        path, Paint()..color = color.withValues(alpha: 0.85));
    canvas.drawPath(
        path,
        Paint()
          ..color = HSLColor.fromColor(color).withLightness(0.30).toColor()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.05);
  }

  @override
  bool shouldRepaint(_SocketPainter old) => old.color != color;
}
