import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/config/game_config.dart';
import 'package:restep_mvp/models/shoe.dart';
import 'package:restep_mvp/services/shop_service.dart';
import 'package:restep_mvp/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 常に同じ値を返す擬似RNG。
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => true;
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('レベルアップ', () {
    test('費用はLv0→1で10SP、Lv5→6で60SP(GPなし)', () {
      expect(GameConfig.levelUpCost(0), (sp: 10.0, gp: 0.0));
      expect(GameConfig.levelUpCost(5), (sp: 60.0, gp: 0.0));
    });

    test('節目レベル(到達Lv10/20/30)は費用3倍+GP併用', () {
      // Lv9→10: 100×3=300SP + 30GP
      expect(GameConfig.levelUpCost(9), (sp: 300.0, gp: 30.0));
      // Lv19→20: 200×3=600SP + 60GP
      expect(GameConfig.levelUpCost(19), (sp: 600.0, gp: 60.0));
      // 節目以外はGPなし
      expect(GameConfig.levelUpCost(10).gp, 0.0);
    });

    test('コモンは通常時4ポイント付与(属性は自動成長しない)', () async {
      final state = AppState(rng: _FixedRandom(0.5)); // クリティカルなし
      await state.load();
      final shoe = state.inventory.shoes.first; // コモン
      shoe.level = 5;
      final effBefore = shoe.baseAttr(ShoeAttr.efficiency);
      state.spBalance = 10000;
      final result = await state.levelUpShoe(shoe);
      expect(result, isNotNull);
      expect(result!.critTier, 0);
      expect(result.points, 4);
      expect(shoe.level, 6);
      expect(shoe.unspentPoints, 4);
      // 効率は自動では変わらない
      expect(shoe.baseAttr(ShoeAttr.efficiency), closeTo(effBefore, 1e-9));
    });

    test('基礎ポイントはレアリティ別(レジェンダリー=12)', () async {
      final state = AppState(rng: _FixedRandom(0.5));
      await state.load();
      final legend = Shoe(
          id: 'legend',
          type: ShoeType.runner,
          rarity: Rarity.legendary,
          level: 3);
      state.inventory.shoes.add(legend);
      state.spBalance = 10000;
      final result = await state.levelUpShoe(legend);
      expect(result!.points, 12);
    });

    test('クリティカル境界: r=0.04→3倍 / r=0.24→2倍 / r=0.30→等倍', () async {
      for (final (r, tier, points) in [
        (0.04, 2, 12), // 超大成功 ×3
        (0.24, 1, 8), // 大成功 ×2
        (0.30, 0, 4), // 通常
      ]) {
        SharedPreferences.setMockInitialValues({});
        final state = AppState(rng: _FixedRandom(r));
        await state.load();
        final shoe = state.inventory.shoes.first; // コモン(基礎4)
        shoe.level = 5;
        state.spBalance = 10000;
        final result = await state.levelUpShoe(shoe);
        expect(result!.critTier, tier, reason: 'r=$r');
        expect(result.points, points, reason: 'r=$r');
      }
    });

    test('節目Lv10到達はポイント2倍+GP消費、GP不足なら失敗', () async {
      final state = AppState(rng: _FixedRandom(0.5));
      await state.load();
      final shoe = state.inventory.shoes.first; // コモン
      shoe.level = 9;
      state.spBalance = 10000;

      // GP不足で失敗
      state.gpBalance = 0;
      expect(await state.levelUpShoe(shoe), isNull);
      expect(shoe.level, 9);

      // GPありで成功: 4×2=8pt、SP300+GP30消費
      state.gpBalance = 100;
      final result = await state.levelUpShoe(shoe);
      expect(result!.points, 8);
      expect(shoe.level, 10);
      expect(state.spBalance, closeTo(10000 - 300, 1e-9));
      expect(state.gpBalance, closeTo(70, 1e-9));
    });

    test('ポイント振り分けで対象属性が+1、残ポイントが減る', () async {
      final state = AppState();
      await state.load();
      final shoe = state.inventory.shoes.first;
      shoe.unspentPoints = 2;
      final before = shoe.baseAttr(ShoeAttr.luck);
      await state.allocatePoint(shoe, ShoeAttr.luck);
      expect(shoe.baseAttr(ShoeAttr.luck), closeTo(before + 1.0, 1e-9));
      expect(shoe.unspentPoints, 1);
    });

    test('残ポイント0では振り分け不可', () async {
      final state = AppState();
      await state.load();
      final shoe = state.inventory.shoes.first;
      shoe.unspentPoints = 0;
      final ok = await state.allocatePoint(shoe, ShoeAttr.luck);
      expect(ok, isFalse);
    });
  });

  group('属性ロール', () {
    test('レアリティ帯の範囲内でロールされる', () {
      final rng = Random(42);
      final attrs = rollAttrs(Rarity.rare, rng);
      final range = GameConfig.mintAttrRange[Rarity.rare.index];
      for (final a in ShoeAttr.values) {
        expect(attrs[a], greaterThanOrEqualTo(range.$1));
        expect(attrs[a], lessThanOrEqualTo(range.$2));
      }
    });
  });

  group('リペア費用', () {
    test('耐久1あたり0.2SP×レベル係数', () {
      expect(GameConfig.repairCostPerPoint(0), closeTo(0.2, 1e-9));
      expect(GameConfig.repairCostPerPoint(10), closeTo(0.4, 1e-9));
    });
  });

  group('デイリー日付キー(JST 4:00境界)', () {
    test('JST 3:59は前日扱い、4:00は当日扱い', () {
      // JST 2026-07-03 03:59 = UTC 2026-07-02 18:59
      final beforeReset = DateTime.utc(2026, 7, 2, 18, 59);
      // JST 2026-07-03 04:00 = UTC 2026-07-02 19:00
      final afterReset = DateTime.utc(2026, 7, 2, 19, 0);
      expect(AppState.dayKeyFor(beforeReset), '2026-7-2');
      expect(AppState.dayKeyFor(afterReset), '2026-7-3');
    });
  });

  group('ショップ', () {
    test('カタログは指定数生成され価格昇順に並ぶ', () {
      final catalog = ShopService().generateCatalog(size: 10);
      expect(catalog.length, 10);
      for (var i = 1; i < catalog.length; i++) {
        expect(catalog[i].priceSp,
            greaterThanOrEqualTo(catalog[i - 1].priceSp));
      }
    });

    test('元値はレアリティ基準額+属性分以上(セール品は元値で判定)', () {
      final listing = ShopService().generateListing();
      expect(
        listing.originalPriceSp,
        greaterThanOrEqualTo(
            GameConfig.shopRarityPrice[listing.shoe.rarity.index]),
      );
    });

    test('価格に属性合計×1.5が反映される', () {
      // r=0.5: コモン・Lv0・各属性5.5(合計22)・乱数0・セールなし
      final listing = ShopService(rng: _FixedRandom(0.5)).generateListing();
      expect(listing.onSale, isFalse);
      expect(listing.priceSp, closeTo(50 + 22.0 * 1.5, 1e-9));
    });

    test('8%未満のロールで半額セール品になる', () {
      // r=0.05: コモン・各属性1.5(合計6)→元値59、セールで29.5
      final listing = ShopService(rng: _FixedRandom(0.05)).generateListing();
      expect(listing.onSale, isTrue);
      expect(listing.priceSp, closeTo(29.5, 1e-9));
      expect(listing.originalPriceSp, closeTo(59.0, 1e-9));
    });

    test('セール状態はJSON往復で保たれる', () {
      final listing = ShopService(rng: _FixedRandom(0.05)).generateListing();
      final round = ShopListing.fromJson(
          Map<String, dynamic>.from(listing.toJson()));
      expect(round.onSale, isTrue);
      expect(round.priceSp, closeTo(listing.priceSp, 1e-9));
    });
  });
}
