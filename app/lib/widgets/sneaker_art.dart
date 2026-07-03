import 'package:flutter/material.dart';

import '../models/shoe.dart';
import '../theme/restep_theme.dart';

/// スニーカーのイラスト(完全自作のCustomPaint)。
/// タイプでアクセント色、レアリティでトリム色が変わる。
class SneakerArt extends StatelessWidget {
  const SneakerArt({super.key, required this.shoe, this.size = 160});

  final Shoe shoe;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.62),
      painter: _SneakerPainter(
        accent: RS.typeColor(shoe.type),
        trim: RS.rarityColor(shoe.rarity),
      ),
    );
  }
}

class _SneakerPainter extends CustomPainter {
  _SneakerPainter({required this.accent, required this.trim});

  final Color accent;
  final Color trim;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outline = Paint()
      ..color = RS.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeJoin = StrokeJoin.round;

    // ソール(靴底)
    final sole = Path()
      ..moveTo(w * 0.04, h * 0.78)
      ..quadraticBezierTo(w * 0.02, h * 0.95, w * 0.18, h * 0.96)
      ..lineTo(w * 0.88, h * 0.96)
      ..quadraticBezierTo(w * 0.99, h * 0.95, w * 0.97, h * 0.82)
      ..quadraticBezierTo(w * 0.96, h * 0.72, w * 0.85, h * 0.70)
      ..lineTo(w * 0.10, h * 0.68)
      ..close();
    canvas.drawPath(sole, Paint()..color = Colors.white);
    canvas.drawPath(sole, outline);

    // 本体
    final body = Path()
      ..moveTo(w * 0.08, h * 0.70)
      ..quadraticBezierTo(w * 0.06, h * 0.42, w * 0.30, h * 0.30)
      ..quadraticBezierTo(w * 0.42, h * 0.06, w * 0.56, h * 0.08)
      ..lineTo(w * 0.66, h * 0.10)
      ..quadraticBezierTo(w * 0.72, h * 0.30, w * 0.86, h * 0.48)
      ..quadraticBezierTo(w * 0.92, h * 0.58, w * 0.88, h * 0.70)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFF6F1E3));
    canvas.drawPath(body, outline);

    // つま先の当て布
    final toe = Path()
      ..moveTo(w * 0.08, h * 0.70)
      ..quadraticBezierTo(w * 0.06, h * 0.46, w * 0.28, h * 0.33)
      ..quadraticBezierTo(w * 0.34, h * 0.52, w * 0.30, h * 0.70)
      ..close();
    canvas.drawPath(toe, Paint()..color = accent.withValues(alpha: 0.85));
    canvas.drawPath(toe, outline);

    // 履き口(タン)
    final collar = Path()
      ..moveTo(w * 0.56, h * 0.08)
      ..lineTo(w * 0.66, h * 0.10)
      ..quadraticBezierTo(w * 0.70, h * 0.22, w * 0.76, h * 0.34)
      ..quadraticBezierTo(w * 0.66, h * 0.40, w * 0.58, h * 0.36)
      ..quadraticBezierTo(w * 0.52, h * 0.20, w * 0.56, h * 0.08)
      ..close();
    canvas.drawPath(collar, Paint()..color = trim.withValues(alpha: 0.9));
    canvas.drawPath(collar, outline);

    // ヒールループ(黄色いつまみ)
    final loop = Path()
      ..moveTo(w * 0.86, h * 0.46)
      ..quadraticBezierTo(w * 0.98, h * 0.44, w * 0.96, h * 0.56)
      ..quadraticBezierTo(w * 0.94, h * 0.64, w * 0.87, h * 0.60)
      ..close();
    canvas.drawPath(loop, Paint()..color = RS.yellow);
    canvas.drawPath(loop, outline);

    // シューレース(3本)
    final lace = Paint()
      ..color = RS.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final t = i * 0.09;
      canvas.drawLine(
        Offset(w * (0.40 + t), h * (0.30 - t * 0.6)),
        Offset(w * (0.52 + t), h * (0.42 - t * 0.6)),
        lace,
      );
    }

    // サイドのジグザグ模様(タイプ色)
    final zig = Path()..moveTo(w * 0.32, h * 0.62);
    for (var i = 0; i < 4; i++) {
      zig.lineTo(w * (0.38 + i * 0.12), h * (i.isEven ? 0.50 : 0.62));
    }
    canvas.drawPath(
      zig,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeJoin = StrokeJoin.round,
    );

    // モザイク飾り(レアリティ色の小さな三角)
    final mosaic = Paint()..color = trim;
    for (var i = 0; i < 3; i++) {
      final cx = w * (0.42 + i * 0.13);
      final cy = h * 0.56;
      final s = w * 0.035;
      final tri = Path()
        ..moveTo(cx, cy - s)
        ..lineTo(cx + s, cy + s)
        ..lineTo(cx - s, cy + s)
        ..close();
      canvas.drawPath(tri, mosaic);
    }
  }

  @override
  bool shouldRepaint(_SneakerPainter old) =>
      old.accent != accent || old.trim != trim;
}
