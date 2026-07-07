import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/config/game_config.dart';
import 'package:restep_mvp/models/shoe.dart';
import 'package:restep_mvp/services/mint_service.dart';

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
    test('両親のミント回数が+1され、子はLv0・ミント0・属性付き', () {
      final service = MintService(rng: _FixedRandom(0.99));
      final parent = _shoe();
      final partner = _shoe(id: 's2', type: ShoeType.jogger);
      final r = service.performMint(parent, partner);
      final child = r.children.first;
      expect(parent.mintCount, 1);
      expect(partner.mintCount, 1);
      expect(child.level, 0);
      expect(child.mintCount, 0);
      expect(child.durability, 100.0);
      expect(child.rarity, Rarity.common);
      // 属性はコモン帯(1〜10)でロールされている
      final range = GameConfig.mintAttrRange[Rarity.common.index];
      for (final a in ShoeAttr.values) {
        expect(child.baseAttr(a), greaterThanOrEqualTo(range.$1));
        expect(child.baseAttr(a), lessThanOrEqualTo(range.$2));
      }
    });

    test('同レアリティの両親は10%で1段上が生まれる', () {
      final lucky = MintService(rng: _FixedRandom(0.05));
      final child = lucky.performMint(_shoe(), _shoe(id: 's2')).children.first;
      expect(child.rarity, Rarity.uncommon);
    });

    test('異なるレアリティなら低い方に揃う', () {
      final service = MintService(rng: _FixedRandom(0.05));
      final child = service
          .performMint(_shoe(rarity: Rarity.epic), _shoe(id: 's2'))
          .children
          .first;
      expect(child.rarity, Rarity.common);
    });
  });

  group('ミント消滅・双子', () {
    test('消滅率テーブル(何回目のミントかで参照、7回目=100%)', () {
      final service = MintService();
      expect(service.vanishChance(_shoe(mintCount: 0)), 0.0); // 1回目
      expect(service.vanishChance(_shoe(mintCount: 1)), 0.05); // 2回目
      expect(service.vanishChance(_shoe(mintCount: 5)), 0.15); // 6回目
      expect(service.vanishChance(_shoe(mintCount: 6)), 1.0); // 7回目
    });

    test('双子率 = 合計ミント回数×4%(上限48%)', () {
      final service = MintService();
      expect(service.twinChance(_shoe(mintCount: 0), _shoe(id: 's2')), 0.0);
      expect(
          service.twinChance(
              _shoe(mintCount: 2), _shoe(id: 's2', mintCount: 2)),
          closeTo(0.16, 1e-9));
      expect(
          service.twinChance(
              _shoe(mintCount: 6), _shoe(id: 's2', mintCount: 6)),
          0.48); // 上限
    });

    test('7回目の親は必ず消滅する', () {
      final service = MintService(rng: _FixedRandom(0.99));
      final worn = _shoe(mintCount: 6); // 次が7回目
      final fresh = _shoe(id: 's2', mintCount: 0);
      final r = service.performMint(worn, fresh);
      expect(r.vanished.map((v) => v.id), contains('s1'));
      expect(r.vanished.map((v) => v.id), isNot(contains('s2')));
    });

    test('双子は子2足になる', () {
      // mintCount5+5=双子率0.4、消滅率0.15。rng0.2で消滅なし・双子あり
      final service = MintService(rng: _FixedRandom(0.2));
      final r = service.performMint(
          _shoe(mintCount: 5), _shoe(id: 's2', mintCount: 5));
      expect(r.children.length, 2);
      expect(r.vanished, isEmpty);
    });
  });

  group('エンハンス(同レア5足→上位)', () {
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

  group('フュージョン(ベース+生贄で属性底上げ)', () {
    Shoe withAttrs(String id, Map<ShoeAttr, double> a,
            {Rarity rarity = Rarity.rare}) =>
        Shoe(id: id, type: ShoeType.walker, rarity: rarity, attrs: {
          for (final at in ShoeAttr.values) at: a[at] ?? 1.0,
        });

    test('条件: 生贄null・別レアリティ・同一靴は不可', () {
      final service = MintService();
      final base = withAttrs('b', {});
      expect(service.fusionBlockReason(base, null), isNotNull);
      expect(service.fusionBlockReason(base, base), isNotNull);
      expect(
          service.fusionBlockReason(
              base, withAttrs('s', {}, rarity: Rarity.epic)),
          isNotNull);
      expect(
          service.fusionBlockReason(base, withAttrs('s', {})), isNull);
    });

    test('生贄が上回る属性だけ範囲内で底上げ(rng最大値→生贄値まで)', () {
      final service = MintService(rng: _FixedRandom(1.0));
      final base = withAttrs('b', {
        ShoeAttr.efficiency: 10.5,
        ShoeAttr.luck: 12.0,
        ShoeAttr.comfort: 16.0,
        ShoeAttr.resilience: 10.5,
      });
      final sacrifice = withAttrs('s', {
        ShoeAttr.efficiency: 21.1,
        ShoeAttr.luck: 12.0, // 同値=底上げなし
        ShoeAttr.comfort: 18.8,
        ShoeAttr.resilience: 10.0, // 下回る=底上げなし
      });
      final gains = service.performFusion(base, sacrifice);
      expect(base.baseAttr(ShoeAttr.efficiency), closeTo(21.1, 1e-9));
      expect(base.baseAttr(ShoeAttr.comfort), closeTo(18.8, 1e-9));
      expect(base.baseAttr(ShoeAttr.luck), 12.0); // 変化なし
      expect(base.baseAttr(ShoeAttr.resilience), 10.5); // 変化なし
      expect(gains.keys, containsAll([ShoeAttr.efficiency, ShoeAttr.comfort]));
      expect(gains.containsKey(ShoeAttr.luck), isFalse);
    });

    test('プレビューは上回る属性にのみ上限を返す', () {
      final service = MintService();
      final base = withAttrs('b', {ShoeAttr.efficiency: 10.0});
      final sac = withAttrs('s', {ShoeAttr.efficiency: 20.0});
      final preview = service.fusionPreview(base, sac);
      expect(preview[ShoeAttr.efficiency]!.max, 20.0);
      expect(preview[ShoeAttr.luck]!.max, isNull); // 両方1.0で同値
    });
  });

  group('売却価格', () {
    test('ショップ基準×0.4 + Lv×5 + 属性合計×1.0', () {
      final service = MintService();
      // コモン基準50 → 20.0 + Lv5×5 + 属性(1.0×4) = 49.0
      expect(service.sellPrice(_shoe(level: 5)), closeTo(49.0, 1e-9));
      // レア基準400 → 160.0 + 属性4.0 = 164.0
      expect(service.sellPrice(_shoe(rarity: Rarity.rare, level: 0)),
          closeTo(164.0, 1e-9));
    });

    test('育てた靴(属性が高い)ほど高く売れる', () {
      final service = MintService();
      final grown = Shoe(
        id: 'g',
        type: ShoeType.walker,
        rarity: Rarity.common,
        level: 5,
        attrs: {for (final a in ShoeAttr.values) a: 25.0},
      );
      // 20.0 + 25 + 100 = 145.0
      expect(service.sellPrice(grown), closeTo(145.0, 1e-9));
    });
  });
}
