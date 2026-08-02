import 'dart:math';

import '../models/move_session.dart';
import '../models/npc.dart';

/// ランキング期間。
enum RankPeriod { week, month, allTime }

/// ランキングの1行。
class RankEntry {
  RankEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.isMe,
    required this.avatarSeed,
  });

  final int rank;
  final String name;
  final double points;
  final bool isMe;
  final int avatarSeed;
}

/// ローカルランキング。
/// 自分の実績(履歴の期間集計)+シード固定の擬似プレイヤーで順位表を作る。
/// ※個人利用アプリのための演出。擬似プレイヤー名は自作の架空名。
class RankingService {
  /// 擬似プレイヤー名は `models/npc.dart` でクラブ/エンカウントと共有する。
  static const _botNames = npcNames;

  /// 期間内の自分の獲得SP合計。
  double myPoints(List<MoveSession> sessions, RankPeriod period,
      {DateTime? now}) {
    final current = now ?? DateTime.now();
    final cutoff = switch (period) {
      RankPeriod.week => current.subtract(const Duration(days: 7)),
      RankPeriod.month => current.subtract(const Duration(days: 30)),
      RankPeriod.allTime => DateTime.fromMillisecondsSinceEpoch(0),
    };
    return sessions
        .where((s) => s.mode == EarnMode.sp && s.endedAt.isAfter(cutoff))
        .fold(0.0, (sum, s) => sum + s.earnedPoints);
  }

  /// 順位表(擬似プレイヤー込み)。
  List<RankEntry> build(
    List<MoveSession> sessions,
    RankPeriod period, {
    required String myName,
    DateTime? now,
  }) {
    final mine = myPoints(sessions, period, now: now);

    // 期間ごとのスケールで擬似プレイヤーのスコアを生成(シード固定で安定)
    final scale = switch (period) {
      RankPeriod.week => 300.0,
      RankPeriod.month => 1200.0,
      RankPeriod.allTime => 15000.0,
    };
    final rng = Random(period.index * 97 + 13);
    final bots = List.generate(_botNames.length, (i) {
      final points =
          scale * (0.3 + rng.nextDouble() * 1.7) * (1 + (i % 5) * 0.1);
      return RankEntry(
        rank: 0,
        name: _botNames[i],
        points: points,
        isMe: false,
        avatarSeed: i,
      );
    });

    final all = [
      ...bots,
      RankEntry(
          rank: 0, name: myName, points: mine, isMe: true, avatarSeed: 99),
    ]..sort((a, b) => b.points.compareTo(a.points));

    return [
      for (var i = 0; i < all.length; i++)
        RankEntry(
          rank: i + 1,
          name: all[i].name,
          points: all[i].points,
          isMe: all[i].isMe,
          avatarSeed: all[i].avatarSeed,
        ),
    ];
  }
}
