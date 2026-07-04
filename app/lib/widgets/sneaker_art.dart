import 'dart:math';

import 'package:flutter/material.dart';

import '../models/shoe.dart';
import '../theme/restep_theme.dart';

/// スニーカーのイラスト(完全自作のCustomPaint)。
///
/// チャンキーソール・ミッドソール・アッパー・トゥキャップ・ヒールカウンター・
/// スウッシュ・シューレース・タン・ヒールループを層で重ね、パネルごとの
/// グラデ陰影と、レアリティ由来のステンドグラス調モザイクで質感を出す。
/// タイプでアクセント色、レアリティでトリム色とモザイク配色が変わり、
/// シリアル値をシードに1足ごとに異なる柄になる。
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
        seed: shoe.serial ?? shoe.id.hashCode,
        rarityIndex: shoe.rarity.index,
      ),
    );
  }
}

class _SneakerPainter extends CustomPainter {
  _SneakerPainter({
    required this.accent,
    required this.trim,
    required this.seed,
    required this.rarityIndex,
  });

  final Color accent;
  final Color trim;
  final int seed;
  final int rarityIndex;

  // 光源は左上。パネルごとに上を明るく、下を暗く。
  static const _base = Color(0xFFF4EFE2); // アッパー地(オフホワイト)
  static const _baseShade = Color(0xFFE2D9C4);
  static const _outsole = Color(0xFF26262C);
  static const _outsoleLight = Color(0xFF3A3A42);
  static const _midsole = Color(0xFFFBFAF5);
  static const _midsoleShade = Color(0xFFDED8C8);
  static const _ink = RS.ink;

  Color _lighten(Color c, [double amt = 0.15]) => HSLColor.fromColor(c)
      .withLightness(
          (HSLColor.fromColor(c).lightness + amt).clamp(0.0, 1.0))
      .toColor();
  Color _darken(Color c, [double amt = 0.15]) => HSLColor.fromColor(c)
      .withLightness(
          (HSLColor.fromColor(c).lightness - amt).clamp(0.0, 1.0))
      .toColor();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // 内部座標は 0..1 正規化。P(x,y) で実座標へ。
    Offset p(double x, double y) => Offset(x * w, y * h);

    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    void fill(Path path, Paint paint) => canvas.drawPath(path, paint);
    void outline(Path path, [double weight = 1]) =>
        canvas.drawPath(path, line..strokeWidth = w * 0.012 * weight);

    // ---- 接地影 ----
    canvas.drawOval(
      Rect.fromCenter(
          center: p(0.52, 0.955), width: w * 0.86, height: h * 0.10),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.02),
    );

    // ---- アウトソール(濃色ラバー) ----
    final outsolePath = Path()
      ..moveTo(w * 0.06, h * 0.80)
      ..cubicTo(w * 0.02, h * 0.94, w * 0.12, h * 0.965, w * 0.22, h * 0.96)
      ..lineTo(w * 0.80, h * 0.96)
      ..cubicTo(w * 0.93, h * 0.96, w * 0.995, h * 0.90, w * 0.965, h * 0.80)
      ..cubicTo(w * 0.94, h * 0.74, w * 0.70, h * 0.75, w * 0.50, h * 0.75)
      ..cubicTo(w * 0.28, h * 0.75, w * 0.12, h * 0.74, w * 0.06, h * 0.80)
      ..close();
    fill(
        outsolePath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_outsoleLight, _outsole],
          ).createShader(Rect.fromLTWH(0, h * 0.74, w, h * 0.24)));
    outline(outsolePath, 1.3);
    // トレッド(縦の切れ込み)
    for (var i = 0; i < 9; i++) {
      final x = w * (0.14 + i * 0.085);
      canvas.drawLine(
          Offset(x, h * 0.86), Offset(x, h * 0.945),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.35)
            ..strokeWidth = w * 0.012
            ..strokeCap = StrokeCap.round);
    }

    // ---- ミッドソール(白・厚底) ----
    final midsolePath = Path()
      ..moveTo(w * 0.055, h * 0.78)
      ..cubicTo(w * 0.045, h * 0.66, w * 0.10, h * 0.63, w * 0.16, h * 0.63)
      ..cubicTo(w * 0.40, h * 0.60, w * 0.60, h * 0.60, w * 0.80, h * 0.655)
      ..cubicTo(w * 0.90, h * 0.675, w * 0.965, h * 0.70, w * 0.965, h * 0.775)
      ..cubicTo(w * 0.94, h * 0.735, w * 0.70, h * 0.745, w * 0.50, h * 0.745)
      ..cubicTo(w * 0.28, h * 0.745, w * 0.12, h * 0.735, w * 0.055, h * 0.78)
      ..close();
    fill(
        midsolePath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_midsole, _midsoleShade],
          ).createShader(Rect.fromLTWH(0, h * 0.60, w, h * 0.20)));
    outline(midsolePath, 1.2);
    // ヒールのエアユニット(丸)
    canvas.drawCircle(p(0.15, 0.70), w * 0.028,
        Paint()..color = accent.withValues(alpha: 0.85));
    canvas.drawCircle(p(0.15, 0.70), w * 0.028, line..strokeWidth = w * 0.01);

    // ---- アッパー本体 ----
    final upperPath = Path()
      ..moveTo(w * 0.11, h * 0.66)
      ..lineTo(w * 0.11, h * 0.42)
      ..cubicTo(w * 0.11, h * 0.30, w * 0.16, h * 0.25, w * 0.25, h * 0.25)
      ..lineTo(w * 0.45, h * 0.25)
      ..cubicTo(w * 0.53, h * 0.25, w * 0.57, h * 0.30, w * 0.62, h * 0.37)
      ..cubicTo(w * 0.73, h * 0.45, w * 0.83, h * 0.51, w * 0.905, h * 0.585)
      ..cubicTo(w * 0.935, h * 0.615, w * 0.925, h * 0.645, w * 0.875, h * 0.655)
      ..cubicTo(w * 0.60, h * 0.665, w * 0.32, h * 0.665, w * 0.11, h * 0.66)
      ..close();
    fill(
        upperPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, _base, _baseShade],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(0, h * 0.20, w, h * 0.48)));
    outline(upperPath, 1.3);

    // ---- ヒールカウンター(かかと・トリム色) ----
    final heelPath = Path()
      ..moveTo(w * 0.11, h * 0.64)
      ..lineTo(w * 0.11, h * 0.42)
      ..cubicTo(w * 0.11, h * 0.30, w * 0.16, h * 0.25, w * 0.25, h * 0.25)
      ..lineTo(w * 0.30, h * 0.25)
      ..cubicTo(w * 0.24, h * 0.34, w * 0.22, h * 0.48, w * 0.235, h * 0.635)
      ..cubicTo(w * 0.19, h * 0.645, w * 0.15, h * 0.645, w * 0.11, h * 0.64)
      ..close();
    fill(
        heelPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_lighten(trim, 0.12), _darken(trim, 0.05)],
          ).createShader(Rect.fromLTWH(0, h * 0.25, w * 0.3, h * 0.4)));
    outline(heelPath, 1.1);
    _mosaic(canvas, heelPath, Rect.fromLTWH(w * 0.11, h * 0.30, w * 0.20, h * 0.32),
        seed + 3, [trim, _darken(trim, 0.12), _lighten(trim, 0.15)]);

    // ---- トゥキャップ(つま先・アクセント色+モザイク) ----
    final toePath = Path()
      ..moveTo(w * 0.66, h * 0.585)
      ..cubicTo(w * 0.74, h * 0.47, w * 0.83, h * 0.51, w * 0.905, h * 0.585)
      ..cubicTo(w * 0.935, h * 0.615, w * 0.925, h * 0.645, w * 0.875, h * 0.655)
      ..cubicTo(w * 0.78, h * 0.662, w * 0.70, h * 0.66, w * 0.635, h * 0.655)
      ..cubicTo(w * 0.63, h * 0.62, w * 0.64, h * 0.60, w * 0.66, h * 0.585)
      ..close();
    fill(
        toePath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_lighten(accent, 0.12), _darken(accent, 0.08)],
          ).createShader(Rect.fromLTWH(w * 0.6, h * 0.47, w * 0.35, h * 0.2)));
    _mosaic(canvas, toePath, Rect.fromLTWH(w * 0.63, h * 0.47, w * 0.30, h * 0.19),
        seed + 7, [accent, _lighten(accent, 0.18), trim, _lighten(trim, 0.1)]);
    outline(toePath, 1.1);

    // ---- スウッシュ(サイドのうねり・タイプ色) ----
    final swoosh = Path()
      ..moveTo(w * 0.27, h * 0.54)
      ..cubicTo(w * 0.42, h * 0.60, w * 0.58, h * 0.585, w * 0.80, h * 0.50)
      ..cubicTo(w * 0.66, h * 0.60, w * 0.50, h * 0.645, w * 0.30, h * 0.635)
      ..cubicTo(w * 0.27, h * 0.62, w * 0.255, h * 0.585, w * 0.27, h * 0.54)
      ..close();
    fill(
        swoosh,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_lighten(accent, 0.1), _darken(accent, 0.12)],
          ).createShader(Rect.fromLTWH(w * 0.25, h * 0.5, w * 0.55, h * 0.14)));
    outline(swoosh, 1.0);

    // ---- アイステイ(シューレース穴+紐) ----
    // 穴の並び(甲の上を斜めに)
    final eyelets = <Offset>[];
    for (var i = 0; i < 4; i++) {
      final t = i / 3.0;
      // 上列
      eyelets.add(p(0.40 + t * 0.16, 0.30 + t * 0.045));
      // 下列
      eyelets.add(p(0.44 + t * 0.16, 0.40 + t * 0.045));
    }
    // 紐(上列と下列をクロス)
    final lace = Paint()
      ..color = _base
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;
    final laceEdge = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final aTop = eyelets[i * 2];
      final aBot = eyelets[i * 2 + 1];
      final bTop = eyelets[(i + 1) * 2];
      final bBot = eyelets[(i + 1) * 2 + 1];
      canvas.drawLine(aTop, bBot, laceEdge);
      canvas.drawLine(aBot, bTop, laceEdge);
    }
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(eyelets[i * 2], eyelets[(i + 1) * 2 + 1], lace);
      canvas.drawLine(eyelets[i * 2 + 1], eyelets[(i + 1) * 2], lace);
    }
    // ハトメ
    for (final e in eyelets) {
      canvas.drawCircle(e, w * 0.017, Paint()..color = _darken(trim, 0.1));
      canvas.drawCircle(e, w * 0.017, line..strokeWidth = w * 0.008);
      canvas.drawCircle(e, w * 0.007, Paint()..color = _outsole);
    }

    // ---- タン(履き口の舌) ----
    final tongue = Path()
      ..moveTo(w * 0.38, h * 0.30)
      ..cubicTo(w * 0.40, h * 0.20, w * 0.47, h * 0.19, w * 0.49, h * 0.28)
      ..cubicTo(w * 0.47, h * 0.31, w * 0.41, h * 0.32, w * 0.38, h * 0.30)
      ..close();
    fill(tongue, Paint()..color = _lighten(trim, 0.2));
    outline(tongue, 1.0);

    // ---- カラー(履き口のパッド) ----
    final collar = Path()
      ..moveTo(w * 0.22, h * 0.26)
      ..cubicTo(w * 0.19, h * 0.34, w * 0.20, h * 0.44, w * 0.235, h * 0.52)
      ..cubicTo(w * 0.27, h * 0.46, w * 0.27, h * 0.34, w * 0.28, h * 0.27)
      ..cubicTo(w * 0.26, h * 0.255, w * 0.24, h * 0.255, w * 0.22, h * 0.26)
      ..close();
    fill(collar, Paint()..color = _lighten(accent, 0.22));
    outline(collar, 1.0);
    // カラーのステッチ
    _dashedPath(
        canvas,
        Path()
          ..moveTo(w * 0.235, h * 0.30)
          ..cubicTo(w * 0.225, h * 0.38, w * 0.235, h * 0.46, w * 0.25, h * 0.5),
        _ink,
        w * 0.006);

    // ---- ヒールループ(黄色いつまみ) ----
    final loop = Path()
      ..moveTo(w * 0.10, h * 0.34)
      ..cubicTo(w * 0.03, h * 0.32, w * 0.03, h * 0.44, w * 0.10, h * 0.44)
      ..lineTo(w * 0.12, h * 0.42)
      ..cubicTo(w * 0.075, h * 0.42, w * 0.075, h * 0.36, w * 0.12, h * 0.36)
      ..close();
    fill(loop, Paint()..color = RS.yellow);
    outline(loop, 1.1);

    // ---- パネルのステッチ ----
    _dashedPath(
        canvas,
        Path()
          ..moveTo(w * 0.30, h * 0.545)
          ..cubicTo(
              w * 0.45, h * 0.605, w * 0.60, h * 0.59, w * 0.80, h * 0.505),
        _ink,
        w * 0.006);
    _dashedPath(
        canvas,
        Path()
          ..moveTo(w * 0.635, h * 0.60)
          ..cubicTo(w * 0.63, h * 0.63, w * 0.70, h * 0.655, w * 0.80, h * 0.655),
        _ink,
        w * 0.006);

    // ---- ミッドソールのライン(1本の帯) ----
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.07, h * 0.72)
        ..cubicTo(w * 0.40, h * 0.685, w * 0.62, h * 0.685, w * 0.945, h * 0.73),
      Paint()
        ..color = accent.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018
        ..strokeCap = StrokeCap.round,
    );

    // ---- 光沢ハイライト(アッパー上面の柔らかい照り) ----
    canvas.save();
    canvas.clipPath(upperPath);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.14, h * 0.30)
        ..cubicTo(w * 0.30, h * 0.24, w * 0.52, h * 0.28, w * 0.66, h * 0.40)
        ..cubicTo(w * 0.50, h * 0.36, w * 0.30, h * 0.36, w * 0.14, h * 0.40)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.24, w, h * 0.18)),
    );
    canvas.restore();

    // ---- リムハイライト(上辺の光) ----
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.16, h * 0.255)
        ..lineTo(w * 0.44, h * 0.255)
        ..cubicTo(w * 0.52, h * 0.255, w * 0.56, h * 0.30, w * 0.61, h * 0.365),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.01
        ..strokeCap = StrokeCap.round,
    );

    // ---- レジェンダリー/エピックのきらめき ----
    if (rarityIndex >= 3) {
      final rng = Random(seed);
      for (var i = 0; i < (rarityIndex == 4 ? 5 : 3); i++) {
        final c = p(0.2 + rng.nextDouble() * 0.7, 0.28 + rng.nextDouble() * 0.3);
        _sparkle(canvas, c, w * (0.02 + rng.nextDouble() * 0.015));
      }
    }
  }

  /// パネルにステンドグラス調の三角モザイクをクリップして描く。
  void _mosaic(Canvas canvas, Path clip, Rect bounds, int seed,
      List<Color> palette) {
    canvas.save();
    canvas.clipPath(clip);
    final rng = Random(seed);
    final cols = 5;
    final rows = 3;
    final cw = bounds.width / cols;
    final ch = bounds.height / rows;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = bounds.left + c * cw;
        final y = bounds.top + r * ch;
        // セルを2つの三角に割る
        final tl = Offset(x, y);
        final tr = Offset(x + cw, y);
        final bl = Offset(x, y + ch);
        final br = Offset(x + cw, y + ch);
        final flip = (r + c).isEven;
        final t1 = Path()
          ..addPolygon(
              flip ? [tl, tr, bl] : [tl, tr, br], true);
        final t2 = Path()
          ..addPolygon(
              flip ? [tr, br, bl] : [tl, br, bl], true);
        canvas.drawPath(
            t1, Paint()..color = palette[rng.nextInt(palette.length)]);
        canvas.drawPath(
            t2, Paint()..color = palette[rng.nextInt(palette.length)]);
      }
    }
    // モザイクの目地(細い線)
    final grout = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = bounds.width * 0.01;
    for (var c = 0; c <= cols; c++) {
      canvas.drawLine(Offset(bounds.left + c * cw, bounds.top),
          Offset(bounds.left + c * cw, bounds.bottom), grout);
    }
    for (var r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(bounds.left, bounds.top + r * ch),
          Offset(bounds.right, bounds.top + r * ch), grout);
    }
    canvas.restore();
  }

  /// 破線でパスをなぞる(ステッチ表現)。
  void _dashedPath(Canvas canvas, Path path, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      final dash = width * 2.2;
      final gap = width * 2.0;
      while (dist < metric.length) {
        final seg = metric.extractPath(dist, dist + dash);
        canvas.drawPath(seg, paint);
        dist += dash + gap;
      }
    }
  }

  void _sparkle(Canvas canvas, Offset c, double r) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..cubicTo(c.dx + r * 0.2, c.dy - r * 0.2, c.dx + r * 0.2, c.dy - r * 0.2,
          c.dx + r, c.dy)
      ..cubicTo(c.dx + r * 0.2, c.dy + r * 0.2, c.dx + r * 0.2, c.dy + r * 0.2,
          c.dx, c.dy + r)
      ..cubicTo(c.dx - r * 0.2, c.dy + r * 0.2, c.dx - r * 0.2, c.dy + r * 0.2,
          c.dx - r, c.dy)
      ..cubicTo(c.dx - r * 0.2, c.dy - r * 0.2, c.dx - r * 0.2, c.dy - r * 0.2,
          c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SneakerPainter old) =>
      old.accent != accent ||
      old.trim != trim ||
      old.seed != seed ||
      old.rarityIndex != rarityIndex;
}
