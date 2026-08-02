import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restep_mvp/config/game_config.dart';
import 'package:restep_mvp/models/move_session.dart';
import 'package:restep_mvp/l10n/strings_ja.dart';
import 'package:restep_mvp/models/npc.dart';
import 'package:restep_mvp/screens/result_screen.dart';
import 'package:restep_mvp/services/encounter_service.dart';
import 'package:restep_mvp/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// nextDoubleを固定値で返すRNG(境界の決め打ち用)。
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

/// 先頭から順に値を返し、尽きたら `fallback` を返すRNG。
/// 遭遇判定(1回目)とギフト抽選(2回目)で別の値を与えるために使う。
class _ScriptedRandom implements Random {
  _ScriptedRandom(this.values, {this.fallback = 0.0});

  final List<double> values;
  final double fallback;
  int _i = 0;

  @override
  double nextDouble() =>
      _i < values.length ? values[_i++] : fallback;

  // nextIntはキューを消費しない(キューはギフト分岐の制御だけに使う)
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => true;
}

/// 「必ず遭遇し、ギフト抽選が r になる」RNG。
EncounterService _serviceForGift(double r) =>
    EncounterService(rng: _ScriptedRandom([0.0, r], fallback: 0.0));

void main() {
  group('遭遇判定', () {
    test('10分未満のムーブでは1回も判定されない', () {
      final service = EncounterService(rng: _FixedRandom(0.0));
      expect(
          service.rollEncounters(movedSeconds: 599, freeBoxSlots: 4), isEmpty);
    });

    test('r=0.99(>=0.15)なら遭遇なし', () {
      final service = EncounterService(rng: _FixedRandom(0.99));
      expect(service.rollEncounters(movedSeconds: 3600, freeBoxSlots: 4),
          isEmpty);
    });

    test('判定回数は movedSeconds ~/ 600 まで(端数の5分は切り捨て)', () {
      // r=0.0 は常に遭遇する
      final service = EncounterService(rng: _FixedRandom(0.0));
      expect(service.rollEncounters(movedSeconds: 65 * 60, freeBoxSlots: 9)
          .length, 6);
    });
  });

  group('ギフト抽選(固定RNGで境界を決め打ち)', () {
    test('r=0.004 → 新規スキン(相手は旅のスキン職人)', () {
      final gifts = _serviceForGift(0.004)
          .rollEncounters(movedSeconds: 600, freeBoxSlots: 4);
      expect(gifts.length, 1);
      expect(gifts.first.kind, GiftKind.skin);
      expect(gifts.first.npcName, EncounterService.skinGiverName);
      expect(gifts.first.skin, isNotNull);
      expect(gifts.first.skin!.name, contains('・'));
      expect(gifts.first.skin!.equippedShoeId, isNull);
    });

    test('r=0.04 → ミステリーボックス', () {
      final gifts = _serviceForGift(0.04)
          .rollEncounters(movedSeconds: 600, freeBoxSlots: 4);
      expect(gifts.single.kind, GiftKind.box);
      expect(gifts.single.amount, 1);
      expect(npcNames, contains(gifts.single.npcName));
    });

    test('r=0.2 → GP(2〜8)', () {
      final gifts = _serviceForGift(0.2)
          .rollEncounters(movedSeconds: 600, freeBoxSlots: 4);
      expect(gifts.single.kind, GiftKind.gp);
      expect(
          gifts.single.amount,
          inInclusiveRange(
              GameConfig.encounterGpMin, GameConfig.encounterGpMax));
    });

    test('r=0.5 → SP(5〜20)', () {
      final gifts = _serviceForGift(0.5)
          .rollEncounters(movedSeconds: 600, freeBoxSlots: 4);
      expect(gifts.single.kind, GiftKind.sp);
      expect(
          gifts.single.amount,
          inInclusiveRange(
              GameConfig.encounterSpMin, GameConfig.encounterSpMax));
    });

    test('ボックス当選でもスロットが満杯ならSPに振り替わる', () {
      final gifts = _serviceForGift(0.04)
          .rollEncounters(movedSeconds: 600, freeBoxSlots: 0);
      expect(gifts.single.kind, GiftKind.sp);
      expect(
          gifts.single.amount,
          inInclusiveRange(
              GameConfig.encounterSpMin, GameConfig.encounterSpMax));
    });

    test('ボックスは空きスロット数を超えて出ない(超過分はSPになる)', () {
      // 3回とも遭遇(0.0)しボックス当選(0.04)。3回目は空き無しでSP振替となり、
      // 振替時だけ量の抽選(0.5)を1回ぶん余計に消費する。
      final rng = _ScriptedRandom(const [
        0.0, 0.04, // 1回目: ボックス
        0.0, 0.04, // 2回目: ボックス
        0.0, 0.04, 0.5, // 3回目: 空き無し → SPへ振替
      ]);
      final gifts = EncounterService(rng: rng)
          .rollEncounters(movedSeconds: 30 * 60, freeBoxSlots: 2);
      expect(gifts.length, 3);
      expect(gifts.where((g) => g.kind == GiftKind.box).length, 2);
      expect(gifts.where((g) => g.kind == GiftKind.sp).length, 1);
    });
  });

  group('スキン生成', () {
    test('レアリティ重みの先頭(コモン)が最小の出目で当たる', () {
      // nextInt が 0 を返す ScriptedRandom(fallback 0.0)ではコモンになる
      final gifts = _serviceForGift(0.004)
          .rollEncounters(movedSeconds: 600, freeBoxSlots: 4);
      final skin = gifts.single.skin!;
      expect(skin.paletteRarity.index, 0);
    });

    test('重みの合計は100で、5段階ぶん定義されている', () {
      expect(GameConfig.encounterSkinRarityWeights.length, 5);
      expect(
          GameConfig.encounterSkinRarityWeights.reduce((a, b) => a + b), 100);
    });

    test('連続して生成してもIDが衝突しない', () {
      // スキン生成はnextIntしか使わないので、キューは遭遇/ギフトのぶんだけでよい
      final rng = _ScriptedRandom(const [
        0.0, 0.004,
        0.0, 0.004,
        0.0, 0.004,
      ]);
      final gifts = EncounterService(rng: rng)
          .rollEncounters(movedSeconds: 30 * 60, freeBoxSlots: 4);
      final ids = gifts.map((g) => g.skin!.id).toSet();
      expect(gifts.length, 3);
      expect(ids.length, 3);
    });
  });

  group('MoveSessionのencounters', () {
    MoveSession sample({int encounters = 0}) => MoveSession(
          startedAt: DateTime.utc(2026, 8, 1, 10),
          endedAt: DateTime.utc(2026, 8, 1, 10, 30),
          mode: EarnMode.sp,
          shoeName: 'コモン ウォーカー',
          distanceMeters: 2400,
          durationSeconds: 1800,
          earnedPoints: 30.5,
          consumedEnergy: 6.0,
          consumedDurability: 8.1,
          boxesObtained: 1,
          encounters: encounters,
          rejectedSamples: 0,
        );

    test('既定値は0', () {
      expect(sample().encounters, 0);
    });

    test('JSON往復で保持される', () {
      final restored = MoveSession.fromJson(
          jsonDecode(jsonEncode(sample(encounters: 3).toJson()))
              as Map<String, dynamic>);
      expect(restored.encounters, 3);
    });

    test('旧形式(encounters欠落)は0にフォールバックする', () {
      final json = sample(encounters: 3).toJson()..remove('encounters');
      final restored = MoveSession.fromJson(
          jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
      expect(restored.encounters, 0);
      // 他のフィールドは壊れていない
      expect(restored.boxesObtained, 1);
      expect(restored.earnedPoints, 30.5);
    });
  });

  group('リザルト画面のすれ違いセクション', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    Future<AppState> loadedState() async {
      final state = AppState();
      await state.load();
      return state;
    }

    Widget wrap(AppState state, MoveSession session) =>
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(home: ResultScreen(session: session)),
        );

    MoveSession session(int encounters) => MoveSession(
          startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          endedAt: DateTime.now(),
          mode: EarnMode.sp,
          shoeName: 'コモン ウォーカー',
          distanceMeters: 2400,
          durationSeconds: 1800,
          earnedPoints: 30.5,
          consumedEnergy: 6.0,
          consumedDurability: 8.1,
          boxesObtained: 0,
          encounters: encounters,
          rejectedSamples: 0,
        );

    testWidgets('0件なら見出しごと表示されない', (tester) async {
      final state = await loadedState();
      state.lastEncounters = [];
      await tester.pumpWidget(wrap(state, session(0)));
      await tester.pump();
      expect(find.text(S.encounterTitle), findsNothing);
    });

    testWidgets('SP/GP/ボックス/スキンがそれぞれ行として出る', (tester) async {
      final state = await loadedState();
      final skin = _serviceForGift(0.004)
          .rollEncounters(movedSeconds: 600, freeBoxSlots: 4)
          .single
          .skin!;
      state.lastEncounters = [
        const EncounterGift(
            npcName: 'hayate_run', kind: GiftKind.sp, amount: 12.3),
        const EncounterGift(
            npcName: 'mochi_walk', kind: GiftKind.gp, amount: 4.5),
        const EncounterGift(
            npcName: 'neko_punch', kind: GiftKind.box, amount: 1),
        EncounterGift(
            npcName: EncounterService.skinGiverName,
            kind: GiftKind.skin,
            amount: 0,
            skin: skin),
      ];
      await tester.pumpWidget(wrap(state, session(4)));
      await tester.pump();

      expect(find.text(S.encounterTitle), findsOneWidget);
      expect(find.text('+ 12.3 SP'), findsOneWidget);
      expect(find.text('+ 4.5 GP'), findsOneWidget);
      expect(find.text(S.encounterBox), findsOneWidget);
      // スキンだけは特別行(専用の見出し+スキン名)
      expect(find.text(S.encounterSkinLead), findsOneWidget);
      expect(find.text(skin.name), findsOneWidget);
    });
  });
}
