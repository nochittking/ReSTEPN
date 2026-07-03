import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/models/move_session.dart';
import 'package:restep_mvp/models/shoe.dart';
import 'package:restep_mvp/models/shoe_inventory.dart';
import 'package:restep_mvp/services/energy_manager.dart';
import 'package:restep_mvp/services/location_provider.dart';
import 'package:restep_mvp/services/reward_engine.dart';

/// 1秒刻みのムーブセッションをシミュレーションで通し、
/// エナジー消費・距離・ポイントの整合を検証するロジック統合テスト。
void main() {
  test('10分のウォーキングでエナジー2.0を使い切り、約10SPを獲得する', () {
    // 1足(コモン・ウォーカー)= エナジー上限2.0 = ムーブ10分ぶん
    final inventory = ShoeInventory([
      Shoe(id: 's1', type: ShoeType.walker, rarity: Rarity.common),
    ]);
    expect(inventory.energyCap, 2.0);

    final energy = EnergyManager(
      energy: inventory.energyCap,
      lastUpdateUtc: DateTime.utc(2026, 7, 1, 2, 0),
    );
    final engine =
        RewardEngine(shoe: inventory.shoes.first, mode: EarnMode.sp);

    // 時速4.5kmで東に移動する軌跡を1秒間隔で生成(12分=720秒ぶん)
    const speedKmh = 4.5;
    const lat = 35.685;
    var lng = 139.752;
    final metersPerDegLng = 111320.0 * cos(lat * pi / 180);
    final start = DateTime.utc(2026, 7, 1, 2, 0);

    var consumed = 0.0;
    for (var second = 1; second <= 720; second++) {
      lng += speedKmh / 3.6 / metersPerDegLng;
      engine.processSample(LocationSample(
        latitude: lat,
        longitude: lng,
        timestamp: start.add(Duration(seconds: second)),
      ));
      final used = energy.consume(1);
      consumed += used;
      engine.tick(1, energyAvailable: used > 0);
    }

    // エナジーは10分(600秒)で2.0を使い切る
    expect(consumed, closeTo(2.0, 1e-6));
    expect(energy.isEmpty, isTrue);

    // ポイントはエナジーが残っていた600秒ぶんのみ(SP 1.0/分 × 10分 ≒ 10)
    expect(engine.earnedPoints, closeTo(10.0, 0.1));

    // 距離は720秒×1.25m/s = 900m(エナジー切れ後も計測は継続)
    expect(engine.distanceMeters, closeTo(900.0, 5.0));

    // チート棄却なし
    expect(engine.rejectedSamples, 0);

    // セッション記録の整合
    final session = MoveSession(
      startedAt: start,
      endedAt: start.add(const Duration(seconds: 720)),
      mode: EarnMode.sp,
      shoeName: inventory.shoes.first.displayName,
      distanceMeters: engine.distanceMeters,
      durationSeconds: 720,
      earnedPoints: engine.earnedPoints,
      consumedEnergy: consumed,
      rejectedSamples: engine.rejectedSamples,
    );
    expect(session.averageSpeedKmh, closeTo(4.5, 0.1));

    final restored = MoveSession.fromJson(
        Map<String, dynamic>.from(session.toJson()));
    expect(restored.earnedPoints, session.earnedPoints);
    expect(restored.mode, EarnMode.sp);
  });
}
