import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/restep_theme.dart';

/// ジェム強化画面の魔法陣(自作CustomPaint)。
/// 外周のルーン風記号・内接三角形・3つのジェム台座を描く。
class MagicCircle extends StatelessWidget {
  const MagicCircle({super.key, required this.slots, required this.center});

  /// 3つの台座に表示するウィジェット(空ならnull)
  final List<Widget?> slots;

  /// 中央円に表示するウィジェット
  final Widget center;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, constraints) {
        final size = constraints.maxWidth;
        final radius = size * 0.34;
        final centerOffset = Offset(size / 2, size / 2);
        // 台座: 上・左下・右下
        final anchors = [
          Offset(centerOffset.dx, centerOffset.dy - radius),
          Offset(centerOffset.dx - radius * cos(pi / 6),
              centerOffset.dy + radius * sin(pi / 6)),
          Offset(centerOffset.dx + radius * cos(pi / 6),
              centerOffset.dy + radius * sin(pi / 6)),
        ];
        final slotSize = size * 0.22;

        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _CirclePainter())),
            for (var i = 0; i < 3; i++)
              Positioned(
                left: anchors[i].dx - slotSize / 2,
                top: anchors[i].dy - slotSize / 2,
                child: Container(
                  width: slotSize,
                  height: slotSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3E),
                    shape: BoxShape.circle,
                    border: Border.all(color: RS.white, width: 3),
                  ),
                  child: Center(
                    child: slots.length > i && slots[i] != null
                        ? slots[i]
                        : Icon(Icons.add,
                            color: RS.white, size: slotSize * 0.4),
                  ),
                ),
              ),
            Center(
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3E),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2A2A2E), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: RS.yellow.withValues(alpha: 0.45),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Center(child: center),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rOuter = size.width * 0.47;
    final rInner = size.width * 0.40;
    final line = Paint()
      ..color = RS.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012;

    canvas.drawCircle(c, rOuter, line);
    canvas.drawCircle(c, rInner, line);

    // 外周のルーン風記号(シード固定の擬似ランダムな線分)
    final rng = Random(3);
    final runeR = (rOuter + rInner) / 2;
    for (var i = 0; i < 26; i++) {
      final a = 2 * pi * i / 26;
      final base = Offset(c.dx + cos(a) * runeR, c.dy + sin(a) * runeR);
      final s = size.width * 0.018;
      final rune = Paint()
        ..color = RS.ink
        ..strokeWidth = size.width * 0.008
        ..strokeCap = StrokeCap.round;
      switch (rng.nextInt(4)) {
        case 0:
          canvas.drawLine(base - Offset(s, 0), base + Offset(s, 0), rune);
          canvas.drawLine(base - Offset(0, s), base + Offset(0, s), rune);
        case 1:
          canvas.drawCircle(base, s * 0.7, rune..style = PaintingStyle.stroke);
        case 2:
          canvas.drawLine(base - Offset(s, s), base + Offset(s, s), rune);
        default:
          canvas.drawRect(
              Rect.fromCenter(center: base, width: s, height: s),
              rune..style = PaintingStyle.stroke);
      }
    }

    // 内接三角形(上向き)+補助線
    final r = size.width * 0.34;
    final p1 = Offset(c.dx, c.dy - r);
    final p2 = Offset(c.dx - r * cos(pi / 6), c.dy + r * sin(pi / 6));
    final p3 = Offset(c.dx + r * cos(pi / 6), c.dy + r * sin(pi / 6));
    final tri = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    canvas.drawPath(tri, line);

    // 三角形内の格子模様
    final web = Paint()
      ..color = RS.ink.withValues(alpha: 0.45)
      ..strokeWidth = size.width * 0.006;
    canvas.drawLine(p1, Offset(c.dx, c.dy + r * 0.5), web);
    canvas.drawLine(
        Offset.lerp(p1, p2, 0.5)!, Offset.lerp(p1, p3, 0.5)!, web);
    canvas.drawLine(Offset.lerp(p2, p1, 0.3)!, Offset.lerp(p2, p3, 0.3)!, web);
    canvas.drawLine(Offset.lerp(p3, p1, 0.3)!, Offset.lerp(p3, p2, 0.3)!, web);
  }

  @override
  bool shouldRepaint(_CirclePainter old) => false;
}
