import 'dart:math';

import '../config/game_config.dart';
import 'gem.dart';

/// シューズタイプ(独自名称)。適正速度レンジは4区分。
enum ShoeType {
  walker('ウォーカー', 1.0, 6.0),
  jogger('ジョガー', 4.0, 10.0),
  runner('ランナー', 8.0, 20.0),
  allRounder('オールラウンダー', 1.0, 20.0);

  const ShoeType(this.label, this.minSpeedKmh, this.maxSpeedKmh);

  final String label;
  final double minSpeedKmh;
  final double maxSpeedKmh;

  bool inRange(double speedKmh) =>
      speedKmh >= minSpeedKmh && speedKmh <= maxSpeedKmh;

  String get rangeLabel =>
      '${minSpeedKmh.toStringAsFixed(0)}-${maxSpeedKmh.toStringAsFixed(0)} km/h';
}

/// レアリティ5段階。エナジーボーナスは1足ごとに加算される。
enum Rarity {
  common('コモン', 0.0),
  uncommon('アンコモン', 1.0),
  rare('レア', 2.0),
  epic('エピック', 3.0),
  legendary('レジェンダリー', 4.0);

  const Rarity(this.label, this.energyBonus);

  final String label;
  final double energyBonus;
}

/// シューズの4属性。
enum ShoeAttr {
  efficiency('効率'),
  luck('幸運'),
  comfort('快適'),
  resilience('回復');

  const ShoeAttr(this.label);

  final String label;

  GemType get gemType => GemType.values[index];
}

/// ミント/購入時の属性ロール。レアリティ帯から各属性を独立に抽選(小数1桁)。
Map<ShoeAttr, double> rollAttrs(Rarity rarity, Random rng) {
  final range = GameConfig.mintAttrRange[rarity.index];
  double roll() {
    final v = range.$1 + rng.nextDouble() * (range.$2 - range.$1);
    return (v * 10).round() / 10;
  }

  return {for (final a in ShoeAttr.values) a: roll()};
}

class Shoe {
  Shoe({
    required this.id,
    required this.type,
    required this.rarity,
    this.level = 0,
    this.durability = 100.0,
    this.mintCount = 0,
    this.serial,
    Map<ShoeAttr, double>? attrs,
    this.unspentPoints = 0,
  }) : attrs = attrs ?? {for (final a in ShoeAttr.values) a: 1.0};

  final String id;
  final ShoeType type;
  final Rarity rarity;
  int level;
  double durability;
  int mintCount;

  /// 個体ごとの基礎属性値(手動振り分けポイントもここに加算される)。
  final Map<ShoeAttr, double> attrs;

  /// 未割り当てのレベルアップポイント。
  int unspentPoints;

  /// 表示用のシリアル番号(#xxxxxxxx)
  final int? serial;

  String get displayName => '${rarity.label} ${type.label}';

  String get serialLabel =>
      '#${(serial ?? id.hashCode.abs() % 1000000000).toString()}';

  /// 属性の基礎値(個体保存値。ジェム補正は含まない)。
  double baseAttr(ShoeAttr attr) => attrs[attr] ?? 0;

  /// ジェム補正込みの属性値。equippedGems はこのシューズに装着中のジェム。
  double totalAttr(ShoeAttr attr, List<Gem> equippedGems) {
    final base = baseAttr(attr);
    var flat = 0.0;
    var percent = 0.0;
    for (final gem in equippedGems) {
      if (gem.type == attr.gemType) {
        flat += gem.flatBonus;
        percent += gem.percentBonus;
      }
    }
    return (base + flat) * (1 + percent / 100);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'rarity': rarity.name,
        'level': level,
        'durability': durability,
        'mintCount': mintCount,
        'serial': serial,
        'attrs': {for (final e in attrs.entries) e.key.name: e.value},
        'unspentPoints': unspentPoints,
      };

  factory Shoe.fromJson(Map<String, dynamic> json) {
    final rarity = Rarity.values.byName(json['rarity'] as String);
    final level = json['level'] as int? ?? 0;
    Map<ShoeAttr, double> attrs;
    final rawAttrs = json['attrs'] as Map<String, dynamic>?;
    if (rawAttrs != null) {
      attrs = {
        for (final a in ShoeAttr.values)
          a: (rawAttrs[a.name] as num?)?.toDouble() ?? 1.0,
      };
    } else {
      // 旧データ移行: レアリティ+レベルの旧式で近似再現。
      final base = GameConfig.rarityBaseAttr[rarity.index];
      attrs = {
        for (final a in ShoeAttr.values)
          a: base +
              level *
                  (a == ShoeAttr.efficiency
                      ? GameConfig.efficiencyPerLevel
                      : GameConfig.otherAttrPerLevel),
      };
    }
    return Shoe(
      id: json['id'] as String,
      type: ShoeType.values.byName(json['type'] as String),
      rarity: rarity,
      level: level,
      durability: (json['durability'] as num?)?.toDouble() ?? 100.0,
      mintCount: json['mintCount'] as int? ?? 0,
      serial: json['serial'] as int?,
      attrs: attrs,
      unspentPoints: json['unspentPoints'] as int? ?? 0,
    );
  }
}
