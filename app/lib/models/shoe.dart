import '../config/game_config.dart';

/// シューズタイプ(独自名称)。適正速度レンジは本家相当の4区分。
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

  /// ポイント獲得倍率(コモン=1.0、レアリティが1段上がるごとに+0.1×段数)
  double get earnMultiplier => 1.0 + index * GameConfig.rarityEarnStep;
}

class Shoe {
  Shoe({
    required this.id,
    required this.type,
    required this.rarity,
  });

  final String id;
  final ShoeType type;
  final Rarity rarity;

  String get displayName => '${rarity.label} ${type.label}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'rarity': rarity.name,
      };

  factory Shoe.fromJson(Map<String, dynamic> json) => Shoe(
        id: json['id'] as String,
        type: ShoeType.values.byName(json['type'] as String),
        rarity: Rarity.values.byName(json['rarity'] as String),
      );
}
