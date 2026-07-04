import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/models/shoe.dart';
import 'package:restep_mvp/services/mint_service.dart';

/// 常に同じ値を返す擬似RNG。
class _FixedRandom implements Random {
  _FixedRandom(this.value, {this.boolValue = true});

  final double value;
  final bool boolValue;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => boolValue;
}

Shoe _shoe({
  String id = 's1',
  ShoeType type = ShoeType.walker,
  Rarity rarity = Rarity.common,
  int level = 5,
  int mintCount = 0,
}) =>
    Shoe(id: id, type: type, rarity: rarity, level: level)
      ..mintCount = mintCount;

void main() {
  group('ミント条件', () {
    test('Lv5未満はミント不可', () {
      final service = MintService();
      expect(service.canMint(_shoe(level: 4)), isFalse);
      expect(service.mintBlockReason(_shoe(level: 4)), contains('Lv5'));
      expect(service.canMint(_shoe(level: 5)), isTrue);
    });

    test('ミント7回済みは不可', () {
      final service = MintService();
      expect(service.canMint(_shoe(mintCount: 7)), isFalse);
      expect(service.mintBlockReason(_shoe(mintCount: 7)), contains('上限'));
    });
  });

  group('ミント費用(基礎×(ミント済み+1)の両親合算)', () {
    test('コモン0回×コモン0回 = 50+10 ×2', () {
      final service = MintService();
      final cost = service.mintCost(_shoe(), _shoe(id: 's2'));
      expect(cost.sp, 100.0);
      expect(cost.gp, 20.0);
    });

    test('ミント済み回数で費用が増える(コモン2回目=×2)', () {
      final service = MintService();
      final cost =
          service.mintCost(_shoe(mintCount: 1), _shoe(id: 's2'));
      expect(cost.sp, 50.0 * 2 + 50.0);
      expect(cost.gp, 10.0 * 2 + 10.0);
    });

    test('レアリティで基礎額が上がる(レア=200/40)', () {
      final service = MintService();
      final cost = service.mintCost(
          _shoe(rarity: Rarity.rare), _shoe(id: 's2'));
      expect(cost.sp, 200.0 + 50.0);
      expect(cost.gp, 40.0 + 10.0);
    });
  });

  group('ミント実行', () {
    test('両親のミント回数が+1され、新しい靴はLv0・ミント0', () {
      final service = MintService(rng: _FixedRandom(0.99));
      final parent = _shoe();
      final partner = _shoe(id: 's2', type: ShoeType.jogger);
      final child = service.performMint(parent, partner);
      expect(parent.mintCount, 1);
      expect(partner.mintCount, 1);
      expect(child.level, 0);
      expect(child.mintCount, 0);
      expect(child.durability, 100.0);
      expect(child.rarity, Rarity.common);
    });

    test('タイプは両親のどちらかを継承', () {
      final service = MintService(rng: _FixedRandom(0.99, boolValue: false));
      final child = service.performMint(
          _shoe(), _shoe(id: 's2', type: ShoeType.jogger));
      expect(child.type, ShoeType.jogger); // nextBool=false → partner側
    });

    test('同レアリティの両親は10%で1段上が生まれる', () {
      final lucky = MintService(rng: _FixedRandom(0.05));
      final child =
          lucky.performMint(_shoe(), _shoe(id: 's2'));
      expect(child.rarity, Rarity.uncommon);
    });

    test('異なるレアリティなら低い方に揃う', () {
      final service = MintService(rng: _FixedRandom(0.05));
      final child = service.performMint(
          _shoe(rarity: Rarity.epic), _shoe(id: 's2'));
      expect(child.rarity, Rarity.common);
    });
  });

  group('フュージョン', () {
    List<Shoe> materials([Rarity rarity = Rarity.common]) => List.generate(
        5, (i) => _shoe(id: 'm$i', rarity: rarity, level: 0));

    test('5足未満・レアリティ不揃い・レジェンダリーは不可', () {
      final service = MintService();
      expect(service.enhanceBlockReason(materials().sublist(0, 4)),
          isNotNull);
      final mixed = materials()..[0] = _shoe(id: 'm0', rarity: Rarity.rare);
      expect(service.enhanceBlockReason(mixed), isNotNull);
      expect(service.enhanceBlockReason(materials(Rarity.legendary)),
          isNotNull);
      expect(service.enhanceBlockReason(materials()), isNull);
    });

    test('費用は参考UI準拠(コモン=360/40、アンコモン=1360/240)', () {
      final service = MintService();
      expect(service.enhanceCost(Rarity.common), (sp: 360.0, gp: 40.0));
      expect(
          service.enhanceCost(Rarity.uncommon), (sp: 1360.0, gp: 240.0));
    });

    test('成功で1段上、失敗でも同レアリティの靴が生まれる', () {
      final success = MintService(rng: _FixedRandom(0.0));
      final win = success.performEnhance(materials());
      expect(win.success, isTrue);
      expect(win.shoe.rarity, Rarity.uncommon);

      final fail = MintService(rng: _FixedRandom(0.99));
      final lose = fail.performEnhance(materials());
      expect(lose.success, isFalse);
      expect(lose.shoe.rarity, Rarity.common);
    });
  });

  group('売却価格', () {
    test('ショップ基準×0.4 + Lv×5', () {
      final service = MintService();
      // コモン基準50 → 20.0 + Lv5×5 = 45.0
      expect(service.sellPrice(_shoe(level: 5)), closeTo(45.0, 1e-9));
      // レア基準400 → 160.0
      expect(service.sellPrice(_shoe(rarity: Rarity.rare, level: 0)),
          closeTo(160.0, 1e-9));
    });
  });
}
