import 'dart:math';

import '../config/game_config.dart';
import 'shoe.dart';

/// 保有シューズ一覧と、そこから導出されるエナジー上限。
///
/// エナジー上限 = 保有数による基礎エナジー + レアリティボーナス合算。
/// ただしどれだけ保有していても [GameConfig.energyHardCap](20.0)で頭打ち。
class ShoeInventory {
  ShoeInventory([List<Shoe>? shoes]) : shoes = shoes ?? [];

  final List<Shoe> shoes;

  bool get isEmpty => shoes.isEmpty;

  /// 保有数による基礎エナジー(閾値未満は直下の段を適用。0足は0)
  double get baseEnergy {
    var base = 0.0;
    for (final (count, energy) in GameConfig.energyCountTiers) {
      if (shoes.length >= count) base = energy;
    }
    return base;
  }

  /// レアリティボーナスの合算(1足ごとに加算)
  double get rarityBonus =>
      shoes.fold(0.0, (sum, shoe) => sum + shoe.rarity.energyBonus);

  /// エナジー上限(20.0ハードキャップ適用後)
  double get energyCap => min(baseEnergy + rarityBonus, GameConfig.energyHardCap);

  Shoe? byId(String? id) {
    if (id == null) return null;
    for (final shoe in shoes) {
      if (shoe.id == id) return shoe;
    }
    return null;
  }

  List<Map<String, dynamic>> toJson() => shoes.map((s) => s.toJson()).toList();

  factory ShoeInventory.fromJson(List<dynamic> json) => ShoeInventory(
        json
            .map((e) => Shoe.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
