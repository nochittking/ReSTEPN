import 'dart:collection';
import 'dart:math';

import '../config/game_config.dart';
import '../models/move_session.dart';
import '../models/shoe.dart';
import 'location_provider.dart';

/// GPSサンプルの検証(チート棄却)・距離積算・移動平均速度の算出と、
/// 適正速度レンジ内でのポイント付与を担う。
///
/// - 距離/速度の更新はサンプル駆動([processSample])
/// - ポイント付与とエナジー消費の時間積算はタイマー駆動([tick])
class RewardEngine {
  RewardEngine({required this.shoe, required this.mode});

  final Shoe shoe;
  final EarnMode mode;

  final Queue<double> _speedWindow = Queue();
  LocationSample? _lastAccepted;

  double distanceMeters = 0;
  double earnedPoints = 0;
  int rejectedSamples = 0;

  /// 直近サンプルの移動平均速度(km/h)
  double get currentSpeedKmh => _speedWindow.isEmpty
      ? 0
      : _speedWindow.reduce((a, b) => a + b) / _speedWindow.length;

  bool get inRange => shoe.type.inRange(currentSpeedKmh);

  double get _pointsPerMinute {
    final base = switch (mode) {
      EarnMode.sp => GameConfig.spPerMinuteBase,
      EarnMode.gp => GameConfig.gpPerMinuteBase,
    };
    return base * shoe.rarity.earnMultiplier;
  }

  /// GPSサンプルを検証して距離・速度を更新する。
  /// チート検出(瞬間移動・速度スパイク)に該当するサンプルは棄却し false を返す。
  bool processSample(LocationSample sample) {
    final last = _lastAccepted;
    if (last == null) {
      _lastAccepted = sample;
      return true;
    }

    final dtSeconds =
        sample.timestamp.difference(last.timestamp).inMilliseconds / 1000.0;
    if (dtSeconds <= 0) {
      rejectedSamples++;
      return false;
    }

    final meters = _haversineMeters(
        last.latitude, last.longitude, sample.latitude, sample.longitude);
    final speedKmh = meters / dtSeconds * 3.6;

    if (meters > GameConfig.maxJumpMeters ||
        speedKmh > GameConfig.maxPlausibleSpeedKmh) {
      // 瞬間移動または人間の移動として不自然な速度 → 距離・速度に反映しない。
      // 基準点は更新して、以降の正常なサンプルを受け付けられるようにする。
      rejectedSamples++;
      _lastAccepted = sample;
      return false;
    }

    distanceMeters += meters;
    _speedWindow.addLast(speedKmh);
    while (_speedWindow.length > GameConfig.speedWindowSize) {
      _speedWindow.removeFirst();
    }
    _lastAccepted = sample;
    return true;
  }

  /// 経過時間 [dtSeconds] 分のポイントを付与する。
  /// 適正速度レンジ外、またはエナジー切れ([energyAvailable]=false)の間は付与しない。
  /// 戻り値はこのtickで加算されたポイント。
  double tick(double dtSeconds, {required bool energyAvailable}) {
    if (!energyAvailable || !inRange) return 0;
    final earned = _pointsPerMinute / 60.0 * dtSeconds;
    earnedPoints += earned;
    return earned;
  }

  static double _haversineMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;
}
