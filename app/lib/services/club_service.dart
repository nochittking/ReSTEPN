import 'dart:math';

import '../config/game_config.dart';
import '../models/club.dart';

/// 前週の決算結果。画面でバナーを表示して消化するまで保持する。
class ClubWeekResult {
  const ClubWeekResult({
    required this.weekKey,
    required this.myClubName,
    required this.opponentName,
    required this.won,
    required this.myTotal,
    required this.oppTotal,
    required this.rewardSp,
    required this.rewardBoxes,
  });

  final String weekKey;
  final String myClubName;
  final String opponentName;
  final bool won;
  final double myTotal;
  final double oppTotal;
  final double rewardSp;
  final int rewardBoxes;
}

/// クラブ対抗戦のロジック。
///
/// NPC側の走行距離は「日付 + NPC番号」を種にした決定的な擬似乱数で生成するため、
/// 保存は一切不要(同じ週・同じNPCなら何度計算しても同じ値になる)。
///
/// 週の境界は月曜 JST 4:00(`GameConfig.dailyResetHourJst` と同じ日替わり基準)。
class ClubService {
  const ClubService();

  /// 1週間の日数。
  static const int daysPerWeek = 7;

  /// UTC時刻を「JST 4:00 を日境界とした日付空間」へ移す。
  /// 戻り値の年月日だけが意味を持つ(時刻は切り捨て)。
  static DateTime _shiftedDay(DateTime utc) {
    final jst = utc.add(const Duration(hours: 9));
    final shifted =
        jst.subtract(const Duration(hours: GameConfig.dailyResetHourJst));
    return DateTime.utc(shifted.year, shifted.month, shifted.day);
  }

  /// 対象時刻が属する週の開始日(月曜 JST4:00)。日付空間の値を返す。
  DateTime weekStartFor(DateTime utc) {
    final day = _shiftedDay(utc);
    // DateTime.weekday は月曜=1。月曜まで巻き戻す。
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  /// 週を識別するキー(週開始日の YYYY-MM-DD)。
  String weekKeyFor(DateTime utc) {
    final start = weekStartFor(utc);
    return '${start.year}-${start.month}-${start.day}';
  }

  /// `weekKeyFor` が作ったキーを週開始日へ戻す。壊れた値はnull。
  DateTime? weekStartFromKey(String weekKey) {
    final parts = weekKey.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime.utc(y, m, d);
  }

  /// 週開始からの経過日数(0〜6)。当日ぶんは経過に含めない。
  int elapsedDaysFor(DateTime utc) {
    final diff = _shiftedDay(utc).difference(weekStartFor(utc)).inDays;
    return diff.clamp(0, daysPerWeek - 1);
  }

  /// 週開始からの経過日数を「当日を含む日数」に直したもの(1〜7)。
  int activeDaysFor(DateTime utc) => elapsedDaysFor(utc) + 1;

  /// NPCごとのペース係数(0.7〜1.3)。個体は固定。
  double paceFactor(int bot) {
    final rng = Random(bot * 7919 + 13);
    return GameConfig.clubNpcPaceMin +
        rng.nextDouble() *
            (GameConfig.clubNpcPaceMax - GameConfig.clubNpcPaceMin);
  }

  /// NPCの1日あたり走行距離(km)。日付とNPC番号で決定的。
  double npcDailyKm(int bot, DateTime day) {
    final d = DateTime.utc(day.year, day.month, day.day);
    final dayNumber = d.year * 10000 + d.month * 100 + d.day;
    final rng = Random(dayNumber * 131 + bot * 7919);
    final base = GameConfig.clubNpcKmMin +
        rng.nextDouble() * (GameConfig.clubNpcKmMax - GameConfig.clubNpcKmMin);
    return base * paceFactor(bot);
  }

  /// NPCの週内合計km(週開始から `days` 日ぶん)。
  double npcWeekKm(int bot, DateTime weekStart, int days) {
    var total = 0.0;
    for (var i = 0; i < days; i++) {
      total += npcDailyKm(bot, weekStart.add(Duration(days: i)));
    }
    return total;
  }

  /// クラブ所属NPCの合計km。
  double clubNpcKm(Club club, DateTime weekStart, int days) {
    var total = 0.0;
    for (final bot in club.memberBotIndices) {
      total += npcWeekKm(bot, weekStart, days);
    }
    return total;
  }

  /// 今週の対戦相手(自クラブ以外から決定的に選ぶ・毎週替わる)。
  Club pickOpponent(String weekKey, String myClubId) {
    final others = allClubs.where((c) => c.id != myClubId).toList();
    // 週キーの文字コード和を種にして、週ごとに巡回させる。
    var seed = 0;
    for (final unit in weekKey.codeUnits) {
      seed = seed * 31 + unit;
    }
    return others[seed.abs() % others.length];
  }

  /// 週の決算。相手クラブの合計は頭数差(自分側5名 vs 相手4名)を補正する。
  /// 同点は自分の勝ちとする。
  ({bool won, double myTotal, double oppTotal}) settle(
    Club mine,
    Club opponent,
    DateTime weekStart,
    double myKm,
  ) {
    final myTotal = clubNpcKm(mine, weekStart, daysPerWeek) + myKm;
    // 自分のクラブは「NPC4名+自分」の5名編成なので、相手側を5/4倍して揃える。
    final oppTotal = clubNpcKm(opponent, weekStart, daysPerWeek) * 5 / 4;
    return (won: myTotal >= oppTotal, myTotal: myTotal, oppTotal: oppTotal);
  }
}
