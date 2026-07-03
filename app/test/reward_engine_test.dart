import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/models/move_session.dart';
import 'package:restep_mvp/models/shoe.dart';
import 'package:restep_mvp/services/location_provider.dart';
import 'package:restep_mvp/services/reward_engine.dart';

/// 指定速度(km/h)で東に移動する位置サンプル列を生成する。
List<LocationSample> samplesAtSpeed(double speedKmh, int seconds,
    {DateTime? start}) {
  final startTime = start ?? DateTime.utc(2026, 7, 1, 0, 0, 0);
  const lat = 35.685;
  var lng = 139.752;
  final metersPerDegLng = 111320.0 * cos(lat * pi / 180);
  return List.generate(seconds + 1, (i) {
    final sample = LocationSample(
      latitude: lat,
      longitude: lng,
      timestamp: startTime.add(Duration(seconds: i)),
    );
    lng += speedKmh / 3.6 / metersPerDegLng;
    return sample;
  });
}

Shoe _walker([Rarity rarity = Rarity.common]) =>
    Shoe(id: 's1', type: ShoeType.walker, rarity: rarity);

void main() {
  group('速度判定と距離積算', () {
    test('4.5km/hのサンプルでウォーカーの適正レンジ内になる', () {
      final engine = RewardEngine(shoe: _walker(), mode: EarnMode.sp);
      for (final s in samplesAtSpeed(4.5, 10)) {
        engine.processSample(s);
      }
      expect(engine.currentSpeedKmh, closeTo(4.5, 0.1));
      expect(engine.inRange, isTrue);
      // 10秒×1.25m/s = 12.5m
      expect(engine.distanceMeters, closeTo(12.5, 0.5));
    });

    test('8km/hはウォーカー(1-6km/h)のレンジ外', () {
      final engine = RewardEngine(shoe: _walker(), mode: EarnMode.sp);
      for (final s in samplesAtSpeed(8.0, 10)) {
        engine.processSample(s);
      }
      expect(engine.inRange, isFalse);
    });
  });

  group('ポイント付与', () {
    test('レンジ内: SPモードは1分で1.0ポイント(コモン)', () {
      final engine = RewardEngine(shoe: _walker(), mode: EarnMode.sp);
      for (final s in samplesAtSpeed(4.5, 5)) {
        engine.processSample(s);
      }
      final earned = engine.tick(60, energyAvailable: true);
      expect(earned, closeTo(1.0, 1e-9));
      expect(engine.earnedPoints, closeTo(1.0, 1e-9));
    });

    test('GPモードは1分で0.5ポイント', () {
      final engine = RewardEngine(shoe: _walker(), mode: EarnMode.gp);
      for (final s in samplesAtSpeed(4.5, 5)) {
        engine.processSample(s);
      }
      expect(engine.tick(60, energyAvailable: true), closeTo(0.5, 1e-9));
    });

    test('レジェンダリーは獲得倍率1.4', () {
      final engine =
          RewardEngine(shoe: _walker(Rarity.legendary), mode: EarnMode.sp);
      for (final s in samplesAtSpeed(4.5, 5)) {
        engine.processSample(s);
      }
      expect(engine.tick(60, energyAvailable: true), closeTo(1.4, 1e-9));
    });

    test('レンジ外では付与されない', () {
      final engine = RewardEngine(shoe: _walker(), mode: EarnMode.sp);
      for (final s in samplesAtSpeed(8.0, 5)) {
        engine.processSample(s);
      }
      expect(engine.tick(60, energyAvailable: true), 0);
    });

    test('エナジー切れでは付与されない', () {
      final engine = RewardEngine(shoe: _walker(), mode: EarnMode.sp);
      for (final s in samplesAtSpeed(4.5, 5)) {
        engine.processSample(s);
      }
      expect(engine.tick(60, energyAvailable: false), 0);
    });
  });

  group('チート検出', () {
    test('瞬間移動(1秒で200m)は棄却され距離に反映されない', () {
      final engine = RewardEngine(shoe: _walker(), mode: EarnMode.sp);
      final normal = samplesAtSpeed(4.5, 5);
      for (final s in normal) {
        engine.processSample(s);
      }
      final before = engine.distanceMeters;

      final jump = LocationSample(
        latitude: normal.last.latitude + 0.002, // 約222m北へ瞬間移動
        longitude: normal.last.longitude,
        timestamp: normal.last.timestamp.add(const Duration(seconds: 1)),
      );
      final accepted = engine.processSample(jump);

      expect(accepted, isFalse);
      expect(engine.rejectedSamples, 1);
      expect(engine.distanceMeters, before);
    });

    test('人間として不自然な速度(35km/h)は棄却される', () {
      final engine = RewardEngine(shoe: _walker(), mode: EarnMode.sp);
      final samples = samplesAtSpeed(35.0, 5);
      for (final s in samples) {
        engine.processSample(s);
      }
      expect(engine.rejectedSamples, 5);
      expect(engine.distanceMeters, 0);
      expect(engine.currentSpeedKmh, 0);
    });

    test('棄却後も正常なサンプルは受け付ける', () {
      final engine = RewardEngine(shoe: _walker(), mode: EarnMode.sp);
      final normal = samplesAtSpeed(4.5, 3);
      for (final s in normal) {
        engine.processSample(s);
      }
      // 瞬間移動1回
      final jump = LocationSample(
        latitude: normal.last.latitude + 0.002,
        longitude: normal.last.longitude,
        timestamp: normal.last.timestamp.add(const Duration(seconds: 1)),
      );
      engine.processSample(jump);
      // 瞬間移動先から正常な移動を再開
      final resumed = samplesAtSpeed(4.5, 3,
          start: jump.timestamp.add(const Duration(seconds: 1)));
      var acceptedCount = 0;
      for (final s in resumed) {
        if (engine.processSample(s)) acceptedCount++;
      }
      // 再開1サンプル目は基準点との距離が大きく棄却され得るが、以降は受理される
      expect(acceptedCount, greaterThanOrEqualTo(2));
    });
  });
}
