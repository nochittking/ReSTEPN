import 'dart:collection';
import 'dart:math';

import '../config/game_config.dart';
import '../models/gem.dart';
import '../models/move_session.dart';
import '../models/shoe.dart';
import 'location_provider.dart';

/// GPSサンプルの検証(チート棄却)・距離積算・移動平均速度の算出と、
/// 適正速度レンジ内でのポイント付与を担う。
///
/// - 距離/速度の更新はサンプル駆動([processSample])
/// - ポイント付与とエナジー消費の時間積算はタイマー駆動([tick])
///
/// 獲得レート: 実効効率値(E_eff)÷ モード別の除数。
/// E_eff は efficiencyCap(300)で頭打ち。SPは÷10、GPは÷20。
/// 耐久度が閾値未満のときは半減ペナルティ。
class RewardEngine {
  RewardEngine({
    required this.shoe,
    required this.mode,
    List<Gem> equippedGems = const [],
  }) : _gems = equippedGems;

  final Shoe shoe;
  final EarnMode mode;
  final List<Gem> _gems;

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

  /// 効率値(ジェム補正・ソケット倍率込み・上限適用前)
  double get efficiency => shoe.totalAttr(ShoeAttr.efficiency, _gems);

  /// 実効効率値 E_eff。効率値を上限(300)で頭打ちにしたもの。
  double get effectiveEfficiency =>
      min(efficiency, GameConfig.efficiencyCap);

  /// 現在の獲得レート(ポイント/分)。耐久度ペナルティ込み。
  /// SP/分 = E_eff ÷ 10、GP/分 = E_eff ÷ 20。
  double get pointsPerMinute {
    final divisor = switch (mode) {
      EarnMode.sp => GameConfig.efficiencyDivisorSp,
      EarnMode.gp => GameConfig.efficiencyDivisorGp,
    };
    var rate = effectiveEfficiency / divisor;
    if (shoe.durability < GameConfig.durabilityPenaltyThreshold) {
      rate *= GameConfig.durabilityPenaltyFactor;
    }
    return rate;
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
  /// レンジ外・エナジー切れ・デイリー上限到達([dailyRemaining]=0)の間は付与しない。
  /// 戻り値はこのtickで加算されたポイント。
  double tick(
    double dtSeconds, {
    required bool energyAvailable,
    double dailyRemaining = double.infinity,
  }) {
    if (!energyAvailable || !inRange || dailyRemaining <= 0) return 0;
    var earned = pointsPerMinute / 60.0 * dtSeconds;
    earned = min(earned, dailyRemaining);
    earnedPoints += earned;
    return earned;
  }

  /// 経過時間分の耐久度消費量を返す(回復値で緩和)。
  double durabilityDecay(double dtSeconds) {
    final resilience = shoe.totalAttr(ShoeAttr.resilience, _gems);
    final factor = (1 - resilience / 200).clamp(0.25, 1.0);
    return GameConfig.durabilityPerMinute / 60.0 * dtSeconds * factor;
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
