import 'dart:math';

import 'package:flutter/material.dart';

import '../models/shoe.dart';

/// スニーカーのイラスト(完全自作のCustomPaint)。
///
/// ローポリ・アート: アッパーを解剖学的なゾーン(トゥ/ヴァンプ/レース枠/クォーター/
/// ヒールカウンター/襟/タン)に沿った平坦な単色ファセットで塗り、極太の黒アウトライン、
/// 多層のクリーム系ソール(差し色ライン+歯付きアウトソール)、飛び出したタン、
/// はしご状のレース、ヒールタブで構成する。シルエットはタイプごとに手作りし、
/// 配色は seed(シリアル値)で個体ごとに変わる。
class SneakerArt extends StatelessWidget {
  const SneakerArt({super.key, required this.shoe, this.size = 160});

  final Shoe shoe;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.74),
      painter: _LowPolyPainter(
        type: shoe.type,
        palette: _palette(shoe.rarity, shoe.serial ?? shoe.id.hashCode),
        seed: shoe.serial ?? shoe.id.hashCode,
        rarity: shoe.rarity,
      ),
    );
  }
}

// ============ パレット生成 ============

const _hueAnchors = {
  Rarity.common: [210, 175, 15, 45, 275, 330],
  Rarity.uncommon: [80, 25, 175, 340, 40],
  Rarity.rare: [220, 258, 190, 320, 200],
  Rarity.epic: [320, 190, 52, 25, 280],
  Rarity.legendary: [262, 282, 45, 210, 300],
};
const _slRanges = {
  Rarity.common: [0.66, 0.82, 0.55, 0.70],
  Rarity.uncommon: [0.48, 0.68, 0.42, 0.60],
  Rarity.rare: [0.60, 0.82, 0.50, 0.66],
  Rarity.epic: [0.82, 0.96, 0.55, 0.66],
  Rarity.legendary: [0.55, 0.82, 0.40, 0.60],
};

List<Color> _palette(Rarity r, int seed) {
  final rng = Random(seed);
  final anchors = _hueAnchors[r]!;
  final sl = _slRanges[r]!;
  final rot = rng.nextDouble() * 360;
  const n = 10;
  final out = <Color>[];
  for (var i = 0; i < n; i++) {
    final baseHue = anchors[i % anchors.length].toDouble();
    final hue = (baseHue + rot + (rng.nextDouble() * 24 - 12)) % 360;
    final sat = sl[0] + rng.nextDouble() * (sl[1] - sl[0]);
    final light = sl[2] + rng.nextDouble() * (sl[3] - sl[2]);
    out.add(HSLColor.fromAHSL(1, hue, sat, light).toColor());
  }
  if (r == Rarity.legendary) {
    for (final i in [2, 6]) {
      out[i] =
          HSLColor.fromAHSL(1, 44 + rng.nextDouble() * 6, 0.72, 0.56).toColor();
    }
  }
  return out;
}

// ============ ファセット ============

class _F {
  const _F(this.pts, this.role);
  final List<Offset> pts;
  final int role;
}

class _LowPolyPainter extends CustomPainter {
  _LowPolyPainter({
    required this.type,
    required this.palette,
    required this.seed,
    required this.rarity,
  });

  final ShoeType type;
  final List<Color> palette;
  final int seed;
  final Rarity rarity;

  static const _cream = Color(0xFFF4EDD8);
  static const _creamMid = Color(0xFFEADFC0);
  static const _creamDark = Color(0xFFD9CBA4);
  static const _ink = Color(0xFF1B1B21);
  static const _boltGreen = Color(0xFF41D07E);

  late double w, h;
  late Canvas _c;

  Offset _p(double x, double y) => Offset(x * w, y * h);

  Paint _blk(double weight) => Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * weight
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    w = size.width;
    h = size.height;

    _c.drawOval(
      Rect.fromCenter(center: _p(0.52, 0.965), width: w * 0.86, height: h * 0.07),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.13)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.02),
    );

    switch (type) {
      case ShoeType.walker:
        _drawShoe(_lowSpec(heelSpoiler: false));
      case ShoeType.jogger:
        _drawShoe(_lowSpec(heelSpoiler: true));
      case ShoeType.runner:
        _drawShoe(_highSpec(chunky: false));
      case ShoeType.allRounder:
        _drawShoe(_highSpec(chunky: true));
    }
  }

  void _drawShoe(_Spec s) {
    final silhouette = _path(s.silhouette);
    final upperPath = _path(s.upperOutline);

    // 1. 靴全体をクリームで塗る(ソール地)
    _c.drawPath(silhouette, Paint()..color = _cream);
    // ヒールウェッジの陰(ソール後方をわずかに濃く)
    _c.save();
    _c.clipPath(silhouette);
    _c.drawPath(
      _path([
        [0.05, 0.72], [0.30, 0.74], [0.30, 1.0], [0.03, 1.0],
      ]),
      Paint()..color = _creamMid.withValues(alpha: 0.5),
    );
    _c.restore();

    // 2. タン(飛び出す舌)— アッパーの後ろに先に描く
    if (s.tongue != null) {
      final t = _path(s.tongue!);
      _c.drawPath(t, Paint()..color = _cream);
      _c.drawPath(t, _blk(0.014));
      // タンのステッチ
      final tp = s.tongue!;
      _c.drawLine(_p(tp[0][0] + 0.015, tp[0][1] + 0.03),
          _p(tp[1][0] - 0.015, tp[1][1] + 0.03), _blk(0.007)..color = _creamDark);
    }

    // 3. アッパー: クリップしてゾーン別ファセットで塗る
    _c.save();
    _c.clipPath(upperPath);
    for (final f in s.facets) {
      _drawFacet(f);
    }
    for (final f in s.facets) {
      _c.drawPath(_path(f.pts.map((o) => [o.dx, o.dy]).toList()), _blk(0.009));
    }
    for (final seam in s.seams) {
      _c.drawPath(_polyline(seam), _blk(0.013));
    }
    _c.restore();

    // 4. ソールの差し色ライン(ミッドソールを走る帯)
    _c.save();
    _c.clipPath(silhouette);
    final stripeColor = HSLColor.fromColor(palette[3])
        .withLightness(0.5)
        .withSaturation(0.85)
        .toColor();
    _c.drawPath(_polyline(s.soleStripe),
        Paint()
          ..color = stripeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.03
          ..strokeCap = StrokeCap.round);
    _c.restore();

    // 5. 歯付きアウトソール(下縁)
    _drawOutsoleTeeth(s);

    // 6. ソール上端の分割線
    _c.drawPath(_polyline(s.soleSeam), _blk(0.014));

    // 7. レースケージ+はしご
    if (s.laceCage != null) _drawLaces(s.laceCage!, s.laceRungs);

    // 8. ヒールタブ
    if (s.heelTab != null) {
      _drawHeelTab(s.heelTab!);
    }

    // 9. かかとの稲妻バッジ
    _drawBolt(s.bolt);

    // 10. シルエット外周の1本の極太黒アウトライン
    _c.drawPath(silhouette, _blk(0.028));
  }

  void _drawFacet(_F f) {
    final path = _path(f.pts.map((o) => [o.dx, o.dy]).toList());
    final cx = f.pts.map((o) => o.dx).reduce((a, b) => a + b) / f.pts.length;
    final cy = f.pts.map((o) => o.dy).reduce((a, b) => a + b) / f.pts.length;
    final base = palette[f.role % palette.length];
    final hsl = HSLColor.fromColor(base);
    final j = ((((cx * 73 + cy * 37) * 1000).floor() % 100) / 100 - 0.5) * 0.05;
    _c.drawPath(
        path,
        Paint()
          ..color =
              hsl.withLightness((hsl.lightness + j).clamp(0.24, 0.84)).toColor());
  }

  // ソール下部の縦トレッド溝(シルエット内にクリップして描く)
  void _drawOutsoleTeeth(_Spec s) {
    _c.save();
    _c.clipPath(_path(s.silhouette));
    // 溝はソール下端バンドに、つま先寄りとかかと寄りに密度を持たせる
    for (var x = 0.10; x <= 0.92; x += 0.042) {
      // 中央部(0.35〜0.62)は溝を薄く/間引く
      final mid = x > 0.35 && x < 0.62;
      if (mid && (((x * 100).round()) % 2 == 0)) continue;
      _c.drawLine(
        _p(x, 0.86),
        _p(x, 1.02),
        _blk(0.008)..color = _ink.withValues(alpha: mid ? 0.35 : 0.7),
      );
    }
    _c.restore();
  }

  void _drawLaces(List<List<double>> cage, int rungs) {
    final cagePath = _path(cage);
    _c.drawPath(cagePath, Paint()..color = _ink.withValues(alpha: 0.88));
    _c.drawPath(cagePath, _blk(0.014));
    final top = _p(cage[0][0], cage[0][1]);
    final topR = _p(cage[1][0], cage[1][1]);
    final botR = _p(cage[2][0], cage[2][1]);
    final bot = _p(cage[3][0], cage[3][1]);
    for (var i = 1; i < rungs + 1; i++) {
      final t = i / (rungs + 1);
      final a = Offset.lerp(top, bot, t)!;
      final b = Offset.lerp(topR, botR, t)!;
      final mid = Offset.lerp(a, b, 0.5)!;
      final ra = Offset.lerp(mid, a, 0.36)!;
      final rb = Offset.lerp(mid, b, 0.36)!;
      final len = (b - a).distance;
      _c.drawLine(ra, rb, Paint()
        ..color = _cream
        ..strokeWidth = len * 0.15
        ..strokeCap = StrokeCap.round);
      _c.drawLine(ra, rb,
          Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.007);
    }
  }

  void _drawHeelTab(List<double> pos) {
    final o = _p(pos[0], pos[1]);
    final s = w * 0.045;
    final tab = Path()
      ..moveTo(o.dx - s * 0.5, o.dy)
      ..lineTo(o.dx - s * 0.9, o.dy - s * 1.4)
      ..lineTo(o.dx + s * 0.2, o.dy - s * 1.4)
      ..lineTo(o.dx + s * 0.5, o.dy)
      ..close();
    _c.drawPath(tab, Paint()..color = _cream);
    _c.drawPath(tab, _blk(0.012));
  }

  void _drawBolt(List<double>? pos) {
    if (pos == null) return;
    final cx = pos[0], cy = pos[1], s = w * 0.045;
    final o = _p(cx, cy);
    final bolt = Path()
      ..moveTo(o.dx + s * 0.3, o.dy - s)
      ..lineTo(o.dx - s * 0.3, o.dy + s * 0.1)
      ..lineTo(o.dx + s * 0.05, o.dy + s * 0.1)
      ..lineTo(o.dx - s * 0.25, o.dy + s)
      ..lineTo(o.dx + s * 0.45, o.dy - s * 0.2)
      ..lineTo(o.dx + s * 0.05, o.dy - s * 0.2)
      ..close();
    _c.drawPath(bolt, Paint()..color = _boltGreen);
    _c.drawPath(bolt, _blk(0.009));
  }

  Path _path(List<List<double>> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts[0][0] * w, pts[0][1] * h);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i][0] * w, pts[i][1] * h);
    }
    path.close();
    return path;
  }

  Path _polyline(List<List<double>> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts[0][0] * w, pts[0][1] * h);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i][0] * w, pts[i][1] * h);
    }
    return path;
  }

  _F _f(List<List<double>> pts, int role) =>
      _F(pts.map((e) => Offset(e[0], e[1])).toList(), role);

  // ============ ロー(ウォーカー/ジョガー) ============
  // 背は低めだが厚いソール。ジョガーは尖ったヒールスポイラー。
  _Spec _lowSpec({required bool heelSpoiler}) {
    // 後方トップ(スポイラー)
    final backTop = heelSpoiler
        ? [[0.10, 0.42], [0.13, 0.24], [0.19, 0.22], [0.22, 0.30], [0.26, 0.40]]
        : [[0.10, 0.42], [0.13, 0.26], [0.22, 0.22], [0.30, 0.24], [0.30, 0.36]];
    return _Spec(
      silhouette: [
        [0.05, 0.82], [0.08, 0.66], ...backTop,
        [0.40, 0.30], [0.46, 0.24], [0.52, 0.30], [0.62, 0.36],
        [0.76, 0.44], [0.90, 0.55], [0.965, 0.64], [0.95, 0.80],
        [0.87, 0.90], [0.20, 0.905], [0.06, 0.86],
      ],
      upperOutline: [
        [0.08, 0.66], ...backTop,
        [0.40, 0.30], [0.46, 0.24], [0.52, 0.30], [0.62, 0.36],
        [0.76, 0.44], [0.90, 0.55], [0.905, 0.66], [0.66, 0.68],
        [0.40, 0.68], [0.20, 0.67],
      ],
      soleSeam: [[0.08, 0.66], [0.20, 0.67], [0.40, 0.68], [0.66, 0.68], [0.905, 0.66]],
      soleStripe: [[0.08, 0.72], [0.4, 0.735], [0.7, 0.73], [0.92, 0.72]],
      outsoleLine: [[0.09, 0.895], [0.5, 0.905], [0.87, 0.895]],
      tongue: [[0.36, 0.20], [0.46, 0.22], [0.48, 0.40], [0.38, 0.40]],
      facets: [
        // ヒールカウンター
        _f([[0.08, 0.66], [0.10, 0.42], [0.22, 0.36], [0.24, 0.56], [0.22, 0.67]], 4),
        _f([backTop[1], backTop[2], backTop[3], [0.22, 0.36], [0.10, 0.42]], 5),
        // クォーター(色の塊)
        _f([[0.22, 0.36], [0.24, 0.56], [0.22, 0.67], [0.42, 0.68], [0.44, 0.46]], 0),
        _f([[0.22, 0.36], [0.44, 0.46], [0.46, 0.34], [0.30, 0.30], backTop.last], 1),
        _f([[0.44, 0.46], [0.42, 0.68], [0.60, 0.68], [0.58, 0.44]], 2),
        _f([[0.44, 0.46], [0.58, 0.44], [0.52, 0.30], [0.46, 0.30], [0.46, 0.34]], 6),
        // ヴァンプ〜トゥ
        _f([[0.58, 0.44], [0.60, 0.68], [0.72, 0.68], [0.70, 0.44]], 0),
        _f([[0.58, 0.44], [0.70, 0.44], [0.62, 0.36], [0.52, 0.30]], 3),
        _f([[0.70, 0.44], [0.72, 0.68], [0.905, 0.66], [0.90, 0.55], [0.76, 0.44]], 7),
        _f([[0.70, 0.44], [0.76, 0.44], [0.90, 0.55], [0.82, 0.48], [0.62, 0.36]], 8),
      ],
      seams: [
        [[0.23, 0.38], [0.22, 0.55], [0.22, 0.67]],
        [[0.70, 0.46], [0.71, 0.57], [0.72, 0.68]],
        [[0.58, 0.38], [0.58, 0.55], [0.60, 0.68]],
        [[0.44, 0.46], [0.43, 0.58], [0.42, 0.68]],
      ],
      laceCage: [[0.40, 0.34], [0.54, 0.40], [0.52, 0.52], [0.38, 0.46]],
      laceRungs: 4,
      heelTab: null,
      bolt: null,
    );
  }

  // ============ ハイカット(ランナー/オールラウンダー) ============
  // 背が高く、尖った襟+飛び出すタン。オールラウンダーは厚い波打つソール。
  _Spec _highSpec({required bool chunky}) {
    final soleBottom = chunky ? 0.92 : 0.90;
    final seamY = chunky ? 0.64 : 0.66;
    return _Spec(
      silhouette: [
        [0.05, 0.80], [0.10, 0.64], [0.12, 0.36], [0.13, 0.18],
        [0.17, 0.08], [0.25, 0.06], [0.30, 0.14], [0.31, 0.26], // 尖った襟
        [0.36, 0.22], [0.42, 0.28], // 履き口前(タンはこの上)
        [0.52, 0.30], [0.62, 0.36], [0.74, 0.44], [0.86, 0.54],
        [0.95, 0.63], [0.93, soleBottom - 0.10], [0.90, soleBottom],
        [0.20, soleBottom + 0.01], [0.06, soleBottom - 0.05],
      ],
      upperOutline: [
        [0.10, 0.64], [0.12, 0.36], [0.13, 0.18], [0.17, 0.08],
        [0.25, 0.06], [0.30, 0.14], [0.31, 0.26], [0.36, 0.22],
        [0.42, 0.28], [0.52, 0.30], [0.62, 0.36], [0.74, 0.44],
        [0.86, 0.54], [0.95, 0.63], [0.90, seamY], [0.66, seamY + 0.02],
        [0.40, seamY + 0.02], [0.20, seamY + 0.01],
      ],
      soleSeam: [
        [0.10, seamY], [0.20, seamY + 0.01], [0.40, seamY + 0.02],
        [0.66, seamY + 0.02], [0.90, seamY],
      ],
      soleStripe: [
        [0.08, seamY + 0.06], [0.4, seamY + 0.075], [0.7, seamY + 0.07],
        [0.92, seamY + 0.05],
      ],
      outsoleLine: [
        [0.08, soleBottom - 0.01], [0.5, soleBottom + 0.005], [0.90, soleBottom - 0.02],
      ],
      tongue: [[0.34, 0.16], [0.44, 0.20], [0.46, 0.40], [0.36, 0.40]],
      facets: [
        // 尖った襟(後)
        _f([[0.12, 0.36], [0.13, 0.18], [0.17, 0.08], [0.25, 0.06], [0.24, 0.22], [0.15, 0.36]], 4),
        _f([[0.25, 0.06], [0.30, 0.14], [0.31, 0.26], [0.24, 0.22]], 5),
        // ヒールカウンター
        _f([[0.12, 0.36], [0.15, 0.36], [0.24, 0.22], [0.26, 0.5], [0.13, 0.54]], 6),
        _f([[0.12, 0.36], [0.13, 0.54], [0.10, 0.64], [0.24, seamY + 0.01], [0.26, 0.5]], 0),
        // クォーター(大きな色の塊)
        _f([[0.26, 0.5], [0.24, seamY + 0.01], [0.44, seamY + 0.02], [0.46, 0.46], [0.34, 0.40]], 1),
        _f([[0.24, 0.22], [0.31, 0.26], [0.36, 0.22], [0.42, 0.28], [0.46, 0.46], [0.34, 0.40], [0.26, 0.5]], 2),
        _f([[0.46, 0.46], [0.44, seamY + 0.02], [0.62, seamY + 0.01], [0.60, 0.44]], 0),
        _f([[0.46, 0.46], [0.60, 0.44], [0.60, 0.34], [0.52, 0.30], [0.42, 0.28]], 3),
        // ヴァンプ〜トゥ
        _f([[0.60, 0.44], [0.62, seamY + 0.01], [0.74, seamY], [0.74, 0.46]], 1),
        _f([[0.74, 0.46], [0.74, seamY], [0.90, seamY], [0.95, 0.63], [0.86, 0.54]], 7),
        _f([[0.74, 0.46], [0.86, 0.54], [0.80, 0.48], [0.62, 0.36], [0.60, 0.44]], 8),
      ],
      seams: [
        [[0.24, 0.24], [0.26, 0.45], [0.24, seamY]],
        [[0.46, 0.30], [0.46, 0.48], [0.44, seamY + 0.02]],
        [[0.60, 0.44], [0.61, 0.55], [0.62, seamY + 0.01]],
        [[0.30, 0.14], [0.36, 0.22]],
      ],
      laceCage: [[0.38, 0.28], [0.50, 0.34], [0.47, 0.48], [0.35, 0.42]],
      laceRungs: 5,
      heelTab: null,
      bolt: null,
    );
  }

  @override
  bool shouldRepaint(_LowPolyPainter old) =>
      old.type != type || old.seed != seed || old.rarity != rarity;
}

class _Spec {
  _Spec({
    required this.silhouette,
    required this.upperOutline,
    required this.soleSeam,
    required this.soleStripe,
    required this.outsoleLine,
    required this.facets,
    required this.seams,
    required this.laceCage,
    required this.laceRungs,
    this.tongue,
    this.heelTab,
    this.bolt,
  });

  final List<List<double>> silhouette;
  final List<List<double>> upperOutline;
  final List<List<double>> soleSeam;
  final List<List<double>> soleStripe;
  final List<List<double>> outsoleLine;
  final List<_F> facets;
  final List<List<List<double>>> seams;
  final List<List<double>>? laceCage;
  final int laceRungs;
  final List<List<double>>? tongue;
  final List<double>? heelTab;
  final List<double>? bolt;
}
