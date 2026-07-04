import 'dart:math';

import '../config/game_config.dart';
import '../models/shoe.dart';

/// ミント・フュージョン・売却のロジック。RNGは注入可能(テスト用)。
class MintService {
  MintService({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  int _seq = 0;

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  int _newSerial() => 10000000 + _rng.nextInt(899999999);

  // ---- ミント ----

  /// ミント可能か(1足単位の条件)。
  bool canMint(Shoe shoe) =>
      shoe.level >= GameConfig.mintMinLevel &&
      shoe.mintCount < GameConfig.mintMaxCount;

  /// ミント不可の理由(可能ならnull)。
  String? mintBlockReason(Shoe shoe) {
    if (shoe.level < GameConfig.mintMinLevel) {
      return 'Lv${GameConfig.mintMinLevel}以上が必要です';
    }
    if (shoe.mintCount >= GameConfig.mintMaxCount) {
      return 'ミント上限(${GameConfig.mintMaxCount}回)です';
    }
    return null;
  }

  /// ミント費用。両親それぞれ 基礎×(ミント済み回数+1) の合算。
  ({double sp, double gp}) mintCost(Shoe parent, Shoe partner) {
    double spOf(Shoe s) =>
        GameConfig.mintBaseSp[s.rarity.index] * (s.mintCount + 1);
    double gpOf(Shoe s) =>
        GameConfig.mintBaseGp[s.rarity.index] * (s.mintCount + 1);
    return (
      sp: spOf(parent) + spOf(partner),
      gp: gpOf(parent) + gpOf(partner),
    );
  }

  /// ミント実行。新しい靴を返す(両親のmintCountはここで+1する)。
  /// タイプは両親から50/50、レアリティは低い方を基準に、
  /// 両親が同レアリティなら10%で1段上。
  Shoe performMint(Shoe parent, Shoe partner) {
    assert(canMint(parent) && canMint(partner));
    assert(parent.id != partner.id);

    final type = _rng.nextBool() ? parent.type : partner.type;
    var rarity = parent.rarity.index <= partner.rarity.index
        ? parent.rarity
        : partner.rarity;
    if (parent.rarity == partner.rarity &&
        rarity != Rarity.legendary &&
        _rng.nextDouble() < GameConfig.mintRarityUpChance) {
      rarity = Rarity.values[rarity.index + 1];
    }

    parent.mintCount += 1;
    partner.mintCount += 1;

    return Shoe(
      id: _newId('shoe-mint'),
      type: type,
      rarity: rarity,
      serial: _newSerial(),
    );
  }

  // ---- フュージョン ----

  /// 素材の検証。問題なければnull、あれば理由を返す。
  String? enhanceBlockReason(List<Shoe> materials) {
    if (materials.length != GameConfig.enhanceMaterialCount) {
      return '同レアリティの靴が${GameConfig.enhanceMaterialCount}足必要です';
    }
    final rarity = materials.first.rarity;
    if (materials.any((s) => s.rarity != rarity)) {
      return 'レアリティが揃っていません';
    }
    if (rarity == Rarity.legendary) {
      return 'レジェンダリーはフュージョンできません';
    }
    return null;
  }

  ({double sp, double gp}) enhanceCost(Rarity rarity) => (
        sp: GameConfig.enhanceCostSp[rarity.index],
        gp: GameConfig.enhanceCostGp[rarity.index],
      );

  double enhanceSuccessRate(Rarity rarity) =>
      GameConfig.enhanceSuccessRate[rarity.index];

  /// フュージョン実行。素材5足は呼び出し側で削除する。
  /// 成功なら1段上、失敗でも同レアリティの新しい靴が必ず返る。
  ({Shoe shoe, bool success}) performEnhance(List<Shoe> materials) {
    assert(enhanceBlockReason(materials) == null);
    final rarity = materials.first.rarity;
    final success = _rng.nextDouble() < enhanceSuccessRate(rarity);
    final resultRarity =
        success ? Rarity.values[rarity.index + 1] : rarity;
    final type = materials[_rng.nextInt(materials.length)].type;
    return (
      shoe: Shoe(
        id: _newId('shoe-fusion'),
        type: type,
        rarity: resultRarity,
        serial: _newSerial(),
      ),
      success: success,
    );
  }

  // ---- 売却 ----

  double sellPrice(Shoe shoe) =>
      GameConfig.shopRarityPrice[shoe.rarity.index] *
          GameConfig.sellPriceFactor +
      shoe.level * GameConfig.sellPricePerLevel;
}
