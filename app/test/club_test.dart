import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/config/game_config.dart';
import 'package:restep_mvp/models/club.dart';
import 'package:restep_mvp/models/npc.dart';
import 'package:restep_mvp/services/club_service.dart';
import 'package:restep_mvp/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// JST時刻をUTCへ直すヘルパ(テストの可読性のため)。
DateTime jst(int y, int m, int d, [int h = 12, int min = 0]) =>
    DateTime.utc(y, m, d, h, min).subtract(const Duration(hours: 9));

void main() {
  const service = ClubService();

  group('週境界(月曜JST4:00)', () {
    test('月曜3:59はまだ前週、4:00から新しい週が始まる', () {
      // 2026-08-03 は月曜
      final before = service.weekKeyFor(jst(2026, 8, 3, 3, 59));
      final after = service.weekKeyFor(jst(2026, 8, 3, 4, 0));
      expect(before, isNot(after));
      // 前週の開始は7/27(前の月曜)、新週の開始は8/3
      expect(service.weekStartFor(jst(2026, 8, 3, 3, 59)),
          DateTime.utc(2026, 7, 27));
      expect(service.weekStartFor(jst(2026, 8, 3, 4, 0)),
          DateTime.utc(2026, 8, 3));
    });

    test('週の途中(木曜)はどの時刻でも同じ週キーになる', () {
      final thursdayMorning = service.weekKeyFor(jst(2026, 8, 6, 5, 0));
      final thursdayNight = service.weekKeyFor(jst(2026, 8, 6, 23, 30));
      expect(thursdayMorning, thursdayNight);
      expect(thursdayMorning, '2026-8-3');
    });

    test('日曜深夜(翌0:30 JST)はまだ同じ週に属する', () {
      // 8/9(日)の翌 0:30 = 8/10(月)0:30 JST → 4:00前なのでまだ8/3週
      expect(service.weekKeyFor(jst(2026, 8, 10, 0, 30)), '2026-8-3');
    });

    test('経過日数は月曜0日→日曜6日', () {
      expect(service.elapsedDaysFor(jst(2026, 8, 3, 12)), 0);
      expect(service.elapsedDaysFor(jst(2026, 8, 6, 12)), 3);
      expect(service.elapsedDaysFor(jst(2026, 8, 9, 23)), 6);
      // 当日を含む日数は+1
      expect(service.activeDaysFor(jst(2026, 8, 9, 23)), 7);
    });

    test('週キーから週開始日へ戻せる', () {
      final key = service.weekKeyFor(jst(2026, 8, 6, 12));
      expect(service.weekStartFromKey(key), DateTime.utc(2026, 8, 3));
      expect(service.weekStartFromKey('こわれた値'), isNull);
    });
  });

  group('NPCの走行距離(決定的)', () {
    test('同じ日付・同じNPCなら何度呼んでも同じ値', () {
      final a = service.npcDailyKm(3, DateTime.utc(2026, 8, 5));
      final b = service.npcDailyKm(3, DateTime.utc(2026, 8, 5));
      expect(a, b);
    });

    test('日付が変われば値も変わる', () {
      final day1 = service.npcDailyKm(3, DateTime.utc(2026, 8, 5));
      final day2 = service.npcDailyKm(3, DateTime.utc(2026, 8, 6));
      expect(day1, isNot(day2));
    });

    test('全NPC・1週間ぶんが 2〜10km × ペース0.7〜1.3 の範囲に収まる', () {
      const minKm = GameConfig.clubNpcKmMin * GameConfig.clubNpcPaceMin;
      const maxKm = GameConfig.clubNpcKmMax * GameConfig.clubNpcPaceMax;
      for (var bot = 0; bot < npcNames.length; bot++) {
        expect(service.paceFactor(bot),
            inInclusiveRange(
                GameConfig.clubNpcPaceMin, GameConfig.clubNpcPaceMax));
        for (var d = 0; d < 7; d++) {
          final km =
              service.npcDailyKm(bot, DateTime.utc(2026, 8, 3).add(Duration(days: d)));
          expect(km, inInclusiveRange(minKm, maxKm));
        }
      }
    });

    test('週合計は日別の合計と一致する', () {
      final weekStart = DateTime.utc(2026, 8, 3);
      var expected = 0.0;
      for (var d = 0; d < 7; d++) {
        expected += service.npcDailyKm(5, weekStart.add(Duration(days: d)));
      }
      expect(service.npcWeekKm(5, weekStart, 7), closeTo(expected, 1e-9));
    });

    test('クラブ合計は所属4名の合計と一致する', () {
      final weekStart = DateTime.utc(2026, 8, 3);
      final club = allClubs.first;
      var expected = 0.0;
      for (final bot in club.memberBotIndices) {
        expected += service.npcWeekKm(bot, weekStart, 7);
      }
      expect(service.clubNpcKm(club, weekStart, 7), closeTo(expected, 1e-9));
    });
  });

  group('対戦相手の抽選', () {
    test('自分のクラブは選ばれない・同じ週なら常に同じ相手', () {
      for (final mine in allClubs) {
        final key = service.weekKeyFor(jst(2026, 8, 6, 12));
        final first = service.pickOpponent(key, mine.id);
        final second = service.pickOpponent(key, mine.id);
        expect(first.id, isNot(mine.id));
        expect(first.id, second.id);
      }
    });

    test('週が替われば相手も替わりうる(全週同一ではない)', () {
      final ids = <String>{};
      for (var w = 0; w < 8; w++) {
        final key =
            service.weekKeyFor(jst(2026, 8, 3, 12).add(Duration(days: 7 * w)));
        ids.add(service.pickOpponent(key, allClubs.first.id).id);
      }
      expect(ids.length, greaterThan(1));
    });
  });

  group('週の決算(settle)', () {
    final weekStart = DateTime.utc(2026, 8, 3);
    final mine = allClubs[0];
    final opponent = allClubs[1];

    test('相手合計はNPC合計の5/4(頭数補正)', () {
      final outcome = service.settle(mine, opponent, weekStart, 0);
      expect(outcome.oppTotal,
          closeTo(service.clubNpcKm(opponent, weekStart, 7) * 5 / 4, 1e-9));
      expect(outcome.myTotal,
          closeTo(service.clubNpcKm(mine, weekStart, 7), 1e-9));
    });

    test('自分が大量に走れば勝てる', () {
      final outcome = service.settle(mine, opponent, weekStart, 10000);
      expect(outcome.won, isTrue);
    });

    test('自分の貢献が0だと負ける(NPC同士は5/4補正で相手有利)', () {
      final outcome = service.settle(mine, opponent, weekStart, 0);
      expect(outcome.won, isFalse);
    });

    test('同点は自分の勝ち', () {
      final base = service.settle(mine, opponent, weekStart, 0);
      final needed = base.oppTotal - base.myTotal;
      final outcome = service.settle(mine, opponent, weekStart, needed);
      expect(outcome.myTotal, closeTo(outcome.oppTotal, 1e-9));
      expect(outcome.won, isTrue);
    });
  });

  group('AppState連携', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('初期状態は未加入・加入すると今週の集計が始まる', () async {
      final state = AppState();
      await state.load();
      expect(state.clubId, isNull);
      expect(state.myClub, isNull);

      await state.joinClub('gale');
      expect(state.myClub?.name, '疾風ランナーズ');
      expect(state.clubMyKm, 0);
      expect(state.clubWeekKey,
          service.weekKeyFor(DateTime.now().toUtc()));
    });

    test('存在しないクラブIDは無視される', () async {
      final state = AppState();
      await state.load();
      await state.joinClub('存在しない');
      expect(state.clubId, isNull);
    });

    test('前週のデータでロードすると決算され、報酬と結果バナーが出る', () async {
      // 保存済みデータを「先週から更新されていない」状態にしておく
      final lastWeek = service.weekKeyFor(
          DateTime.now().toUtc().subtract(const Duration(days: 7)));
      SharedPreferences.setMockInitialValues({
        'flutter.restep.club':
            '{"clubId":"gale","weekKey":"$lastWeek","myKm":99999.0}',
        'flutter.restep.balances': '{"sp":0.0,"gp":0.0}',
      });

      final state = AppState();
      await state.load();

      // 99999km 貢献していれば必ず勝利 → 300SP + ボックス1個
      final result = state.lastClubResult;
      expect(result, isNotNull);
      expect(result!.weekKey, lastWeek);
      expect(result.won, isTrue);
      expect(result.rewardSp, GameConfig.clubWinRewardSp);
      expect(result.rewardBoxes, GameConfig.clubWinRewardBoxes);
      expect(state.spBalance, GameConfig.clubWinRewardSp);
      expect(state.boxes.length, GameConfig.clubWinRewardBoxes);

      // 今週ぶんはリセットされ、所属は維持される
      expect(state.clubMyKm, 0);
      expect(state.clubId, 'gale');
      expect(state.clubWeekKey, service.weekKeyFor(DateTime.now().toUtc()));

      // バナーは一度消化したら消える
      expect(state.consumeClubResult(), isNotNull);
      expect(state.lastClubResult, isNull);
      expect(state.consumeClubResult(), isNull);
    });

    test('貢献0で前週ロードすると敗北報酬50SP・ボックス無し', () async {
      final lastWeek = service.weekKeyFor(
          DateTime.now().toUtc().subtract(const Duration(days: 7)));
      SharedPreferences.setMockInitialValues({
        'flutter.restep.club':
            '{"clubId":"gale","weekKey":"$lastWeek","myKm":0.0}',
        'flutter.restep.balances': '{"sp":0.0,"gp":0.0}',
      });

      final state = AppState();
      await state.load();

      expect(state.lastClubResult?.won, isFalse);
      expect(state.spBalance, GameConfig.clubLoseRewardSp);
      expect(state.boxes, isEmpty);
    });

    test('同じ週のままロードした場合は決算されない', () async {
      final thisWeek = service.weekKeyFor(DateTime.now().toUtc());
      SharedPreferences.setMockInitialValues({
        'flutter.restep.club':
            '{"clubId":"gale","weekKey":"$thisWeek","myKm":12.5}',
        'flutter.restep.balances': '{"sp":0.0,"gp":0.0}',
      });

      final state = AppState();
      await state.load();

      expect(state.lastClubResult, isNull);
      expect(state.clubMyKm, 12.5);
      expect(state.spBalance, 0);
    });

    test('未加入なら週をまたいでも決算されない', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.restep.club': '{"clubId":null,"weekKey":"2020-1-6","myKm":0.0}',
      });
      final state = AppState();
      await state.load();
      expect(state.lastClubResult, isNull);
      expect(state.spBalance, 0);
    });
  });

  group('クラブ定義', () {
    test('4クラブ・各4名で、NPCの重複が無い', () {
      expect(allClubs.length, 4);
      final used = <int>{};
      for (final club in allClubs) {
        expect(club.memberBotIndices.length, 4);
        for (final bot in club.memberBotIndices) {
          expect(bot, inInclusiveRange(0, npcNames.length - 1));
          expect(used.add(bot), isTrue, reason: 'NPC $bot が重複している');
        }
      }
    });

    test('clubById はIDで引ける・未知IDとnullはnull', () {
      expect(clubById('moonlit')?.name, '月夜さんぽ部');
      expect(clubById('nope'), isNull);
      expect(clubById(null), isNull);
    });
  });
}
