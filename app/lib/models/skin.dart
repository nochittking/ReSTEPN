import 'shoe.dart';

/// スキン: 靴に装着すると見た目をこの絵柄に変更できる独自アイテム。
/// ステータスやレアリティとは独立し、育てた強い靴に好きなデザインを載せられる。
/// 自由に付け外し・再利用できる(外すとインベントリに戻る)。
class Skin {
  Skin({
    required this.id,
    required this.name,
    required this.visualType,
    required this.paletteRarity,
    required this.seed,
    this.equippedShoeId,
  });

  final String id;
  final String name;

  /// 見た目のシルエット(靴タイプ)。
  final ShoeType visualType;

  /// 配色ファミリー(レアリティで決まる)。
  final Rarity paletteRarity;

  /// 柄のシード。
  final int seed;

  /// 装着先シューズID(未装着はnull)。
  String? equippedShoeId;

  String get idLabel => '#${(seed.abs() % 100000000)}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'visualType': visualType.name,
        'paletteRarity': paletteRarity.name,
        'seed': seed,
        'equippedShoeId': equippedShoeId,
      };

  factory Skin.fromJson(Map<String, dynamic> json) => Skin(
        id: json['id'] as String,
        name: json['name'] as String,
        visualType: ShoeType.values.byName(json['visualType'] as String),
        paletteRarity: Rarity.values.byName(json['paletteRarity'] as String),
        seed: json['seed'] as int,
        equippedShoeId: json['equippedShoeId'] as String?,
      );
}

/// 初回配布のスターター・スキン。
List<Skin> starterSkins() => [
      Skin(
        id: 'skin-neon',
        name: 'ネオン・パルス',
        visualType: ShoeType.runner,
        paletteRarity: Rarity.epic,
        seed: 71053,
      ),
      Skin(
        id: 'skin-earth',
        name: 'アース・トレイル',
        visualType: ShoeType.walker,
        paletteRarity: Rarity.uncommon,
        seed: 24418,
      ),
      Skin(
        id: 'skin-aurora',
        name: 'オーロラ',
        visualType: ShoeType.allRounder,
        paletteRarity: Rarity.legendary,
        seed: 90233,
      ),
      Skin(
        id: 'skin-royal',
        name: 'ロイヤル・ブルー',
        visualType: ShoeType.jogger,
        paletteRarity: Rarity.rare,
        seed: 55810,
      ),
    ];
