import 'dart:math';

import '../config/game_config.dart';
import '../models/shoe.dart';

/// ショップの商品(シューズ+価格)。[onSale] は半額セール品(掘り出し物)。
class ShopListing {
  ShopListing({required this.shoe, required this.priceSp, this.onSale = false});

  final Shoe shoe;
  final double priceSp;
  final bool onSale;

  /// セール前の元値(通常品は priceSp と同じ)。
  double get originalPriceSp => onSale ? priceSp * 2 : priceSp;

  Map<String, dynamic> toJson() => {
        'shoe': shoe.toJson(),
        'priceSp': priceSp,
        'onSale': onSale,
      };

  factory ShopListing.fromJson(Map<String, dynamic> json) => ShopListing(
        shoe: Shoe.fromJson(Map<String, dynamic>.from(json['shoe'] as Map)),
        priceSp: (json['priceSp'] as num).toDouble(),
        onSale: json['onSale'] as bool? ?? false,
      );
}

/// マーケットプレイス風ショップ。カタログをランダム生成しSPで購入する。
/// RNGは注入可能(テスト用)。
class ShopService {
  ShopService({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  int _seq = 0;

  /// レアリティ抽選(コモン55% / アンコモン25% / レア12% / エピック6% / レジェンダリー2%)
  Rarity _rollRarity() {
    final roll = _rng.nextDouble();
    if (roll < 0.55) return Rarity.common;
    if (roll < 0.80) return Rarity.uncommon;
    if (roll < 0.92) return Rarity.rare;
    if (roll < 0.98) return Rarity.epic;
    return Rarity.legendary;
  }

  ShopListing generateListing() {
    final type = ShoeType.values[_rng.nextInt(ShoeType.values.length)];
    final rarity = _rollRarity();
    final level = _rng.nextInt(6); // 出品Lvは0〜5
    final shoe = Shoe(
      id: 'shoe-shop-${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
      type: type,
      rarity: rarity,
      level: level,
      serial: 10000000 + _rng.nextInt(89999999),
      attrs: rollAttrs(rarity, _rng),
    );
    // 属性ロールの良い個体ほど高い。まれに半額セール品(掘り出し物)が出る。
    final attrTotal =
        ShoeAttr.values.fold(0.0, (sum, a) => sum + shoe.baseAttr(a));
    var price = GameConfig.shopRarityPrice[rarity.index] +
        level * 10.0 +
        attrTotal * GameConfig.shopPricePerAttr +
        _rng.nextInt(30);
    final onSale = _rng.nextDouble() < GameConfig.shopSaleChance;
    if (onSale) price /= 2;
    return ShopListing(shoe: shoe, priceSp: price, onSale: onSale);
  }

  /// カタログを生成(価格昇順)。
  List<ShopListing> generateCatalog({int? size}) {
    final list = List.generate(
        size ?? GameConfig.shopCatalogSize, (_) => generateListing());
    list.sort((a, b) => a.priceSp.compareTo(b.priceSp));
    return list;
  }
}
