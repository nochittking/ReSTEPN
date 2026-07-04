import 'dart:math';

import 'package:flutter/material.dart';

import '../models/shoe.dart';
import '../theme/restep_theme.dart';

/// スニーカーのイラスト(完全自作のCustomPaint)。
///
/// 設計方針(実在のスニーカーデザイン言語に基づく):
/// - タイプごとに別シルエット: ウォーカー=厚底ライフスタイル / ジョガー=レトロランナー /
///   ランナー=前傾パフォーマンス / オールラウンダー=ハイカット
/// - レアリティごとに実在の名作カラーウェイ準拠の3色設計(地色+主役+差し色)
/// - クリーンなセルシェーディング+自信のあるアウトライン
class SneakerArt extends StatelessWidget {
  const SneakerArt({super.key, required this.shoe, this.size = 160});

  final Shoe shoe;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.66),
      painter: _SneakerPainter(
        type: shoe.type,
        cw: _Colorway.of(shoe.rarity, shoe.serial ?? shoe.id.hashCode),
        seed: shoe.serial ?? shoe.id.hashCode,
        rarityIndex: shoe.rarity.index,
      ),
    );
  }
}

/// カラーウェイ(地色・オーバーレイ・差し色・ソール)。
class _Colorway {
  const _Colorway({
    required this.base,
    required this.baseDark,
    required this.overlay,
    required this.overlayDark,
    required this.accent,
    required this.sole,
    required this.soleDark,
    required this.laces,
    this.gloss = false,
    this.metallic = false,
  });

  final Color base, baseDark; // アッパー地
  final Color overlay, overlayDark; // オーバーレイパネル(主役色)
  final Color accent; // 差し色(ロゴ・ステッチ・ライン)
  final Color sole, soleDark; // ソール
  final Color laces;
  final bool gloss; // 光沢(シンセ/パテント)
  final bool metallic; // 金属光沢+スパークル

  static _Colorway of(Rarity r, int seed) {
    // 実在の名作カラーウェイ・ファミリーに準拠
    switch (r) {
      case Rarity.common: // トリプルホワイト(クリーンな神経質さ)
        return const _Colorway(
          base: Color(0xFFF4F2EC),
          baseDark: Color(0xFFDDDAD1),
          overlay: Color(0xFFE4E1D8),
          overlayDark: Color(0xFFC3BFB2),
          accent: Color(0xFF9B9A94),
          sole: Color(0xFFFFFFFF),
          soleDark: Color(0xFFD8D5CD),
          laces: Color(0xFFFFFFFF),
        );
      case Rarity.uncommon: // アースカラー(オリーブ×ボーン×ガムソール)
        return const _Colorway(
          base: Color(0xFFEAE3D2),
          baseDark: Color(0xFFCEC5AC),
          overlay: Color(0xFF6E7346),
          overlayDark: Color(0xFF4E5230),
          accent: Color(0xFFBE9B63),
          sole: Color(0xFFC89B5A),
          soleDark: Color(0xFFA47C3D),
          laces: Color(0xFFECE5D3),
        );
      case Rarity.rare: // ユニバーシティブルー(ロイヤル×白×ガム)
        return const _Colorway(
          base: Color(0xFFF3F1EB),
          baseDark: Color(0xFFD6D3CB),
          overlay: Color(0xFF3E6FB0),
          overlayDark: Color(0xFF2B4E82),
          accent: Color(0xFF6FA8DC),
          sole: Color(0xFFC89B5A),
          soleDark: Color(0xFFA47C3D),
          laces: Color(0xFFFFFFFF),
        );
      case Rarity.epic: // ブレッド(黒×クリムゾン、光沢)
        return const _Colorway(
          base: Color(0xFF25252C),
          baseDark: Color(0xFF141419),
          overlay: Color(0xFFC0392B),
          overlayDark: Color(0xFF88271D),
          accent: Color(0xFFEDEDED),
          sole: Color(0xFFF3F1EC),
          soleDark: Color(0xFFCDCAC1),
          laces: Color(0xFF1B1B21),
          gloss: true,
        );
      case Rarity.legendary: // メタリック(ディープパープル×ゴールド、玉虫)
        return const _Colorway(
          base: Color(0xFF2E2A48),
          baseDark: Color(0xFF1B1830),
          overlay: Color(0xFF6C4FC0),
          overlayDark: Color(0xFF3F2E80),
          accent: Color(0xFFE7C15A),
          sole: Color(0xFF272338),
          soleDark: Color(0xFF16142A),
          laces: Color(0xFFE7C15A),
          gloss: true,
          metallic: true,
        );
    }
  }
}

class _SneakerPainter extends CustomPainter {
  _SneakerPainter({
    required this.type,
    required this.cw,
    required this.seed,
    required this.rarityIndex,
  });

  final ShoeType type;
  final _Colorway cw;
  final int seed;
  final int rarityIndex;

  late double w;
  late double h;
  late Canvas _c;

  Offset _p(double x, double y) => Offset(x * w, y * h);

  Paint get _stroke => Paint()
    ..color = RS.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.014
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    w = size.width;
    h = size.height;

    // 接地影
    _c.drawOval(
      Rect.fromCenter(
          center: _p(0.52, 0.95), width: w * 0.84, height: h * 0.09),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.02),
    );

    switch (type) {
      case ShoeType.walker:
        _paintLifestyle();
      case ShoeType.jogger:
        _paintRetroRunner();
      case ShoeType.runner:
        _paintPerformance();
      case ShoeType.allRounder:
        _paintHighTop();
    }

    if (cw.metallic) _paintSparkles();
  }

  // ============ 共通ヘルパ ============

  /// 2トーンのセルシェーディングでパスを塗る。
  void _panel(Path path, Color light, Color dark,
      {double split = 0.58,
      Alignment begin = Alignment.topLeft,
      Alignment end = Alignment.bottomRight}) {
    final rect = path.getBounds();
    _c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: begin,
          end: end,
          colors: [light, light, dark, dark],
          stops: [0, (split - 0.03).clamp(0, 1), (split + 0.03).clamp(0, 1), 1],
        ).createShader(rect),
    );
    if (cw.gloss) {
      // 光沢: 上部にハイライトの帯
      _c.save();
      _c.clipPath(path);
      _c.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.42),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(rect),
      );
      _c.restore();
    }
  }

  void _flat(Path path, Color color) => _c.drawPath(path, Paint()..color = color);

  void _line(Path path, [double weight = 1.0]) =>
      _c.drawPath(path, _stroke..strokeWidth = w * 0.014 * weight);

  /// ステッチ(破線)。
  void _stitch(Path path, {Color? color, double weight = 0.006}) {
    final paint = Paint()
      ..color = color ?? RS.ink.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * weight
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      final dash = w * 0.018;
      final gap = w * 0.014;
      while (d < m.length) {
        _c.drawPath(m.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  /// ハトメ+クロスした紐。
  void _lacing(List<Offset> topRow, List<Offset> botRow) {
    final laceEdge = Paint()
      ..color = RS.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.032
      ..strokeCap = StrokeCap.round;
    final lace = Paint()
      ..color = cw.laces
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.024
      ..strokeCap = StrokeCap.round;
    final n = min(topRow.length, botRow.length);
    for (var i = 0; i < n - 1; i++) {
      _c.drawLine(topRow[i], botRow[i + 1], laceEdge);
      _c.drawLine(botRow[i], topRow[i + 1], laceEdge);
    }
    for (var i = 0; i < n - 1; i++) {
      _c.drawLine(topRow[i], botRow[i + 1], lace);
      _c.drawLine(botRow[i], topRow[i + 1], lace);
    }
    for (final row in [topRow, botRow]) {
      for (final e in row) {
        _c.drawCircle(e, w * 0.016, Paint()..color = cw.baseDark);
        _c.drawCircle(e, w * 0.016, _stroke..strokeWidth = w * 0.008);
        _c.drawCircle(e, w * 0.006, Paint()..color = RS.ink);
      }
    }
  }

  /// ブランドタブ(タンやヒールの小さなラベル)。
  void _tab(Offset center, double size, Color color) {
    final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size, height: size * 0.55),
        Radius.circular(size * 0.12));
    _c.drawRRect(rect, Paint()..color = color);
    _c.drawRRect(rect, _stroke..strokeWidth = w * 0.008);
  }

  // ============ ① 厚底ライフスタイル(ウォーカー) ============
  // レトロコート系。分厚いカップソール+クリーンな低いアッパー。
  void _paintLifestyle() {
    // 厚底ミッドソール(カップソール)
    final sole = Path()
      ..moveTo(w * 0.05, h * 0.70)
      ..cubicTo(w * 0.03, h * 0.70, w * 0.03, h * 0.90, w * 0.16, h * 0.905)
      ..lineTo(w * 0.86, h * 0.905)
      ..cubicTo(w * 0.965, h * 0.905, w * 0.975, h * 0.86, w * 0.95, h * 0.70)
      ..cubicTo(w * 0.70, h * 0.66, w * 0.30, h * 0.66, w * 0.05, h * 0.70)
      ..close();
    _panel(sole, cw.sole, cw.soleDark, split: 0.5);
    _line(sole, 1.2);
    // ソールの水平ライン(2枚重ね)
    _c.drawPath(
      Path()
        ..moveTo(w * 0.05, h * 0.80)
        ..cubicTo(w * 0.4, h * 0.78, w * 0.6, h * 0.78, w * 0.95, h * 0.80),
      Paint()
        ..color = cw.soleDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );
    // アウトソールの縁(ガム/暗色)
    _c.drawPath(
      Path()
        ..moveTo(w * 0.05, h * 0.87)
        ..cubicTo(w * 0.4, h * 0.855, w * 0.6, h * 0.855, w * 0.95, h * 0.87),
      Paint()
        ..color = RS.ink.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02,
    );

    // アッパー本体(低くクリーン)
    final upper = Path()
      ..moveTo(w * 0.10, h * 0.68)
      ..lineTo(w * 0.10, h * 0.42)
      ..cubicTo(w * 0.10, h * 0.32, w * 0.15, h * 0.28, w * 0.24, h * 0.28)
      ..lineTo(w * 0.46, h * 0.28)
      ..cubicTo(w * 0.56, h * 0.28, w * 0.62, h * 0.34, w * 0.70, h * 0.42)
      ..cubicTo(w * 0.80, h * 0.50, w * 0.88, h * 0.55, w * 0.92, h * 0.62)
      ..cubicTo(w * 0.935, h * 0.66, w * 0.90, h * 0.685, w * 0.84, h * 0.69)
      ..cubicTo(w * 0.55, h * 0.695, w * 0.30, h * 0.695, w * 0.10, h * 0.68)
      ..close();
    _panel(upper, cw.base, cw.baseDark, split: 0.62);
    _line(upper, 1.3);

    // トゥキャップのステッチ(パンチング穴つき)
    final toe = Path()
      ..moveTo(w * 0.66, h * 0.44)
      ..cubicTo(w * 0.78, h * 0.50, w * 0.88, h * 0.56, w * 0.92, h * 0.62)
      ..cubicTo(w * 0.935, h * 0.66, w * 0.90, h * 0.685, w * 0.84, h * 0.69)
      ..cubicTo(w * 0.75, h * 0.695, w * 0.68, h * 0.69, w * 0.63, h * 0.685)
      ..cubicTo(w * 0.60, h * 0.58, w * 0.62, h * 0.50, w * 0.66, h * 0.44)
      ..close();
    _panel(toe, cw.base, cw.baseDark, split: 0.55);
    _line(toe, 1.0);
    // パンチング(3点×2列)
    for (var r = 0; r < 2; r++) {
      for (var i = 0; i < 3; i++) {
        _c.drawCircle(_p(0.72 + i * 0.05, 0.55 + r * 0.06), w * 0.008,
            Paint()..color = cw.baseDark);
      }
    }

    // サイドの3本ストライプ風オーバーレイ(オリジナルの帯)
    for (var i = 0; i < 3; i++) {
      final off = i * 0.075;
      final stripe = Path()
        ..moveTo(w * (0.30 + off), h * 0.44)
        ..lineTo(w * (0.36 + off), h * 0.44)
        ..lineTo(w * (0.30 + off), h * 0.67)
        ..lineTo(w * (0.24 + off), h * 0.67)
        ..close();
      _panel(stripe, cw.overlay, cw.overlayDark, split: 0.5);
      _line(stripe, 0.9);
    }

    // ヒールカウンター(オーバーレイ色)
    final heel = Path()
      ..moveTo(w * 0.10, h * 0.66)
      ..lineTo(w * 0.10, h * 0.42)
      ..cubicTo(w * 0.10, h * 0.32, w * 0.15, h * 0.28, w * 0.24, h * 0.28)
      ..lineTo(w * 0.27, h * 0.28)
      ..cubicTo(w * 0.20, h * 0.36, w * 0.18, h * 0.52, w * 0.19, h * 0.665)
      ..cubicTo(w * 0.16, h * 0.67, w * 0.13, h * 0.67, w * 0.10, h * 0.66)
      ..close();
    _panel(heel, cw.overlay, cw.overlayDark, split: 0.5);
    _line(heel, 1.0);

    // 履き口・カラー
    final collar = Path()
      ..moveTo(w * 0.22, h * 0.30)
      ..cubicTo(w * 0.24, h * 0.40, w * 0.30, h * 0.44, w * 0.40, h * 0.44)
      ..cubicTo(w * 0.34, h * 0.34, w * 0.30, h * 0.30, w * 0.22, h * 0.30)
      ..close();
    _flat(collar, cw.baseDark);
    _line(collar, 0.9);

    // シューレース
    _lacing(
      [_p(0.40, 0.34), _p(0.47, 0.36), _p(0.54, 0.40)],
      [_p(0.42, 0.44), _p(0.49, 0.46), _p(0.56, 0.49)],
    );
    // タン
    _tab(_p(0.40, 0.31), w * 0.06, cw.accent);

    // ヒールタブ
    _c.drawLine(_p(0.11, 0.34), _p(0.11, 0.42),
        Paint()
          ..color = cw.accent
          ..strokeWidth = w * 0.02
          ..strokeCap = StrokeCap.round);

    _stitch(Path()
      ..moveTo(w * 0.19, h * 0.34)
      ..cubicTo(w * 0.18, h * 0.5, w * 0.185, h * 0.6, w * 0.19, h * 0.66));
  }

  // ============ ② レトロランナー(ジョガー) ============
  // スリムなウェッジソール+スエードオーバーレイ+サイドストライプ。
  void _paintRetroRunner() {
    // スリムなウェッジソール(ガム)
    final sole = Path()
      ..moveTo(w * 0.06, h * 0.74)
      ..cubicTo(w * 0.04, h * 0.80, w * 0.10, h * 0.86, w * 0.18, h * 0.865)
      ..lineTo(w * 0.86, h * 0.845)
      ..cubicTo(w * 0.94, h * 0.84, w * 0.965, h * 0.80, w * 0.94, h * 0.75)
      ..cubicTo(w * 0.70, h * 0.70, w * 0.30, h * 0.71, w * 0.06, h * 0.74)
      ..close();
    _panel(sole, cw.sole, cw.soleDark, split: 0.45);
    _line(sole, 1.2);
    // ミッドソールの白い帯
    final mid = Path()
      ..moveTo(w * 0.06, h * 0.735)
      ..cubicTo(w * 0.3, h * 0.705, w * 0.7, h * 0.70, w * 0.94, h * 0.745)
      ..cubicTo(w * 0.7, h * 0.725, w * 0.3, h * 0.73, w * 0.06, h * 0.755)
      ..close();
    _flat(mid, const Color(0xFFF6F4EE));
    _line(mid, 0.8);

    // アッパー(低く流線)
    final upper = Path()
      ..moveTo(w * 0.11, h * 0.72)
      ..lineTo(w * 0.12, h * 0.44)
      ..cubicTo(w * 0.13, h * 0.34, w * 0.18, h * 0.30, w * 0.27, h * 0.305)
      ..lineTo(w * 0.44, h * 0.315)
      ..cubicTo(w * 0.54, h * 0.32, w * 0.60, h * 0.38, w * 0.70, h * 0.46)
      ..cubicTo(w * 0.80, h * 0.53, w * 0.89, h * 0.58, w * 0.94, h * 0.64)
      ..cubicTo(w * 0.96, h * 0.68, w * 0.92, h * 0.71, w * 0.85, h * 0.715)
      ..cubicTo(w * 0.55, h * 0.725, w * 0.30, h * 0.725, w * 0.11, h * 0.72)
      ..close();
    _panel(upper, cw.base, cw.baseDark, split: 0.66);
    _line(upper, 1.3);

    // トゥオーバーレイ(スエード)
    final toe = Path()
      ..moveTo(w * 0.70, h * 0.46)
      ..cubicTo(w * 0.80, h * 0.53, w * 0.89, h * 0.58, w * 0.94, h * 0.64)
      ..cubicTo(w * 0.96, h * 0.68, w * 0.92, h * 0.71, w * 0.85, h * 0.715)
      ..cubicTo(w * 0.76, h * 0.72, w * 0.70, h * 0.715, w * 0.66, h * 0.71)
      ..cubicTo(w * 0.63, h * 0.60, w * 0.66, h * 0.52, w * 0.70, h * 0.46)
      ..close();
    _panel(toe, cw.overlay, cw.overlayDark, split: 0.55);
    _line(toe, 1.0);
    _stitch(Path()
      ..moveTo(w * 0.67, h * 0.52)
      ..cubicTo(w * 0.72, h * 0.62, w * 0.80, h * 0.66, w * 0.9, h * 0.66));

    // サイドの斜めストライプ(ランナーの象徴)
    final stripe = Path()
      ..moveTo(w * 0.30, h * 0.50)
      ..lineTo(w * 0.40, h * 0.48)
      ..lineTo(w * 0.66, h * 0.70)
      ..lineTo(w * 0.55, h * 0.715)
      ..close();
    _panel(stripe, cw.overlay, cw.overlayDark, split: 0.5);
    _line(stripe, 1.0);

    // ヒールオーバーレイ
    final heel = Path()
      ..moveTo(w * 0.11, h * 0.70)
      ..lineTo(w * 0.12, h * 0.44)
      ..cubicTo(w * 0.13, h * 0.34, w * 0.18, h * 0.30, w * 0.27, h * 0.305)
      ..lineTo(w * 0.30, h * 0.31)
      ..cubicTo(w * 0.23, h * 0.38, w * 0.21, h * 0.54, w * 0.22, h * 0.71)
      ..cubicTo(w * 0.18, h * 0.715, w * 0.14, h * 0.71, w * 0.11, h * 0.70)
      ..close();
    _panel(heel, cw.overlay, cw.overlayDark, split: 0.5);
    _line(heel, 1.0);

    // 履き口
    final collar = Path()
      ..moveTo(w * 0.24, h * 0.32)
      ..cubicTo(w * 0.26, h * 0.42, w * 0.32, h * 0.46, w * 0.42, h * 0.46)
      ..cubicTo(w * 0.36, h * 0.36, w * 0.32, h * 0.32, w * 0.24, h * 0.32)
      ..close();
    _flat(collar, cw.baseDark);
    _line(collar, 0.9);

    // レース
    _lacing(
      [_p(0.42, 0.37), _p(0.49, 0.40), _p(0.56, 0.44)],
      [_p(0.44, 0.47), _p(0.51, 0.50), _p(0.58, 0.53)],
    );
    _tab(_p(0.42, 0.34), w * 0.055, cw.accent);

    // ヒールタブ
    _tab(_p(0.13, 0.40), w * 0.05, cw.accent);
  }

  // ============ ③ パフォーマンスランナー(ランナー) ============
  // トゥスプリング+ロッカーソール+積層フォーム+スピードライン。前傾。
  void _paintPerformance() {
    // 積層ミッドソール(2層のフォーム)+反り上がったつま先
    final foamLower = Path()
      ..moveTo(w * 0.05, h * 0.72)
      ..cubicTo(w * 0.02, h * 0.82, w * 0.10, h * 0.885, w * 0.20, h * 0.88)
      ..lineTo(w * 0.80, h * 0.85)
      ..cubicTo(w * 0.92, h * 0.84, w * 0.99, h * 0.78, w * 0.965, h * 0.70)
      ..cubicTo(w * 0.99, h * 0.62, w * 0.90, h * 0.60, w * 0.86, h * 0.66)
      ..cubicTo(w * 0.60, h * 0.70, w * 0.30, h * 0.70, w * 0.05, h * 0.72)
      ..close();
    _panel(foamLower, cw.accent, RS.ink.withValues(alpha: 0.6), split: 0.4);
    _line(foamLower, 1.2);
    // 上層フォーム(白)
    final foamUpper = Path()
      ..moveTo(w * 0.06, h * 0.68)
      ..cubicTo(w * 0.30, h * 0.63, w * 0.62, h * 0.63, w * 0.87, h * 0.60)
      ..cubicTo(w * 0.93, h * 0.585, w * 0.95, h * 0.63, w * 0.90, h * 0.66)
      ..cubicTo(w * 0.60, h * 0.71, w * 0.30, h * 0.71, w * 0.06, h * 0.72)
      ..cubicTo(w * 0.045, h * 0.70, w * 0.05, h * 0.685, w * 0.06, h * 0.68)
      ..close();
    _panel(foamUpper, cw.sole, cw.soleDark, split: 0.5);
    _line(foamUpper, 1.0);
    // アウトソールの分割(セグメント)
    for (var i = 0; i < 6; i++) {
      final x = 0.16 + i * 0.12;
      _c.drawLine(_p(x, 0.80), _p(x - 0.02, 0.885),
          Paint()
            ..color = RS.ink.withValues(alpha: 0.4)
            ..strokeWidth = w * 0.012
            ..strokeCap = StrokeCap.round);
    }

    // アッパー(前傾・低い・メッシュ)
    final upper = Path()
      ..moveTo(w * 0.12, h * 0.66)
      ..cubicTo(w * 0.12, h * 0.42, w * 0.16, h * 0.34, w * 0.26, h * 0.34)
      ..lineTo(w * 0.42, h * 0.35)
      ..cubicTo(w * 0.54, h * 0.36, w * 0.64, h * 0.42, w * 0.78, h * 0.50)
      ..cubicTo(w * 0.88, h * 0.55, w * 0.93, h * 0.58, w * 0.90, h * 0.63)
      ..cubicTo(w * 0.60, h * 0.67, w * 0.32, h * 0.67, w * 0.12, h * 0.66)
      ..close();
    _panel(upper, cw.base, cw.baseDark, split: 0.6);
    _line(upper, 1.3);
    // メッシュのテクスチャ(細かい斜線)
    _c.save();
    _c.clipPath(upper);
    final mesh = Paint()
      ..color = cw.baseDark.withValues(alpha: 0.4)
      ..strokeWidth = w * 0.004;
    for (var i = -6; i < 14; i++) {
      _c.drawLine(_p(0.1 + i * 0.06, 0.34), _p(0.02 + i * 0.06, 0.66), mesh);
    }
    _c.restore();

    // 大きなスピードライン(スウッシュ)— 前へ流れる
    final speed = Path()
      ..moveTo(w * 0.18, h * 0.52)
      ..cubicTo(w * 0.40, h * 0.60, w * 0.62, h * 0.56, w * 0.86, h * 0.44)
      ..cubicTo(w * 0.70, h * 0.60, w * 0.46, h * 0.66, w * 0.22, h * 0.63)
      ..cubicTo(w * 0.18, h * 0.60, w * 0.16, h * 0.56, w * 0.18, h * 0.52)
      ..close();
    _panel(speed, cw.overlay, cw.overlayDark, split: 0.5);
    _line(speed, 1.1);

    // ヒールクリップ(TPU)
    final clip = Path()
      ..moveTo(w * 0.12, h * 0.64)
      ..cubicTo(w * 0.12, h * 0.44, w * 0.16, h * 0.36, w * 0.24, h * 0.35)
      ..cubicTo(w * 0.20, h * 0.44, w * 0.19, h * 0.56, w * 0.21, h * 0.655)
      ..cubicTo(w * 0.17, h * 0.66, w * 0.14, h * 0.655, w * 0.12, h * 0.64)
      ..close();
    _panel(clip, cw.overlay, cw.overlayDark, split: 0.5);
    _line(clip, 1.0);

    // 履き口(前傾)
    final collar = Path()
      ..moveTo(w * 0.22, h * 0.36)
      ..cubicTo(w * 0.25, h * 0.44, w * 0.32, h * 0.48, w * 0.42, h * 0.47)
      ..cubicTo(w * 0.34, h * 0.40, w * 0.30, h * 0.36, w * 0.22, h * 0.36)
      ..close();
    _flat(collar, cw.baseDark);
    _line(collar, 0.9);

    // レース(前傾に沿って)
    _lacing(
      [_p(0.40, 0.40), _p(0.48, 0.43), _p(0.57, 0.47)],
      [_p(0.42, 0.49), _p(0.50, 0.52), _p(0.59, 0.55)],
    );
    _tab(_p(0.40, 0.37), w * 0.05, cw.accent);
  }

  // ============ ④ ハイカット(オールラウンダー) ============
  // 高い履き口(足首)+チャンキーカップソール+大きなタン。バスケ系。
  void _paintHighTop() {
    // カップソール
    final sole = Path()
      ..moveTo(w * 0.06, h * 0.72)
      ..cubicTo(w * 0.03, h * 0.74, w * 0.04, h * 0.885, w * 0.16, h * 0.89)
      ..lineTo(w * 0.86, h * 0.885)
      ..cubicTo(w * 0.96, h * 0.885, w * 0.975, h * 0.83, w * 0.95, h * 0.72)
      ..cubicTo(w * 0.70, h * 0.68, w * 0.30, h * 0.68, w * 0.06, h * 0.72)
      ..close();
    _panel(sole, cw.sole, cw.soleDark, split: 0.5);
    _line(sole, 1.2);
    _c.drawPath(
      Path()
        ..moveTo(w * 0.06, h * 0.815)
        ..cubicTo(w * 0.4, h * 0.80, w * 0.6, h * 0.80, w * 0.95, h * 0.815),
      Paint()
        ..color = RS.ink.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018,
    );

    // アッパー本体(足首まで高い)
    final upper = Path()
      ..moveTo(w * 0.13, h * 0.70)
      ..lineTo(w * 0.14, h * 0.30)
      ..cubicTo(w * 0.14, h * 0.16, w * 0.20, h * 0.12, w * 0.30, h * 0.13)
      ..cubicTo(w * 0.40, h * 0.14, w * 0.44, h * 0.20, w * 0.45, h * 0.30)
      ..cubicTo(w * 0.47, h * 0.40, w * 0.55, h * 0.44, w * 0.66, h * 0.48)
      ..cubicTo(w * 0.80, h * 0.53, w * 0.90, h * 0.58, w * 0.93, h * 0.64)
      ..cubicTo(w * 0.95, h * 0.68, w * 0.90, h * 0.705, w * 0.83, h * 0.71)
      ..cubicTo(w * 0.55, h * 0.715, w * 0.32, h * 0.715, w * 0.13, h * 0.70)
      ..close();
    _panel(upper, cw.base, cw.baseDark, split: 0.6);
    _line(upper, 1.3);

    // 足首カラー(パッド)
    final ankle = Path()
      ..moveTo(w * 0.16, h * 0.30)
      ..cubicTo(w * 0.16, h * 0.18, w * 0.21, h * 0.14, w * 0.30, h * 0.15)
      ..cubicTo(w * 0.39, h * 0.16, w * 0.42, h * 0.21, w * 0.43, h * 0.30)
      ..cubicTo(w * 0.40, h * 0.26, w * 0.34, h * 0.24, w * 0.30, h * 0.24)
      ..cubicTo(w * 0.24, h * 0.24, w * 0.19, h * 0.26, w * 0.16, h * 0.30)
      ..close();
    _flat(ankle, cw.baseDark);
    _line(ankle, 1.0);

    // トゥキャップ(オーバーレイ色)
    final toe = Path()
      ..moveTo(w * 0.66, h * 0.48)
      ..cubicTo(w * 0.80, h * 0.53, w * 0.90, h * 0.58, w * 0.93, h * 0.64)
      ..cubicTo(w * 0.95, h * 0.68, w * 0.90, h * 0.705, w * 0.83, h * 0.71)
      ..cubicTo(w * 0.74, h * 0.715, w * 0.66, h * 0.71, w * 0.61, h * 0.705)
      ..cubicTo(w * 0.58, h * 0.60, w * 0.61, h * 0.53, w * 0.66, h * 0.48)
      ..close();
    _panel(toe, cw.overlay, cw.overlayDark, split: 0.55);
    _line(toe, 1.0);
    for (var r = 0; r < 2; r++) {
      for (var i = 0; i < 3; i++) {
        _c.drawCircle(_p(0.70 + i * 0.05, 0.58 + r * 0.05), w * 0.008,
            Paint()..color = cw.overlayDark);
      }
    }

    // サイドのスウッシュ(大きな弧)
    final swoosh = Path()
      ..moveTo(w * 0.28, h * 0.40)
      ..cubicTo(w * 0.36, h * 0.56, w * 0.52, h * 0.62, w * 0.80, h * 0.56)
      ..cubicTo(w * 0.56, h * 0.70, w * 0.36, h * 0.66, w * 0.28, h * 0.56)
      ..cubicTo(w * 0.25, h * 0.50, w * 0.25, h * 0.44, w * 0.28, h * 0.40)
      ..close();
    _panel(swoosh, cw.overlay, cw.overlayDark, split: 0.5);
    _line(swoosh, 1.1);

    // ヒールオーバーレイ
    final heel = Path()
      ..moveTo(w * 0.13, h * 0.68)
      ..lineTo(w * 0.14, h * 0.40)
      ..cubicTo(w * 0.18, h * 0.44, w * 0.22, h * 0.54, w * 0.235, h * 0.70)
      ..cubicTo(w * 0.19, h * 0.705, w * 0.16, h * 0.70, w * 0.13, h * 0.68)
      ..close();
    _panel(heel, cw.overlay, cw.overlayDark, split: 0.5);
    _line(heel, 1.0);

    // 大きなタン+ブランドタブ
    final tongue = Path()
      ..moveTo(w * 0.30, h * 0.24)
      ..cubicTo(w * 0.32, h * 0.16, w * 0.40, h * 0.16, w * 0.42, h * 0.24)
      ..lineTo(w * 0.44, h * 0.36)
      ..cubicTo(w * 0.40, h * 0.38, w * 0.34, h * 0.38, w * 0.30, h * 0.36)
      ..close();
    _flat(tongue, cw.base);
    _line(tongue, 1.0);
    _tab(_p(0.37, 0.22), w * 0.07, cw.accent);

    // 高いレーシング(4段)
    _lacing(
      [_p(0.42, 0.30), _p(0.44, 0.40), _p(0.47, 0.50)],
      [_p(0.32, 0.32), _p(0.34, 0.42), _p(0.37, 0.52)],
    );

    // ヒールタブ
    _c.drawLine(_p(0.145, 0.34), _p(0.145, 0.44),
        Paint()
          ..color = cw.accent
          ..strokeWidth = w * 0.022
          ..strokeCap = StrokeCap.round);
  }

  // ============ レジェンダリーのきらめき ============
  void _paintSparkles() {
    final rng = Random(seed);
    for (var i = 0; i < 5; i++) {
      final c = _p(0.25 + rng.nextDouble() * 0.6, 0.28 + rng.nextDouble() * 0.3);
      final r = w * (0.018 + rng.nextDouble() * 0.014);
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..cubicTo(c.dx + r * 0.22, c.dy - r * 0.22, c.dx + r * 0.22,
            c.dy - r * 0.22, c.dx + r, c.dy)
        ..cubicTo(c.dx + r * 0.22, c.dy + r * 0.22, c.dx + r * 0.22,
            c.dy + r * 0.22, c.dx, c.dy + r)
        ..cubicTo(c.dx - r * 0.22, c.dy + r * 0.22, c.dx - r * 0.22,
            c.dy + r * 0.22, c.dx - r, c.dy)
        ..cubicTo(c.dx - r * 0.22, c.dy - r * 0.22, c.dx - r * 0.22,
            c.dy - r * 0.22, c.dx, c.dy - r)
        ..close();
      _c.drawPath(path, Paint()..color = cw.accent.withValues(alpha: 0.95));
    }
  }

  @override
  bool shouldRepaint(_SneakerPainter old) =>
      old.type != type || old.seed != seed || old.rarityIndex != rarityIndex;
}
