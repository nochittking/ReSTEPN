import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/services/energy_manager.dart';

void main() {
  group('エナジー消費(毎分0.2 = 1.0で5分)', () {
    test('60秒で0.2消費する', () {
      final m = EnergyManager(
          energy: 2.0, lastUpdateUtc: DateTime.utc(2026, 7, 1));
      final used = m.consume(60);
      expect(used, closeTo(0.2, 1e-9));
      expect(m.energy, closeTo(1.8, 1e-9));
    });

    test('残量以上は消費できず0で止まる', () {
      final m = EnergyManager(
          energy: 0.1, lastUpdateUtc: DateTime.utc(2026, 7, 1));
      final used = m.consume(600); // 本来は2.0消費相当
      expect(used, closeTo(0.1, 1e-9));
      expect(m.energy, 0.0);
      expect(m.isEmpty, isTrue);
    });
  });

  group('回復(JST 4/10/16/22時 = UTC 19/1/7/13時に上限の25%)', () {
    test('回復境界を1回通過すると上限の25%回復する', () {
      // UTC 0:30 → 2:00 の間に UTC 1時(JST 10時)の境界を1回通過
      final m = EnergyManager(
          energy: 1.0, lastUpdateUtc: DateTime.utc(2026, 7, 1, 0, 30));
      m.applyRefills(DateTime.utc(2026, 7, 1, 2, 0), 4.0);
      expect(m.energy, closeTo(2.0, 1e-9)); // +25% of 4.0 = +1.0
    });

    test('境界を通過しなければ回復しない', () {
      final m = EnergyManager(
          energy: 1.0, lastUpdateUtc: DateTime.utc(2026, 7, 1, 2, 0));
      m.applyRefills(DateTime.utc(2026, 7, 1, 6, 59), 4.0);
      expect(m.energy, closeTo(1.0, 1e-9));
    });

    test('複数境界の通過ぶん回復し、上限でクランプされる', () {
      // UTC 0:00 → 14:00 で 1時/7時/13時 の3回通過(+75%)
      final m = EnergyManager(
          energy: 0.0, lastUpdateUtc: DateTime.utc(2026, 7, 1, 0, 0));
      m.applyRefills(DateTime.utc(2026, 7, 1, 14, 0), 4.0);
      expect(m.energy, closeTo(3.0, 1e-9));
    });

    test('満タン時は回復がスキップされる(上限を超えない)', () {
      final m = EnergyManager(
          energy: 4.0, lastUpdateUtc: DateTime.utc(2026, 7, 1, 0, 0));
      m.applyRefills(DateTime.utc(2026, 7, 1, 14, 0), 4.0);
      expect(m.energy, 4.0);
    });

    test('24時間以上の放置で必ず満タンになる', () {
      final m = EnergyManager(
          energy: 0.0, lastUpdateUtc: DateTime.utc(2026, 7, 1));
      m.applyRefills(DateTime.utc(2026, 7, 3), 20.0);
      expect(m.energy, 20.0);
    });

    test('上限が縮小された場合(靴を手放した等)は現在値がクランプされる', () {
      final m = EnergyManager(
          energy: 10.0, lastUpdateUtc: DateTime.utc(2026, 7, 1, 2, 0));
      m.applyRefills(DateTime.utc(2026, 7, 1, 2, 30), 4.0);
      expect(m.energy, 4.0);
    });
  });

  group('シリアライズ', () {
    test('toJson/fromJsonで状態が保たれる', () {
      final m = EnergyManager(
          energy: 3.5, lastUpdateUtc: DateTime.utc(2026, 7, 1, 12));
      final restored = EnergyManager.fromJson(
          Map<String, dynamic>.from(m.toJson()));
      expect(restored.energy, 3.5);
      expect(restored.lastUpdateUtc, DateTime.utc(2026, 7, 1, 12));
    });
  });
}
