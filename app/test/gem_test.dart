import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/models/gem.dart';
import 'package:restep_mvp/models/shoe.dart';
import 'package:restep_mvp/services/gem_service.dart';

/// 常に同じ値を返す擬似RNG(成功/失敗を確定させる)。
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

List<Gem> _materials(GemType type, int level) => List.generate(
    3, (i) => Gem(id: 'm$i', type: type, level: level));

void main() {
  group('ジェムの効果', () {
    test('固定値ボーナス: Lv1=+2 / Lv2=+8 / Lv3=+25', () {
      expect(Gem(id: 'a', type: GemType.efficiency, level: 1).flatBonus, 2);
      expect(Gem(id: 'b', type: GemType.efficiency, level: 2).flatBonus, 8);
      expect(Gem(id: 'c', type: GemType.efficiency, level: 3).flatBonus, 25);
    });

    test('装着で属性値が(基礎+固定)×(1+割合)になる', () {
      final shoe = Shoe(id: 's', type: ShoeType.walker, rarity: Rarity.rare);
      // レアの基礎 = 18.0
      final gem = Gem(id: 'g', type: GemType.efficiency, level: 2);
      // (18+8) × 1.10 = 28.6
      expect(shoe.totalAttr(ShoeAttr.efficiency, [gem]),
          closeTo(28.6, 1e-9));
      // 別属性には影響しない
      expect(shoe.totalAttr(ShoeAttr.luck, [gem]), closeTo(18.0, 1e-9));
    });
  });

  group('ジェム強化(3個合成)', () {
    test('成功するとLv+1のジェムが1個できる', () {
      final service = GemService(rng: _FixedRandom(0.0)); // 常に成功
      final result = service.upgrade(_materials(GemType.luck, 1));
      expect(result, isNotNull);
      expect(result!.level, 2);
      expect(result.type, GemType.luck);
    });

    test('失敗するとnull(素材は消失)', () {
      final service = GemService(rng: _FixedRandom(0.99)); // 常に失敗
      final result = service.upgrade(_materials(GemType.luck, 1));
      expect(result, isNull);
    });

    test('成功率はLv1→2が55%、Lv2→3が50%', () {
      final service = GemService();
      expect(service.successRate(1), 0.55);
      expect(service.successRate(2), 0.50);
    });

    test('種類・レベル不揃いはエラー', () {
      final service = GemService(rng: _FixedRandom(0.0));
      expect(
        () => service.upgrade([
          Gem(id: 'a', type: GemType.luck, level: 1),
          Gem(id: 'b', type: GemType.luck, level: 2),
          Gem(id: 'c', type: GemType.luck, level: 1),
        ]),
        throwsArgumentError,
      );
      expect(
        () => service.upgrade([
          Gem(id: 'a', type: GemType.luck, level: 1),
          Gem(id: 'b', type: GemType.comfort, level: 1),
          Gem(id: 'c', type: GemType.luck, level: 1),
        ]),
        throwsArgumentError,
      );
    });

    test('装着中のジェムは素材にできない', () {
      final service = GemService(rng: _FixedRandom(0.0));
      final materials = _materials(GemType.luck, 1);
      materials.first.equippedShoeId = 'shoe-1';
      expect(() => service.upgrade(materials), throwsArgumentError);
    });
  });

  group('ミステリーボックスのドロップ', () {
    test('10分未満のムーブでは判定回数0', () {
      final service = GemService(rng: _FixedRandom(0.0));
      expect(
          service.rollBoxDrops(movedSeconds: 599, luck: 0, freeSlots: 4), 0);
    });

    test('確率100%相当なら10分ごとに1個(空きスロット上限まで)', () {
      final service = GemService(rng: _FixedRandom(0.0)); // 必ず当選
      expect(
          service.rollBoxDrops(
              movedSeconds: 1800, luck: 100, freeSlots: 4),
          3);
      expect(
          service.rollBoxDrops(
              movedSeconds: 3600, luck: 100, freeSlots: 2),
          2); // スロット上限
    });

    test('当選しなければ0個', () {
      final service = GemService(rng: _FixedRandom(0.99));
      expect(
          service.rollBoxDrops(movedSeconds: 3600, luck: 0, freeSlots: 4),
          0);
    });
  });
}
