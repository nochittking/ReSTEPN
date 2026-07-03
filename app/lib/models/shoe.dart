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

  /// 属性の基礎値
  double get baseAttr => GameConfig.rarityBaseAttr[index];
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

class Shoe {
  Shoe({
    required this.id,
    required this.type,
    required this.rarity,
    this.level = 0,
    this.durability = 100.0,
    this.mintCount = 0,
    this.serial,
  });

  final String id;
  final ShoeType type;
  final Rarity rarity;
  int level;
  double durability;
  int mintCount;

  /// 表示用のシリアル番号(#xxxxxxxx)
  final int? serial;

  String get displayName => '${rarity.label} ${type.label}';

  String get serialLabel =>
      '#${(serial ?? id.hashCode.abs() % 1000000000).toString()}';

  /// 属性の基礎値(レアリティ+レベル成長。ジェム補正は含まない)
  double baseAttr(ShoeAttr attr) {
    final growth = attr == ShoeAttr.efficiency
        ? GameConfig.efficiencyPerLevel
        : GameConfig.otherAttrPerLevel;
    return rarity.baseAttr + level * growth;
  }

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
      };

  factory Shoe.fromJson(Map<String, dynamic> json) => Shoe(
        id: json['id'] as String,
        type: ShoeType.values.byName(json['type'] as String),
        rarity: Rarity.values.byName(json['rarity'] as String),
        level: json['level'] as int? ?? 0,
        durability: (json['durability'] as num?)?.toDouble() ?? 100.0,
        mintCount: json['mintCount'] as int? ?? 0,
        serial: json['serial'] as int?,
      );
}
