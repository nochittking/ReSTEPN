import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';

/// 位置サンプル。GPS実装・シミュレーション実装の共通形式。
class LocationSample {
  const LocationSample({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracyMeters = 5.0,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracyMeters;
}

/// 位置情報の供給元。実GPSとシミュレーションを差し替え可能にする。
abstract class LocationProvider {
  Stream<LocationSample> start();
  Future<void> stop();
}

/// 実GPS(geolocator)実装。実機・スマホブラウザで使用する。
class GpsLocationProvider implements LocationProvider {
  StreamSubscription<Position>? _subscription;
  StreamController<LocationSample>? _controller;

  @override
  Stream<LocationSample> start() {
    final controller = StreamController<LocationSample>.broadcast();
    _controller = controller;

    () async {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        controller.addError(StateError('位置情報の利用が許可されていません'));
        return;
      }
      _subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).listen((position) {
        controller.add(LocationSample(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: position.timestamp,
          accuracyMeters: position.accuracy,
        ));
      }, onError: controller.addError);
    }();

    return controller.stream;
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    await _controller?.close();
    _subscription = null;
    _controller = null;
  }
}

/// シミュレーション実装。開発・QA用に指定速度で移動する軌跡を1秒間隔で生成する。
/// 速度は [targetSpeedKmh] でムーブ中も変更できる。
class SimulatedLocationProvider implements LocationProvider {
  SimulatedLocationProvider({
    this.targetSpeedKmh = 4.5,
    this.intervalSeconds = 1,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// 模擬する移動速度(km/h)。ムーブ中にスライダーから変更される。
  double targetSpeedKmh;

  final int intervalSeconds;
  final DateTime Function() _clock;

  Timer? _timer;
  StreamController<LocationSample>? _controller;

  // 皇居周辺を起点に東へ進む(座標自体に意味はない)
  final double _lat = 35.685;
  double _lng = 139.752;

  static const double _metersPerDegLat = 111320.0;

  @override
  Stream<LocationSample> start() {
    final controller = StreamController<LocationSample>.broadcast();
    _controller = controller;
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      final meters = targetSpeedKmh / 3.6 * intervalSeconds;
      final metersPerDegLng = _metersPerDegLat * cos(_lat * pi / 180);
      _lng += meters / metersPerDegLng;
      controller.add(LocationSample(
        latitude: _lat,
        longitude: _lng,
        timestamp: _clock(),
      ));
    });
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    await _controller?.close();
    _timer = null;
    _controller = null;
  }
}
