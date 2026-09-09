import 'package:flutter/material.dart';

import '../config/game_config.dart';

/// ジェムの種類。対応する属性を強化する。
enum GemType {
  efficiency('効率', Color(0xFFF2C14E)),
  luck('幸運', Color(0xFF7CC7F0)),
  comfort('快適', Color(0xFFE9605A)),
  resilience('回復', Color(0xFF8E8AE0));

  const GemType(this.label, this.color);

  final String label;
  final Color color;
}

/// ジェム。装着すると対応属性に「固定値+割合」の強化が付く。
class Gem {
  Gem({
    required this.id,
    required this.type,
    required this.level,
    this.equippedShoeId,
  });

  final String id;
  final GemType type;
  final int level;

  /// 装着先シューズID(未装着はnull)
  String? equippedShoeId;

  /// 固定値ボーナス(Lv1〜9)。Lv9=+100。
  double get flatBonus => GameConfig.gemFlatBonus[level - 1];

  /// 割合ボーナス(Lv1〜9・%)。Lv9=40%。
  double get percentBonus => GameConfig.gemPercentBonus[level - 1];

  /// 強度(固定値+割合)。Lv9なら100+40=140。ジェムの格を1つの数で示す。
  double get intensity => flatBonus + percentBonus;

  String get displayName => '${type.label}ジェム Lv.$level';

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'level': level,
        'equippedShoeId': equippedShoeId,
      };

  factory Gem.fromJson(Map<String, dynamic> json) => Gem(
        id: json['id'] as String,
        type: GemType.values.byName(json['type'] as String),
        level: json['level'] as int,
        equippedShoeId: json['equippedShoeId'] as String?,
      );
}
