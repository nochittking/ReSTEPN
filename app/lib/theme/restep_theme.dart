import 'package:flutter/material.dart';

import '../models/shoe.dart';

/// RE:STEPのデザイントークン。
/// 参考資料(本家スクショ)から抽出した配色・形状ルールを一元管理する。
class RS {
  RS._();

  // 基調色
  static const cream = Color(0xFFF0EFE9); // 画面地
  static const lavender = Color(0xFFE7E2F6); // ホーム上部
  static const mint = Color(0xFF8BEDC7); // 主ボタン・アクセント
  static const mintDark = Color(0xFF35B98A);
  static const ink = Color(0xFF1E1E22); // 文字・枠線
  static const border = Color(0xFF3A3A40); // カード枠
  static const white = Colors.white;
  static const charcoal = Color(0xFF2B2B2E); // ムーブ画面背景
  static const charcoalCard = Color(0xFF3A3A3E);
  static const grey = Color(0xFF9E9E9E);
  static const purple = Color(0xFF9F7BEA);
  static const purpleDeep = Color(0xFF8E5BF0);
  static const orange = Color(0xFFF5A63B);
  static const blue = Color(0xFF6EC1F6);
  static const red = Color(0xFFE5484D);
  static const yellow = Color(0xFFF7C948);

  // 属性色(効率=黄 / 幸運=水色 / 快適=赤 / 回復=紫)
  static const attrEfficiency = Color(0xFFF2C14E);
  static const attrLuck = Color(0xFF7CC7F0);
  static const attrComfort = Color(0xFFE9605A);
  static const attrResilience = Color(0xFF8E8AE0);

  // レアリティ色
  static const rarityColors = {
    Rarity.common: Color(0xFFB9B9B9),
    Rarity.uncommon: Color(0xFF6FCF97),
    Rarity.rare: Color(0xFF5FA8E9),
    Rarity.epic: Color(0xFFA26BF0),
    Rarity.legendary: Color(0xFFF2994A),
  };

  // タイプピル色(ウォーカー=緑 / ジョガー=青 / ランナー=橙 / オールラウンダー=水色)
  static const typeColors = {
    ShoeType.walker: Color(0xFF58BE89),
    ShoeType.jogger: Color(0xFF5F8FD9),
    ShoeType.runner: Color(0xFFE08A3C),
    ShoeType.allRounder: Color(0xFF64B6D9),
  };

  static Color rarityColor(Rarity r) => rarityColors[r]!;
  static Color typeColor(ShoeType t) => typeColors[t]!;

  // 数字・欧文用(太い斜体) / 日本語はNotoSansJPへフォールバック
  static const numFont = 'Poppins';
  static const jpFont = 'NotoSansJP';

  /// 大きな数字用スタイル(Poppins ExtraBold Italic)
  static TextStyle number({
    double size = 32,
    Color color = ink,
    FontWeight weight = FontWeight.w800,
  }) =>
      TextStyle(
        fontFamily: numFont,
        fontFamilyFallback: const [jpFont],
        fontStyle: FontStyle.italic,
        fontWeight: weight,
        fontSize: size,
        color: color,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// 見出し・ラベル用(太字イタリック。日本語はNotoの太字で表示される)
  static TextStyle label({
    double size = 14,
    Color color = ink,
    bool italic = true,
  }) =>
      TextStyle(
        fontFamily: numFont,
        fontFamilyFallback: const [jpFont],
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        fontWeight: FontWeight.w700,
        fontSize: size,
        color: color,
        height: 1.3,
      );

  /// 本文用
  static TextStyle body({double size = 13, Color color = ink}) => TextStyle(
        fontFamily: jpFont,
        fontWeight: FontWeight.w400,
        fontSize: size,
        color: color,
        height: 1.5,
      );

  static ThemeData theme() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(seedColor: mintDark),
        fontFamily: jpFont,
        dividerColor: const Color(0xFFE2E1DA),
      );
}
