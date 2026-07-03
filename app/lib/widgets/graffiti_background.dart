import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/restep_theme.dart';

/// ホームのスニーカーヒーローカード背景。
/// ダーク地に稲妻・×印・抽象シルエットを散らした自作アート(シード固定で毎回同じ絵)。
class GraffitiBackground extends StatelessWidget {
  const GraffitiBackground({super.key, this.seed = 7});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GraffitiPainter(seed: seed));
  }
}

class _GraffitiPainter extends CustomPainter {
  _GraffitiPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final w = size.width;
    final h = size.height;

    // 地: 濃紺〜黒のグラデーション
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17171C), Color(0xFF26222E)],
        ).createShader(Offset.zero & size),
    );

    // 薄いグリッド線
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(Offset(w * i / 4, 0), Offset(w * i / 4, h), grid);
      canvas.drawLine(Offset(0, h * i / 3), Offset(w, h * i / 3), grid);
    }

    // 斜めの光条
    final beam = Path()
      ..moveTo(w * 0.15, 0)
      ..lineTo(w * 0.45, 0)
      ..lineTo(w * 0.85, h)
      ..lineTo(w * 0.55, h)
      ..close();
    canvas.drawPath(
        beam, Paint()..color = Colors.white.withValues(alpha: 0.07));

    // ×印(白・グレー)
    for (var i = 0; i < 5; i++) {
      final cx = rng.nextDouble() * w;
      final cy = rng.nextDouble() * h;
      final s = w * (0.03 + rng.nextDouble() * 0.05);
      final p = Paint()
        ..color = Colors.white.withValues(alpha: 0.10 + rng.nextDouble() * 0.2)
        ..strokeWidth = s * 0.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - s, cy - s), Offset(cx + s, cy + s), p);
      canvas.drawLine(Offset(cx - s, cy + s), Offset(cx + s, cy - s), p);
    }

    // 稲妻(ライムグリーン)
    for (var i = 0; i < 3; i++) {
      final ox = rng.nextDouble() * w * 0.9;
      final oy = rng.nextDouble() * h * 0.7;
      final s = w * 0.05;
      final bolt = Path()
        ..moveTo(ox + s * 0.4, oy)
        ..lineTo(ox, oy + s * 0.9)
        ..lineTo(ox + s * 0.35, oy + s * 0.9)
        ..lineTo(ox + s * 0.1, oy + s * 1.8)
        ..lineTo(ox + s * 0.9, oy + s * 0.7)
        ..lineTo(ox + s * 0.5, oy + s * 0.7)
        ..lineTo(ox + s * 0.9, oy)
        ..close();
      canvas.drawPath(
          bolt,
          Paint()
            ..color = const Color(0xFF9BE15D)
                .withValues(alpha: 0.35 + rng.nextDouble() * 0.4));
    }

    // うさぎ風シルエット(抽象)
    for (var i = 0; i < 2; i++) {
      final cx = w * (0.12 + rng.nextDouble() * 0.75);
      final cy = h * (0.55 + rng.nextDouble() * 0.3);
      final s = w * 0.06;
      final ghost = Path()
        ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: s))
        ..addOval(Rect.fromCenter(
            center: Offset(cx - s * 0.45, cy - s * 1.1),
            width: s * 0.5,
            height: s * 1.4))
        ..addOval(Rect.fromCenter(
            center: Offset(cx + s * 0.45, cy - s * 1.1),
            width: s * 0.5,
            height: s * 1.4));
      canvas.drawPath(
          ghost,
          Paint()
            ..color = (i.isEven
                    ? const Color(0xFF9BE15D)
                    : Colors.white)
                .withValues(alpha: 0.18));
    }

    // 点線の円(中央装飾)
    final dotted = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final cr = w * 0.30;
    const dashCount = 40;
    for (var i = 0; i < dashCount; i += 2) {
      final a1 = 2 * pi * i / dashCount;
      final a2 = 2 * pi * (i + 1) / dashCount;
      canvas.drawArc(
          Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: cr),
          a1,
          a2 - a1,
          false,
          dotted);
    }
  }

  @override
  bool shouldRepaint(_GraffitiPainter old) => old.seed != seed;
}

/// リザルト画面の装飾ルートイラスト(抽象的な街並み+ルート線)。
class RouteArt extends StatelessWidget {
  const RouteArt({super.key, this.seed = 11});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RoutePainter(seed: seed));
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      Paint()..color = const Color(0xFFF7F6FB),
    );

    // 抽象的な建物パネル
    for (var i = 0; i < 6; i++) {
      final bw = w * (0.10 + rng.nextDouble() * 0.12);
      final bh = h * (0.18 + rng.nextDouble() * 0.30);
      final bx = rng.nextDouble() * (w - bw);
      final by = rng.nextDouble() * (h - bh);
      final colors = [
        const Color(0xFFDCE9F7),
        const Color(0xFFF7DCE9),
        const Color(0xFFE9F7DC),
        const Color(0xFFEFE3F9),
      ];
      canvas.drawRect(
        Rect.fromLTWH(bx, by, bw, bh),
        Paint()
          ..color =
              colors[rng.nextInt(colors.length)].withValues(alpha: 0.6),
      );
      final line = Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..strokeWidth = 1;
      for (var gx = 1; gx < 3; gx++) {
        canvas.drawLine(Offset(bx + bw * gx / 3, by),
            Offset(bx + bw * gx / 3, by + bh), line);
      }
    }

    // ルート線(緑の太い曲線)
    final route = Path()..moveTo(w * 0.10, h * 0.25);
    route.cubicTo(
        w * 0.35, h * 0.30, w * 0.40, h * 0.55, w * 0.60, h * 0.60);
    route.cubicTo(w * 0.75, h * 0.64, w * 0.80, h * 0.75, w * 0.88, h * 0.80);
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF6FCF7C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018
        ..strokeCap = StrokeCap.round,
    );

    // GO / ENDピン
    void pin(Offset c, Color color, String text) {
      canvas.drawCircle(c, w * 0.045, Paint()..color = color);
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: w * 0.028,
            fontWeight: FontWeight.w800,
            fontFamily: RS.numFont,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }

    pin(Offset(w * 0.10, h * 0.25), const Color(0xFF3BA168), 'GO');
    pin(Offset(w * 0.88, h * 0.80), const Color(0xFFE5484D), 'END');
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.seed != seed;
}
