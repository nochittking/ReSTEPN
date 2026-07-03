import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/config/game_config.dart';
import 'package:restep_mvp/models/shoe.dart';
import 'package:restep_mvp/services/shop_service.dart';
import 'package:restep_mvp/state/app_state.dart';

void main() {
  group('レベルアップ', () {
    test('費用はLv0→1で10SP、Lv5→6で60SP', () {
      expect(GameConfig.levelUpCost(0), 10.0);
      expect(GameConfig.levelUpCost(5), 60.0);
    });

    test('レベルで効率が+1.0/Lv成長する', () {
      final shoe = Shoe(id: 's', type: ShoeType.walker, rarity: Rarity.common);
      final before = shoe.baseAttr(ShoeAttr.efficiency);
      shoe.level = 10;
      expect(shoe.baseAttr(ShoeAttr.efficiency), closeTo(before + 10.0, 1e-9));
      // 他属性は+0.3/Lv
      expect(shoe.baseAttr(ShoeAttr.luck),
          closeTo(Rarity.common.baseAttr + 3.0, 1e-9));
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
