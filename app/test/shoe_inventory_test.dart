import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/models/shoe.dart';
import 'package:restep_mvp/models/shoe_inventory.dart';

Shoe _shoe(int i, [Rarity rarity = Rarity.common]) =>
    Shoe(id: 'shoe-$i', type: ShoeType.walker, rarity: rarity);

ShoeInventory _inventoryOf(int count, [Rarity rarity = Rarity.common]) =>
    ShoeInventory(List.generate(count, (i) => _shoe(i, rarity)));

void main() {
  group('保有数による基礎エナジー(閾値 1/3/9/15/30)', () {
    test('0足は0', () {
      expect(_inventoryOf(0).baseEnergy, 0.0);
    });

    test('1足=2.0 / 2足=2.0(次の閾値未満は直下の段)', () {
      expect(_inventoryOf(1).baseEnergy, 2.0);
      expect(_inventoryOf(2).baseEnergy, 2.0);
    });

    test('3足=4.0 / 8足=4.0', () {
      expect(_inventoryOf(3).baseEnergy, 4.0);
      expect(_inventoryOf(8).baseEnergy, 4.0);
    });

    test('9足=9.0 / 14足=9.0', () {
      expect(_inventoryOf(9).baseEnergy, 9.0);
      expect(_inventoryOf(14).baseEnergy, 9.0);
    });

    test('15足=12.0 / 29足=12.0', () {
      expect(_inventoryOf(15).baseEnergy, 12.0);
      expect(_inventoryOf(29).baseEnergy, 12.0);
    });

    test('30足=20.0', () {
      expect(_inventoryOf(30).baseEnergy, 20.0);
    });
  });

  group('レアリティボーナス(1足ごとに加算)', () {
    test('アンコモン+1 / レア+2 / エピック+3 / レジェンダリー+4', () {
      final inv = ShoeInventory([
        _shoe(1, Rarity.uncommon),
        _shoe(2, Rarity.rare),
        _shoe(3, Rarity.epic),
        _shoe(4, Rarity.legendary),
        _shoe(5, Rarity.common),
      ]);
      expect(inv.rarityBonus, 1.0 + 2.0 + 3.0 + 4.0);
      // 5足なので基礎は3足の段=4.0、合算 4+10=14.0
      expect(inv.energyCap, 14.0);
    });
  });

  group('デイリーエナジーキャップ20.0', () {
    test('基礎+ボーナスが20を超えても20.0でハードキャップ', () {
      // 30足(基礎20.0)+レジェンダリー30足(ボーナス+120)でも20.0
      final inv = _inventoryOf(30, Rarity.legendary);
      expect(inv.baseEnergy + inv.rarityBonus, greaterThan(20.0));
      expect(inv.energyCap, 20.0);
    });

    test('15足のレジェンダリー(基礎12+ボーナス60)でも20.0', () {
      expect(_inventoryOf(15, Rarity.legendary).energyCap, 20.0);
    });

    test('キャップ未満は合算値そのまま(3足のうち1足レア: 4+2=6.0)', () {
      final inv = ShoeInventory([
        _shoe(1, Rarity.rare),
        _shoe(2),
        _shoe(3),
      ]);
      expect(inv.energyCap, 6.0);
    });
  });
}
