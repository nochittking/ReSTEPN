import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/config/game_config.dart';
import 'package:restep_mvp/models/move_session.dart';
import 'package:restep_mvp/services/gem_service.dart';
import 'package:restep_mvp/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// nextDoubleを固定値で返すRNG(確率の境界を決め打ちするため)。
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
  group('復帰ボーナスの倍率(段の境界)', () {
    test('休止0〜2日はボーナスなし(前日に走った=休止1日も日常の範囲)', () {
      expect(GameConfig.comebackMultiplierFor(0), 1.0);
      expect(GameConfig.comebackMultiplierFor(1), 1.0);
      expect(GameConfig.comebackMultiplierFor(2), 1.0);
    });

    test('休止3〜6日は1.2倍', () {
      expect(GameConfig.comebackMultiplierFor(3), 1.2);
      expect(GameConfig.comebackMultiplierFor(6), 1.2);
    });

    test('休止7〜13日は1.5倍', () {
      expect(GameConfig.comebackMultiplierFor(7), 1.5);
      expect(GameConfig.comebackMultiplierFor(13), 1.5);
    });

    test('休止14日以上は2.0倍で頭打ち', () {
      expect(GameConfig.comebackMultiplierFor(14), 2.0);
      expect(GameConfig.comebackMultiplierFor(365), 2.0);
    });

    test('負の日数でも1.0を下回らない', () {
      expect(GameConfig.comebackMultiplierFor(-5), 1.0);
    });
  });

  group('確定枠', () {
    test('14日未満は確定枠なし', () {
      expect(GameConfig.comebackGuaranteedFor(13, 3600), 0);
    });

    test('14日以上かつ10分以上のムーブで1個', () {
      expect(GameConfig.comebackGuaranteedFor(14, 600), 1);
      expect(GameConfig.comebackGuaranteedFor(30, 3600), 1);
    });

    test('10分未満のムーブでは確定枠を受け取れない', () {
      expect(GameConfig.comebackGuaranteedFor(30, 599), 0);
    });
  });

  group('日の通し番号(JST4:00境界)', () {
    // JST 4:00 = UTC 前日 19:00
    test('JST 3:59 はまだ前日として数える', () {
      final justBefore = DateTime.utc(2026, 8, 14, 18, 59); // JST 8/15 3:59
      final justAfter = DateTime.utc(2026, 8, 14, 19, 0); // JST 8/15 4:00
      expect(AppState.dayIndexFor(justAfter) -
          AppState.dayIndexFor(justBefore), 1);
    });

    test('同じ日のうちは通し番号が変わらない', () {
      final morning = DateTime.utc(2026, 8, 14, 20); // JST 8/15 5:00
      final night = DateTime.utc(2026, 8, 15, 12); // JST 8/15 21:00
      expect(AppState.dayIndexFor(morning), AppState.dayIndexFor(night));
    });

    test('7日離れれば差は7', () {
      final a = DateTime.utc(2026, 8, 1, 12);
      final b = DateTime.utc(2026, 8, 8, 12);
      expect(AppState.dayIndexFor(b) - AppState.dayIndexFor(a), 7);
    });
  });

  group('ボックス抽選への反映', () {
    // 基礎5% + 幸運0 = 5%。r=0.055 は等倍だと外れ、1.2倍(6%)なら当たる。
    test('倍率1.0では外れる乱数が、1.2倍では当たる', () {
      final service = GemService(rng: _FixedRandom(0.055));
      expect(
        service.rollBoxDrops(movedSeconds: 600, luck: 0, freeSlots: 4),
        0,
      );
      expect(
        service.rollBoxDrops(
            movedSeconds: 600,
            luck: 0,
            freeSlots: 4,
            chanceMultiplier: 1.2),
        1,
      );
    });

    test('確定枠は抽選に関係なく先に入る', () {
      // r=0.99 なので抽選は全部外れる
      final service = GemService(rng: _FixedRandom(0.99));
      expect(
        service.rollBoxDrops(
            movedSeconds: 3600,
            luck: 0,
            freeSlots: 4,
            guaranteedDrops: 1),
        1,
      );
    });

    test('確定枠でも空きスロットは超えない', () {
      final service = GemService(rng: _FixedRandom(0.99));
      expect(
        service.rollBoxDrops(
            movedSeconds: 3600,
            luck: 0,
            freeSlots: 0,
            guaranteedDrops: 3),
        0,
      );
      expect(
        service.rollBoxDrops(
            movedSeconds: 3600,
            luck: 0,
            freeSlots: 1,
            guaranteedDrops: 3),
        1,
      );
    });

    test('倍率をかけても上限90%を超えない', () {
      // r=0.95 は 90% 上限でも外れる
      final service = GemService(rng: _FixedRandom(0.95));
      expect(
        service.rollBoxDrops(
            movedSeconds: 600,
            luck: 400,
            freeSlots: 4,
            chanceMultiplier: 2.0),
        0,
      );
    });

    test('倍率を渡さなければ従来と同じ挙動', () {
      // r=0.04 < 5% なので等倍でも当たる
      final service = GemService(rng: _FixedRandom(0.04));
      expect(
        service.rollBoxDrops(movedSeconds: 1800, luck: 0, freeSlots: 4),
        3,
      );
    });
  });

  group('MoveSession への記録', () {
    test('休止日数から倍率とフラグが導ける', () {
      final session = MoveSession(
        startedAt: DateTime(2026, 8, 14),
        endedAt: DateTime(2026, 8, 14),
        mode: EarnMode.sp,
        shoeName: 'テスト',
        distanceMeters: 1000,
        durationSeconds: 600,
        earnedPoints: 10,
        consumedEnergy: 2,
        rejectedSamples: 0,
        comebackGapDays: 7,
      );
      expect(session.comebackMultiplier, 1.5);
      expect(session.hasComebackBonus, isTrue);
    });

    test('休止0日ならボーナスなし', () {
      final session = MoveSession(
        startedAt: DateTime(2026, 8, 14),
        endedAt: DateTime(2026, 8, 14),
        mode: EarnMode.sp,
        shoeName: 'テスト',
        distanceMeters: 1000,
        durationSeconds: 600,
        earnedPoints: 10,
        consumedEnergy: 2,
        rejectedSamples: 0,
      );
      expect(session.hasComebackBonus, isFalse);
    });

    test('JSONで往復しても休止日数が保たれる', () {
      final session = MoveSession(
        startedAt: DateTime(2026, 8, 14),
        endedAt: DateTime(2026, 8, 14),
        mode: EarnMode.sp,
        shoeName: 'テスト',
        distanceMeters: 1000,
        durationSeconds: 600,
        earnedPoints: 10,
        consumedEnergy: 2,
        rejectedSamples: 0,
        comebackGapDays: 21,
      );
      final restored = MoveSession.fromJson(session.toJson());
      expect(restored.comebackGapDays, 21);
      expect(restored.comebackMultiplier, 2.0);
    });

    test('旧データ(comebackGapDaysなし)は0として読める', () {
      final json = {
        'startedAt': DateTime(2026, 8, 14).toIso8601String(),
        'endedAt': DateTime(2026, 8, 14).toIso8601String(),
        'mode': 'sp',
        'shoeName': 'テスト',
        'distanceMeters': 1000,
        'durationSeconds': 600,
        'earnedPoints': 10,
        'consumedEnergy': 2,
        'rejectedSamples': 0,
      };
      final restored = MoveSession.fromJson(json);
      expect(restored.comebackGapDays, 0);
      expect(restored.hasComebackBonus, isFalse);
    });
  });

  group('AppState連携', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('初回起動では記録がなく、ボーナスも出ない', () async {
      final state = AppState();
      await state.load();
      expect(state.lastMoveDayIndex, -1);
      expect(state.comebackGapDays, 0);
      expect(state.hasComebackBonus, isFalse);
    });

    test('保存された最終ムーブ日から休止日数を出す', () async {
      final tenDaysAgo =
          AppState.dayIndexFor(DateTime.now().toUtc()) - 10;
      SharedPreferences.setMockInitialValues({
        'restep.comeback': jsonEncode({'lastMoveDayIndex': tenDaysAgo}),
      });

      final state = AppState();
      await state.load();
      expect(state.comebackGapDays, 10);
      expect(state.comebackMultiplier, 1.5);
      expect(state.hasComebackBonus, isTrue);
    });

    test('今日すでに走っていればボーナスは出ない', () async {
      final today = AppState.dayIndexFor(DateTime.now().toUtc());
      SharedPreferences.setMockInitialValues({
        'restep.comeback': jsonEncode({'lastMoveDayIndex': today}),
      });

      final state = AppState();
      await state.load();
      expect(state.comebackGapDays, 0);
      expect(state.hasComebackBonus, isFalse);
    });

    test('記録が無い既存ユーザーは直近セッションから復元される', () async {
      final twentyDaysAgo =
          DateTime.now().toUtc().subtract(const Duration(days: 20));
      final session = MoveSession(
        startedAt: twentyDaysAgo,
        endedAt: twentyDaysAgo,
        mode: EarnMode.sp,
        shoeName: 'テスト',
        distanceMeters: 1000,
        durationSeconds: 600,
        earnedPoints: 10,
        consumedEnergy: 2,
        rejectedSamples: 0,
      );
      SharedPreferences.setMockInitialValues({
        'restep.sessions': jsonEncode([session.toJson()]),
      });

      final state = AppState();
      await state.load();
      expect(state.comebackGapDays, 20);
      expect(state.comebackMultiplier, 2.0);
    });
  });
}
