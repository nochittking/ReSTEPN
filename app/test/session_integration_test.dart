import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/models/move_session.dart';
import 'package:restep_mvp/models/shoe.dart';
import 'package:restep_mvp/models/shoe_inventory.dart';
import 'package:restep_mvp/services/energy_manager.dart';
import 'package:restep_mvp/services/location_provider.dart';
import 'package:restep_mvp/services/reward_engine.dart';

/// 1秒刻みのムーブセッションをシミュレーションで通し、
/// エナジー消費・距離・ポイント・耐久の整合を検証するロジック統合テスト。
void main() {
  test('10分のウォーキングでエナジー2.0を使い切り、約1.0SPを獲得する', () {
    // 1足(コモン・ウォーカー)= エナジー上限2.0 = ムーブ10分ぶん
    final inventory = ShoeInventory([
      Shoe(id: 's1', type: ShoeType.walker, rarity: Rarity.common),
    ]);
    expect(inventory.energyCap, 2.0);

    final shoe = inventory.shoes.first;
    final energy = EnergyManager(
      energy: inventory.energyCap,
      lastUpdateUtc: DateTime.utc(2026, 7, 1, 2, 0),
    );
    final engine = RewardEngine(shoe: shoe, mode: EarnMode.sp);

    // 時速4.5kmで東に移動する軌跡を1秒間隔で生成(12分=720秒ぶん)
    const speedKmh = 4.5;
    const lat = 35.685;
    var lng = 139.752;
    final metersPerDegLng = 111320.0 * cos(lat * pi / 180);
    final start = DateTime.utc(2026, 7, 1, 2, 0);

    var consumed = 0.0;
    var durabilityConsumed = 0.0;
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
      final decay = min(shoe.durability, engine.durabilityDecay(1));
      shoe.durability -= decay;
      durabilityConsumed += decay;
    }

    // エナジーは10分(600秒)で2.0を使い切る
    expect(consumed, closeTo(2.0, 1e-6));
    expect(energy.isEmpty, isTrue);

    // ポイントはエナジーが残っていた600秒ぶんのみ
    // (SP/分 = E_eff÷10 = 1.0÷10 = 0.1/分 × 10分 ≒ 1.0)
    expect(engine.earnedPoints, closeTo(1.0, 0.02));

    // 距離は720秒×1.25m/s = 900m(エナジー切れ後も計測は継続)
    expect(engine.distanceMeters, closeTo(900.0, 5.0));

    // 耐久は12分 × 0.2985/分 ≒ 3.58消費
    expect(durabilityConsumed, closeTo(3.58, 0.05));
    expect(shoe.durability, closeTo(100 - 3.58, 0.05));

    // チート棄却なし
    expect(engine.rejectedSamples, 0);

    // セッション記録の整合
    final session = MoveSession(
      startedAt: start,
      endedAt: start.add(const Duration(seconds: 720)),
      mode: EarnMode.sp,
      shoeName: shoe.displayName,
      distanceMeters: engine.distanceMeters,
      durationSeconds: 720,
      earnedPoints: engine.earnedPoints,
      consumedEnergy: consumed,
      consumedDurability: durabilityConsumed,
      boxesObtained: 0,
      rejectedSamples: engine.rejectedSamples,
    );
    expect(session.averageSpeedKmh, closeTo(4.5, 0.1));
    // 歩数推定: 900m ÷ 0.7m ≒ 1286歩
    expect(session.estimatedSteps, closeTo(1286, 5));

    final restored = MoveSession.fromJson(
        Map<String, dynamic>.from(session.toJson()));
    expect(restored.earnedPoints, session.earnedPoints);
    expect(restored.consumedDurability, session.consumedDurability);
    expect(restored.mode, EarnMode.sp);
  });
}
