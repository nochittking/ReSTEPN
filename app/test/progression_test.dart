import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/config/game_config.dart';
import 'package:restep_mvp/models/shoe.dart';
import 'package:restep_mvp/services/shop_service.dart';
import 'package:restep_mvp/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('レベルアップ', () {
    test('費用はLv0→1で10SP、Lv5→6で60SP', () {
      expect(GameConfig.levelUpCost(0), 10.0);
      expect(GameConfig.levelUpCost(5), 60.0);
    });

    test('レベルアップは4ポイント付与(属性は自動成長しない)', () async {
      final state = AppState();
      await state.load();
      final shoe = state.inventory.shoes.first;
      shoe.level = 5; // ミント条件などとは無関係にLv設定
      final effBefore = shoe.baseAttr(ShoeAttr.efficiency);
      state.spBalance = 10000;
      final ok = await state.levelUpShoe(shoe);
      expect(ok, isTrue);
      expect(shoe.level, 6);
      expect(shoe.unspentPoints, GameConfig.pointsPerLevel);
      // 効率は自動では変わらない
      expect(shoe.baseAttr(ShoeAttr.efficiency), closeTo(effBefore, 1e-9));
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

    test('価格はレアリティの基準額以上', () {
      final listing = ShopService().generateListing();
      expect(
        listing.priceSp,
        greaterThanOrEqualTo(
            GameConfig.shopRarityPrice[listing.shoe.rarity.index]),
      );
    });
  });
}
