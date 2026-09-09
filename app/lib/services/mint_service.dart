import 'dart:math';

import '../config/game_config.dart';
import '../models/shoe.dart';

/// ミント・エンハンス・フュージョン・売却のロジック。RNGは注入可能(テスト用)。
class MintService {
  MintService({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  int _seq = 0;

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  int _newSerial() => 10000000 + _rng.nextInt(899999999);

  double _round1(double v) => (v * 10).round() / 10;

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

  /// その親の消滅確率(何回目のミントか=mintCount+1 で参照。7回目=100%)。
  double vanishChance(Shoe parent) {
    final table = GameConfig.mintVanishByOccasion;
    final i = parent.mintCount.clamp(0, table.length - 1);
    return table[i];
  }

  /// 双子(子2足)確率 = 両親の合計ミント回数 × 4%(上限48%)。
  double twinChance(Shoe parent, Shoe partner) {
    final v = GameConfig.mintTwinStep * (parent.mintCount + partner.mintCount);
    return v > GameConfig.mintTwinCap ? GameConfig.mintTwinCap : v;
  }

  /// ミント実行。子1〜2足(双子)と、消滅した親を返す。
  /// タイプは両親から50/50、レアリティは低い方を基準に、
  /// 両親が同レアリティなら10%で1段上。子の属性はレアリティ帯からランダム。
  ({List<Shoe> children, List<Shoe> vanished}) performMint(
      Shoe parent, Shoe partner) {
    assert(canMint(parent) && canMint(partner));
    assert(parent.id != partner.id);

    // 消滅・双子は「増やす前」のミント回数で判定する。
    final vanishP = _rng.nextDouble() < vanishChance(parent);
    final vanishPartner = _rng.nextDouble() < vanishChance(partner);
    final twin = _rng.nextDouble() < twinChance(parent, partner);

    Shoe makeChild() {
      final type = _rng.nextBool() ? parent.type : partner.type;
      var rarity = parent.rarity.index <= partner.rarity.index
          ? parent.rarity
          : partner.rarity;
      if (parent.rarity == partner.rarity &&
          rarity != Rarity.legendary &&
          _rng.nextDouble() < GameConfig.mintRarityUpChance) {
        rarity = Rarity.values[rarity.index + 1];
      }
      return Shoe(
        id: _newId('shoe-mint'),
        type: type,
        rarity: rarity,
        serial: _newSerial(),
        attrs: rollAttrs(rarity, _rng),
      );
    }

    final children = [makeChild(), if (twin) makeChild()];

    parent.mintCount += 1;
    partner.mintCount += 1;

    final vanished = [
      if (vanishP) parent,
      if (vanishPartner) partner,
    ];

    return (children: children, vanished: vanished);
  }

  // ---- エンハンス(同レア5足 → 確定で上位レアリティへ進化) ----

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
      return 'レジェンダリーはエンハンスできません';
    }
    return null;
  }

  ({double sp, double gp}) enhanceCost(Rarity rarity) => (
        sp: GameConfig.enhanceCostSp[rarity.index],
        gp: GameConfig.enhanceCostGp[rarity.index],
      );

  /// 大成功(2段階アップ)の確率。通常成功(1段アップ)はこの残り。
  /// エピック素材はレジェンダリーの先が無く2段階アップが起こり得ないため0。
  double enhanceGreatChance(Rarity rarity) =>
      rarity.index + 2 <= Rarity.legendary.index
          ? GameConfig.enhanceGreatChance
          : 0.0;

  /// エンハンス実行。素材5足は呼び出し側で削除する。
  /// 失敗は無く、必ず1段上(大成功なら2段階上)の靴が返る。属性はランダム。
  ({Shoe shoe, bool great, int steps}) performEnhance(List<Shoe> materials) {
    assert(enhanceBlockReason(materials) == null);
    final rarity = materials.first.rarity;
    // 失敗は無い。必ず1段アップし、大成功なら2段階アップする。
    final great = _rng.nextDouble() < enhanceGreatChance(rarity);
    final steps = great ? 2 : 1;
    final resultRarity = Rarity.values[rarity.index + steps];
    final type = materials[_rng.nextInt(materials.length)].type;
    return (
      shoe: Shoe(
        id: _newId('shoe-enhance'),
        type: type,
        rarity: resultRarity,
        serial: _newSerial(),
        attrs: rollAttrs(resultRarity, _rng),
      ),
      great: great,
      steps: steps,
    );
  }

  // ---- フュージョン(ベース+生贄1足で属性を底上げ) ----

  /// 生贄はレアリティ不問(ベースより上位の靴も使える)。
  String? fusionBlockReason(Shoe base, Shoe? sacrifice) {
    if (sacrifice == null) return '生贄の靴を選択してください';
    if (sacrifice.id == base.id) return 'ベースと別の靴を選んでください';
    return null;
  }

  double fusionCost(Rarity rarity) => GameConfig.fusionCostSp[rarity.index];

  /// 底上げの上限値。ベース靴のレアリティ帯の上限を超えることは決して無い。
  /// (例: ベースがレアなら、生贄がエピックでもレア帯の上限で頭打ち)
  double fusionAttrCap(Rarity baseRarity) =>
      GameConfig.mintAttrRange[baseRarity.index].$2;

  /// この生贄で到達しうる属性値。生贄値をベースのレアリティ上限で頭打ちにする。
  double _fusionTarget(Shoe base, Shoe sacrifice, ShoeAttr a) =>
      min(sacrifice.baseAttr(a), fusionAttrCap(base.rarity));

  /// 属性ごとのプレビュー: current と、到達しうる上限 max(上がらないならnull)。
  Map<ShoeAttr, ({double current, double? max})> fusionPreview(
      Shoe base, Shoe sacrifice) {
    final preview = <ShoeAttr, ({double current, double? max})>{};
    for (final a in ShoeAttr.values) {
      final cur = base.baseAttr(a);
      final target = _fusionTarget(base, sacrifice, a);
      preview[a] = (current: cur, max: target > cur ? target : null);
    }
    return preview;
  }

  /// フュージョン実行。生贄が上回る属性を「現在値〜到達上限」の範囲でランダム底上げ。
  /// 到達上限はベースのレアリティ帯の上限で頭打ちになるため、上位レアリティの
  /// 生贄を使ってもベースの帯を超えて伸びることは無い。
  /// ベース靴を直接更新する。生贄の消費は呼び出し側で行う。
  /// 実際に上がった属性→上げ幅を返す。
  Map<ShoeAttr, double> performFusion(Shoe base, Shoe sacrifice) {
    assert(fusionBlockReason(base, sacrifice) == null);
    final gains = <ShoeAttr, double>{};
    for (final a in ShoeAttr.values) {
      final cur = base.baseAttr(a);
      final target = _fusionTarget(base, sacrifice, a);
      if (target > cur) {
        final boosted = _round1(cur + _rng.nextDouble() * (target - cur));
        if (boosted > cur) {
          gains[a] = _round1(boosted - cur);
          base.attrs[a] = boosted;
        }
      }
    }
    return gains;
  }

  // ---- 売却 ----

  /// 売却価格 = ショップ基準×0.4 + Lv×5 + 属性合計×1.0。
  /// 振り分け・フュージョンで育てた靴ほど高く売れる。
  double sellPrice(Shoe shoe) {
    final attrTotal =
        ShoeAttr.values.fold(0.0, (sum, a) => sum + shoe.baseAttr(a));
    return GameConfig.shopRarityPrice[shoe.rarity.index] *
            GameConfig.sellPriceFactor +
        shoe.level * GameConfig.sellPricePerLevel +
        attrTotal * GameConfig.sellPricePerAttr;
  }
}
