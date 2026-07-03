import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/move_session.dart';
import '../models/shoe.dart';
import '../models/shoe_inventory.dart';
import '../services/energy_manager.dart';
import '../services/location_provider.dart';
import '../services/reward_engine.dart';
import '../services/storage.dart';

/// アプリ全体の状態。インベントリ・エナジー・ポイント残高・ムーブ進行を持つ。
class AppState extends ChangeNotifier {
  AppState({Storage? storage}) : _storage = storage ?? Storage();

  final Storage _storage;

  ShoeInventory inventory = ShoeInventory();
  EnergyManager energyManager =
      EnergyManager(energy: 0, lastUpdateUtc: DateTime.now().toUtc());
  List<MoveSession> sessions = [];
  double spBalance = 0;
  double gpBalance = 0;

  String? selectedShoeId;
  EarnMode selectedMode = EarnMode.sp;
  bool simulationMode = kIsWeb; // Web(開発環境)ではデフォルトでシミュレーション
  double simSpeedKmh = 4.5;

  bool loaded = false;

  // ---- ムーブ進行中の状態 ----
  bool get isMoving => _engine != null;
  RewardEngine? _engine;
  LocationProvider? _provider;
  StreamSubscription<LocationSample>? _locationSub;
  Timer? _ticker;
  DateTime? _moveStartedAt;
  int elapsedSeconds = 0;
  double consumedEnergyThisMove = 0;
  bool gpsReceived = false;
  String? locationError;
  MoveSession? lastResult;

  RewardEngine? get engine => _engine;

  Shoe? get selectedShoe => inventory.byId(selectedShoeId);

  Future<void> load() async {
    final savedInventory = await _storage.loadInventory();
    if (savedInventory == null) {
      // 初回起動: コモンのウォーカー1足を配布
      inventory = ShoeInventory([
        Shoe(
          id: 'shoe-initial',
          type: ShoeType.walker,
          rarity: Rarity.common,
        ),
      ]);
      await _storage.saveInventory(inventory);
      energyManager = EnergyManager(
        energy: inventory.energyCap,
        lastUpdateUtc: DateTime.now().toUtc(),
      );
      await _storage.saveEnergy(energyManager);
    } else {
      inventory = savedInventory;
      energyManager = await _storage.loadEnergy() ??
          EnergyManager(
            energy: inventory.energyCap,
            lastUpdateUtc: DateTime.now().toUtc(),
          );
    }
    sessions = await _storage.loadSessions();
    final balances = await _storage.loadBalances();
    spBalance = balances.sp;
    gpBalance = balances.gp;

    energyManager.applyRefills(DateTime.now().toUtc(), inventory.energyCap);
    await _storage.saveEnergy(energyManager);

    selectedShoeId ??= inventory.shoes.isNotEmpty ? inventory.shoes.first.id : null;
    loaded = true;
    notifyListeners();
  }

  // ---- インベントリ操作(プロトタイプ用の擬似ミント) ----

  Future<void> addShoe(ShoeType type, Rarity rarity) async {
    final shoe = Shoe(
      id: 'shoe-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      rarity: rarity,
    );
    inventory.shoes.add(shoe);
    selectedShoeId ??= shoe.id;
    await _storage.saveInventory(inventory);
    _refreshEnergy();
    notifyListeners();
  }

  Future<void> removeShoe(String id) async {
    inventory.shoes.removeWhere((s) => s.id == id);
    if (selectedShoeId == id) {
      selectedShoeId =
          inventory.shoes.isNotEmpty ? inventory.shoes.first.id : null;
    }
    await _storage.saveInventory(inventory);
    _refreshEnergy();
    notifyListeners();
  }

  void selectShoe(String id) {
    selectedShoeId = id;
    notifyListeners();
  }

  void selectMode(EarnMode mode) {
    selectedMode = mode;
    notifyListeners();
  }

  void setSimulationMode(bool value) {
    simulationMode = value;
    notifyListeners();
  }

  void setSimSpeed(double kmh) {
    simSpeedKmh = kmh;
    final provider = _provider;
    if (provider is SimulatedLocationProvider) {
      provider.targetSpeedKmh = kmh;
    }
    notifyListeners();
  }

  void _refreshEnergy() {
    energyManager.applyRefills(DateTime.now().toUtc(), inventory.energyCap);
    _storage.saveEnergy(energyManager);
  }

  // ---- ムーブ ----

  bool get canStart =>
      !isMoving &&
      selectedShoe != null &&
      energyManager.energy > 0;

  void startMove() {
    final shoe = selectedShoe;
    if (shoe == null || isMoving) return;
    _refreshEnergy();
    if (energyManager.isEmpty) {
      notifyListeners();
      return;
    }

    _engine = RewardEngine(shoe: shoe, mode: selectedMode);
    _provider = simulationMode
        ? SimulatedLocationProvider(targetSpeedKmh: simSpeedKmh)
        : GpsLocationProvider();
    _moveStartedAt = DateTime.now();
    elapsedSeconds = 0;
    consumedEnergyThisMove = 0;
    gpsReceived = false;
    locationError = null;
    lastResult = null;

    _locationSub = _provider!.start().listen((sample) {
      gpsReceived = true;
      _engine?.processSample(sample);
      notifyListeners();
    }, onError: (Object e) {
      locationError = e.toString();
      notifyListeners();
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final engine = _engine;
      if (engine == null) return;
      elapsedSeconds++;
      final used = energyManager.consume(1);
      consumedEnergyThisMove += used;
      engine.tick(1, energyAvailable: !energyManager.isEmpty || used > 0);
      notifyListeners();
    });

    notifyListeners();
  }

  Future<MoveSession?> stopMove() async {
    final engine = _engine;
    final startedAt = _moveStartedAt;
    if (engine == null || startedAt == null) return null;

    _ticker?.cancel();
    _ticker = null;
    await _locationSub?.cancel();
    _locationSub = null;
    await _provider?.stop();
    _provider = null;

    final session = MoveSession(
      startedAt: startedAt,
      endedAt: DateTime.now(),
      mode: engine.mode,
      shoeName: engine.shoe.displayName,
      distanceMeters: engine.distanceMeters,
      durationSeconds: elapsedSeconds,
      earnedPoints: engine.earnedPoints,
      consumedEnergy: consumedEnergyThisMove,
      rejectedSamples: engine.rejectedSamples,
    );

    switch (engine.mode) {
      case EarnMode.sp:
        spBalance += engine.earnedPoints;
      case EarnMode.gp:
        gpBalance += engine.earnedPoints;
    }

    sessions.insert(0, session);
    lastResult = session;
    _engine = null;
    _moveStartedAt = null;

    await _storage.saveSessions(sessions);
    await _storage.saveEnergy(energyManager);
    await _storage.saveBalances(sp: spBalance, gp: gpBalance);

    notifyListeners();
    return session;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _locationSub?.cancel();
    _provider?.stop();
    super.dispose();
  }
}
