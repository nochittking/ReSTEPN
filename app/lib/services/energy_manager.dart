import 'dart:math';

import '../config/game_config.dart';

/// エナジーの消費と時刻固定の自動回復を管理する。
///
/// - 消費: 毎分0.2(=1.0で5分のムーブ)
/// - 回復: 日本時間 4:00/10:00/16:00/22:00 に上限値の25%ずつ。満タン時はスキップ
/// - 上限: シューズ保有状況から算出された値(最大20.0)。上限縮小時はクランプ
class EnergyManager {
  EnergyManager({
    required this.energy,
    required this.lastUpdateUtc,
  });

  double energy;
  DateTime lastUpdateUtc;

  static const int _jstOffsetHours = 9;

  /// 回復境界時刻のUTCでの「時」(JST 4/10/16/22 → UTC 19/1/7/13)
  static final Set<int> _refillHoursUtc = GameConfig.refillHoursJst
      .map((h) => (h - _jstOffsetHours) % 24 < 0
          ? (h - _jstOffsetHours) % 24 + 24
          : (h - _jstOffsetHours) % 24)
      .toSet();

  /// [lastUpdateUtc] から [nowUtc] までに通過した回復時刻ぶんの回復を適用する。
  void applyRefills(DateTime nowUtc, double cap) {
    if (nowUtc.isBefore(lastUpdateUtc)) {
      lastUpdateUtc = nowUtc;
      energy = min(energy, cap);
      return;
    }

    // 24時間以上放置されていれば回復は4回以上通過している=必ず満タン
    if (nowUtc.difference(lastUpdateUtc) >= const Duration(hours: 24)) {
      energy = cap;
      lastUpdateUtc = nowUtc;
      return;
    }

    // 直近24時間以内: 1時間刻みで回復境界の通過を数える
    var cursor = DateTime.utc(
      lastUpdateUtc.year,
      lastUpdateUtc.month,
      lastUpdateUtc.day,
      lastUpdateUtc.hour,
    );
    while (true) {
      cursor = cursor.add(const Duration(hours: 1));
      if (cursor.isAfter(nowUtc)) break;
      if (_refillHoursUtc.contains(cursor.hour)) {
        energy = min(cap, energy + cap * GameConfig.refillRatio);
      }
    }

    energy = min(energy, cap);
    lastUpdateUtc = nowUtc;
  }

  /// ムーブ中の時間経過 [dtSeconds] ぶんのエナジーを消費する。
  /// 戻り値は実際に消費した量。
  double consume(double dtSeconds) {
    final want = GameConfig.energyPerMinute / 60.0 * dtSeconds;
    final used = min(energy, want);
    energy -= used;
    return used;
  }

  bool get isEmpty => energy <= 0;

  Map<String, dynamic> toJson() => {
        'energy': energy,
        'lastUpdateUtc': lastUpdateUtc.toIso8601String(),
      };

  factory EnergyManager.fromJson(Map<String, dynamic> json) => EnergyManager(
        energy: (json['energy'] as num).toDouble(),
        lastUpdateUtc: DateTime.parse(json['lastUpdateUtc'] as String).toUtc(),
      );
}
