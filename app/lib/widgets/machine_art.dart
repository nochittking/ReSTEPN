import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/restep_theme.dart';

/// ミント画面の機械(歯車ボックス+左右アーム)。自作CustomPaint。
class MintMachineArt extends StatelessWidget {
  const MintMachineArt({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.6,
      child: CustomPaint(painter: _MachinePainter()),
    );
  }
}

class _MachinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outline = Paint()
      ..color = RS.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.035
      ..strokeJoin = StrokeJoin.round;
    final metal = Paint()..color = const Color(0xFFD9D9D9);
    final metalDark = Paint()..color = const Color(0xFFBDBDBD);

    // 左右のアーム(縦棒+関節丸)
    for (final xNorm in [0.14, 0.86]) {
      final x = w * xNorm;
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(x, h * 0.35),
              width: w * 0.035,
              height: h * 0.7),
          metalDark);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(x, h * 0.35),
              width: w * 0.035,
              height: h * 0.7),
          outline);
      canvas.drawCircle(Offset(x, h * 0.72), h * 0.13, metal);
      canvas.drawCircle(Offset(x, h * 0.72), h * 0.13, outline);
      canvas.drawCircle(Offset(x, h * 0.72), h * 0.06, outline);
      // 横棒(本体へ)
      final toCenter = xNorm < 0.5 ? w * 0.30 : w * 0.70;
      canvas.drawRect(
          Rect.fromLTRB(min(x, toCenter), h * 0.66, max(x, toCenter),
              h * 0.78),
          metalDark);
      canvas.drawRect(
          Rect.fromLTRB(min(x, toCenter), h * 0.66, max(x, toCenter),
              h * 0.78),
          outline);
    }

    // 本体ボックス
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.62),
          width: w * 0.42,
          height: h * 0.72),
      Radius.circular(h * 0.06),
    );
    canvas.drawRRect(body, metal);
    canvas.drawRRect(body, outline);

    // 窓(歯車が見える)
    final window = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.52),
          width: w * 0.30,
          height: h * 0.38),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(window, Paint()..color = RS.white);
    canvas.drawRRect(window, outline);

    // 歯車2つ
    _drawGear(canvas, Offset(w * 0.45, h * 0.50), h * 0.15, 8, outline);
    _drawGear(canvas, Offset(w * 0.56, h * 0.58), h * 0.10, 7, outline);

    // 下部のダイヤル
    for (var i = 0; i < 4; i++) {
      final x = w * (0.40 + i * 0.065);
      canvas.drawCircle(Offset(x, h * 0.86), h * 0.035, outline);
    }
  }

  void _drawGear(
      Canvas canvas, Offset center, double radius, int teeth, Paint paint) {
    final path = Path();
    for (var i = 0; i < teeth * 2; i++) {
      final r = i.isEven ? radius : radius * 0.72;
      final a = 2 * pi * i / (teeth * 2);
      final p = Offset(center.dx + cos(a) * r, center.dy + sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF4A4A4E));
    canvas.drawCircle(center, radius * 0.28, Paint()..color = RS.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ミント台座(横線の目盛りでミント回数を表示)。
class MintPedestal extends StatelessWidget {
  const MintPedestal({
    super.key,
    required this.mintCount,
    required this.maxMint,
  });

  final int mintCount;
  final int maxMint;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 34),
      painter: _PedestalPainter(mintCount: mintCount, maxMint: maxMint),
    );
  }
}

class _PedestalPainter extends CustomPainter {
  _PedestalPainter({required this.mintCount, required this.maxMint});

  final int mintCount;
  final int maxMint;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outline = Paint()
      ..color = RS.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    // 台形の台座
    final path = Path()
      ..moveTo(w * 0.06, 0)
      ..lineTo(w * 0.94, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = RS.white);
    canvas.drawPath(path, outline);

    // ミント目盛り
    final cellW = w * 0.88 / maxMint;
    for (var i = 0; i < maxMint; i++) {
      final rect = Rect.fromLTWH(w * 0.06 + cellW * i + 2, h * 0.22,
          cellW - 4, h * 0.56);
      if (i < mintCount) {
        canvas.drawRect(rect, Paint()..color = RS.mint);
        // 「m」風のマーク
        final tp = TextPainter(
          text: TextSpan(
            text: 'm',
            style: TextStyle(
              color: RS.ink,
              fontSize: h * 0.42,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              fontFamily: RS.numFont,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
            canvas,
            rect.center - Offset(tp.width / 2, tp.height / 2));
      }
      canvas.drawRect(rect, outline..strokeWidth = 1.6);
    }
  }

  @override
  bool shouldRepaint(_PedestalPainter old) =>
      old.mintCount != mintCount || old.maxMint != maxMint;
}

/// フュージョン画面の五角形土台。
class PentagonBase extends StatelessWidget {
  const PentagonBase({super.key, required this.glowColor});

  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PentagonPainter(glow: glowColor));
  }
}

class _PentagonPainter extends CustomPainter {
  _PentagonPainter({required this.glow});

  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.40;
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final a = -pi / 2 + 2 * pi * i / 5;
      final p = Offset(c.dx + cos(a) * r, c.dy + sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFC9C9C9)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF9E9E9E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.015);

    // 中央円(外側にグロー)
    canvas.drawCircle(
        c,
        size.width * 0.21,
        Paint()
          ..color = glow.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawCircle(c, size.width * 0.195, Paint()..color = const Color(0xFF3A3A3E));
    canvas.drawCircle(
        c,
        size.width * 0.195,
        Paint()
          ..color = const Color(0xFF2A2A2E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.012);
  }

  @override
  bool shouldRepaint(_PentagonPainter old) => old.glow != glow;
}
