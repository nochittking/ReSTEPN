import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/config/game_config.dart';
import 'package:restep_mvp/models/gem.dart';
import 'package:restep_mvp/models/move_session.dart';
import 'package:restep_mvp/models/shoe.dart';
import 'package:restep_mvp/services/reward_engine.dart';
import 'package:restep_mvp/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 獲得式の再設計(E_eff÷10)・ジェムLv1〜9・ソケット倍率・
/// デイリー上限のGP解放をまとめて検証する。
void main() {
  Shoe shoeWith(Rarity rarity, double efficiency) => Shoe(
        id: 's',
        type: ShoeType.walker,
        rarity: rarity,
        attrs: {
          for (final a in ShoeAttr.values)
            a: a == ShoeAttr.efficiency ? efficiency : 1.0,
        },
      );

  group('獲得式 SP/分 = E_eff ÷ 10', () {
    test('効率100なら10SP/分、効率50なら5SP/分', () {
      for (final (eff, rate) in [(100.0, 10.0), (50.0, 5.0), (7.0, 0.7)]) {
        final engine = RewardEngine(
            shoe: shoeWith(Rarity.common, eff), mode: EarnMode.sp);
        expect(engine.pointsPerMinute, closeTo(rate, 1e-9));
      }
    });

    test('GPはSPの半分(÷20)', () {
      final shoe = shoeWith(Rarity.common, 100);
      expect(RewardEngine(shoe: shoe, mode: EarnMode.sp).pointsPerMinute,
          closeTo(10.0, 1e-9));
      expect(RewardEngine(shoe: shoe, mode: EarnMode.gp).pointsPerMinute,
          closeTo(5.0, 1e-9));
    });

    test('E_effは300で頭打ち。それ以上は30SP/分のまま', () {
      final capped = RewardEngine(
          shoe: shoeWith(Rarity.common, 300), mode: EarnMode.sp);
      final over = RewardEngine(
          shoe: shoeWith(Rarity.common, 1000), mode: EarnMode.sp);
      expect(capped.effectiveEfficiency, GameConfig.efficiencyCap);
      expect(over.effectiveEfficiency, GameConfig.efficiencyCap);
      expect(over.pointsPerMinute, closeTo(30.0, 1e-9));
      // 上限前の効率値そのものは素通しで見える
      expect(over.efficiency, closeTo(1000, 1e-9));
    });

    test('上限30SP/分 × 100分(20エナジー)= 3000SP/日', () {
      final engine = RewardEngine(
          shoe: shoeWith(Rarity.legendary, 500), mode: EarnMode.sp);
      // 20エナジー ÷ 0.2/分 = 100分
      final minutes = GameConfig.energyHardCap / GameConfig.energyPerMinute;
      expect(minutes, 100);
      expect(engine.pointsPerMinute * minutes,
          closeTo(GameConfig.dailySpCapUnlocked, 1e-9));
    });
  });

  group('ジェム Lv1〜9', () {
    test('最大レベルは9', () {
      expect(GameConfig.maxGemLevel, 9);
      expect(GameConfig.gemFlatBonus.length, 9);
      expect(GameConfig.gemPercentBonus.length, 9);
    });

    test('Lv9は固定100 / 割合40% / 強度140', () {
      final gem = Gem(id: 'g', type: GemType.efficiency, level: 9);
      expect(gem.flatBonus, 100);
      expect(gem.percentBonus, 40);
      expect(gem.intensity, 140);
    });

    test('強化成功率はLv8→9まで定義されている', () {
      // Lv1→2 から Lv8→9 の8段ぶん
      expect(GameConfig.gemUpgradeSuccessRate.length,
          GameConfig.maxGemLevel - 1);
    });
  });

  group('ソケット倍率(靴のレアリティ別)', () {
    test('コモン1.0 〜 レジェンダリー1.5', () {
      expect(GameConfig.socketMultiplier.first, 1.0);
      expect(GameConfig.socketMultiplier.last, 1.5);
      expect(GameConfig.socketMultiplier.length, Rarity.values.length);
    });

    test('同じジェムでも上位レアリティの靴のほうが効く', () {
      final gem = Gem(id: 'g', type: GemType.efficiency, level: 9);
      final common = shoeWith(Rarity.common, 50);
      final legendary = shoeWith(Rarity.legendary, 50);
      expect(legendary.totalAttr(ShoeAttr.efficiency, [gem]),
          greaterThan(common.totalAttr(ShoeAttr.efficiency, [gem])));
    });

    test('レジェンダリー靴×Lv9効率ジェムは上限300に到達する', () {
      // 効率134.4(レジェンダリーの絶対上限)の靴にLv9ジェム
      final shoe = shoeWith(Rarity.legendary, 134.4);
      final gem = Gem(id: 'g', type: GemType.efficiency, level: 9);
      final engine = RewardEngine(
          shoe: shoe, mode: EarnMode.sp, equippedGems: [gem]);
      // (134.4 + 100×1.5) × (1 + 40×1.5/100) = 284.4 × 1.6 = 455.04
      expect(engine.efficiency, closeTo(455.04, 1e-9));
      // 上限適用後は300 → 30SP/分
      expect(engine.effectiveEfficiency, GameConfig.efficiencyCap);
      expect(engine.pointsPerMinute, closeTo(30.0, 1e-9));
    });

    test('ジェム未装着ならソケット倍率は効かない(素の属性のまま)', () {
      expect(shoeWith(Rarity.legendary, 80).totalAttr(ShoeAttr.efficiency, []),
          closeTo(80, 1e-9));
    });
  });

  group('デイリーSP上限のGP解放', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('既定は1000。解放すると3000になる', () async {
      final state = AppState();
      await state.load();
      expect(state.dailyCapUnlocked, isFalse);
      expect(state.dailySpCap, GameConfig.dailySpCap);

      state.gpBalance = GameConfig.dailyCapUnlockGp;
      expect(await state.unlockDailyCap(), isTrue);
      expect(state.dailyCapUnlocked, isTrue);
      expect(state.dailySpCap, GameConfig.dailySpCapUnlocked);
      expect(state.gpBalance, 0);
    });

    test('GP不足なら解放できない', () async {
      final state = AppState();
      await state.load();
      state.gpBalance = GameConfig.dailyCapUnlockGp - 1;
      expect(await state.unlockDailyCap(), isFalse);
      expect(state.dailyCapUnlocked, isFalse);
      expect(state.gpBalance, GameConfig.dailyCapUnlockGp - 1);
    });

    test('二重解放でGPが二重に引かれない', () async {
      final state = AppState();
      await state.load();
      state.gpBalance = GameConfig.dailyCapUnlockGp * 2;
      expect(await state.unlockDailyCap(), isTrue);
      expect(await state.unlockDailyCap(), isFalse);
      expect(state.gpBalance, GameConfig.dailyCapUnlockGp);
    });

    test('解放は再起動後も保持される', () async {
      final first = AppState();
      await first.load();
      first.gpBalance = GameConfig.dailyCapUnlockGp;
      await first.unlockDailyCap();

      final reloaded = AppState();
      await reloaded.load();
      expect(reloaded.dailyCapUnlocked, isTrue);
      expect(reloaded.dailySpCap, GameConfig.dailySpCapUnlocked);
    });

    test('残り獲得可能量は解放状態の上限から引かれる', () async {
      final state = AppState();
      await state.load();
      state.dailyEarnedSp = 900;
      expect(state.dailyRemainingSp, closeTo(100, 1e-9));

      state.gpBalance = GameConfig.dailyCapUnlockGp;
      await state.unlockDailyCap();
      expect(state.dailyRemainingSp, closeTo(2100, 1e-9));
    });
  });
}
