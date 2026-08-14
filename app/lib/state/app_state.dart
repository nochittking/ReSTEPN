import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/game_config.dart';
import '../models/club.dart';
import '../models/gem.dart';
import '../models/move_session.dart';
import '../models/mystery_box.dart';
import '../models/shoe.dart';
import '../models/shoe_inventory.dart';
import '../models/skin.dart';
import '../services/club_service.dart';
import '../services/encounter_service.dart';
import '../services/energy_manager.dart';
import '../services/gem_service.dart';
import '../services/location_provider.dart';
import '../services/mint_service.dart';
import '../services/reward_engine.dart';
import '../services/shop_service.dart';
import '../services/storage.dart';

/// アプリ全体の状態。
/// インベントリ・ジェム・ボックス・エナジー・残高・ショップ・ムーブ進行を持つ。
class AppState extends ChangeNotifier {
  AppState({
    Storage? storage,
    GemService? gemService,
    ShopService? shopService,
    MintService? mintService,
    EncounterService? encounterService,
    Random? rng,
  })  : _storage = storage ?? Storage(),
        _gemService = gemService ?? GemService(),
        _shopService = shopService ?? ShopService(),
        mint = mintService ?? MintService(),
        _encounterService = encounterService ?? EncounterService(),
        _rng = rng ?? Random();

  final Storage _storage;
  final GemService _gemService;
  final ShopService _shopService;
  final EncounterService _encounterService;

  /// 直近のムーブで貰ったすれ違いギフト(リザルト画面が表示する)。
  List<EncounterGift> lastEncounters = [];

  /// クラブ対抗戦(日付シードで決定的なので保存は所属と自分の走行kmのみ)。
  final club = const ClubService();

  /// レベルアップのクリティカル抽選などに使う(テスト注入可)。
  final Random _rng;

  /// ミント・フュージョン・売却ロジック(画面から費用計算等も参照する)
  final MintService mint;

  ShoeInventory inventory = ShoeInventory();
  EnergyManager energyManager =
      EnergyManager(energy: 0, lastUpdateUtc: DateTime.now().toUtc());
  List<MoveSession> sessions = [];
  List<Gem> gems = [];
  List<Skin> skins = [];
  List<MysteryBox> boxes = [];
  List<ShopListing> shopCatalog = [];
  double spBalance = 0;
  double gpBalance = 0;
  String userName = 'RUNNER';
  double totalKm = 0;

  // デイリー獲得SP(JST4:00リセット)
  String _dailyKey = '';
  double dailyEarnedSp = 0;

  // ---- クラブ対抗戦 ----

  /// 所属クラブID(null = 未加入)。
  String? clubId;

  /// 集計中の週キー(`ClubService.weekKeyFor`)。
  String clubWeekKey = '';

  /// 今週の自分の貢献km。
  double clubMyKm = 0;

  /// 未消化の前週決算結果(画面で表示したら `consumeClubResult` で消す)。
  ClubWeekResult? lastClubResult;

  Club? get myClub => clubById(clubId);

  String? selectedShoeId;
  EarnMode selectedMode = EarnMode.sp;
  bool simulationMode = kIsWeb; // Web(開発環境)ではデフォルトでシミュレーション
  double simSpeedKmh = 4.5;

  bool loaded = false;

  // ---- ムーブ進行中の状態 ----
  bool get isMoving => _engine != null;
  bool isPaused = false;
  RewardEngine? _engine;
  LocationProvider? _provider;
  StreamSubscription<LocationSample>? _locationSub;
  Timer? _ticker;
  DateTime? _moveStartedAt;
  int elapsedSeconds = 0;
  double consumedEnergyThisMove = 0;
  double consumedDurabilityThisMove = 0;
  bool gpsReceived = false;
  String? locationError;
  MoveSession? lastResult;

  RewardEngine? get engine => _engine;

  Shoe? get selectedShoe => inventory.byId(selectedShoeId);

  double get dailyRemainingSp =>
      max(0, GameConfig.dailySpCap - dailyEarnedSp);

  /// シューズに装着中のジェム一覧。
  List<Gem> equippedGems(String shoeId) =>
      gems.where((g) => g.equippedShoeId == shoeId).toList();

  /// 属性ごとの装着ジェム(1属性1枠)。
  Gem? equippedGemOf(String shoeId, GemType type) {
    for (final gem in gems) {
      if (gem.equippedShoeId == shoeId && gem.type == type) return gem;
    }
    return null;
  }

  /// 未装着ジェム(種類別)。
  List<Gem> unequippedGems(GemType type) =>
      gems.where((g) => g.equippedShoeId == null && g.type == type).toList();

  // ---- スキン ----

  /// シューズに装着中のスキン(1足1枠)。
  Skin? equippedSkinOf(String? shoeId) {
    if (shoeId == null) return null;
    for (final skin in skins) {
      if (skin.equippedShoeId == shoeId) return skin;
    }
    return null;
  }

  /// 未装着スキン。
  List<Skin> get unequippedSkins =>
      skins.where((s) => s.equippedShoeId == null).toList();

  /// スキンを装着(同じ靴に付いていた別スキンは外す)。自由に再利用可。
  Future<void> equipSkin(String shoeId, Skin skin) async {
    final current = equippedSkinOf(shoeId);
    current?.equippedShoeId = null;
    skin.equippedShoeId = shoeId;
    await _storage.saveSkins(skins);
    notifyListeners();
  }

  Future<void> unequipSkin(Skin skin) async {
    skin.equippedShoeId = null;
    await _storage.saveSkins(skins);
    notifyListeners();
  }

  // ---- 起動時ロード ----

  static String dayKeyFor(DateTime utc) {
    // JST4:00を1日の境界とする
    final jst = utc.add(const Duration(hours: 9));
    final shifted =
        jst.subtract(Duration(hours: GameConfig.dailyResetHourJst));
    return '${shifted.year}-${shifted.month}-${shifted.day}';
  }

  void _rolloverDailyIfNeeded() {
    final key = dayKeyFor(DateTime.now().toUtc());
    if (key != _dailyKey) {
      _dailyKey = key;
      dailyEarnedSp = 0;
      _storage.saveDaily(dayKey: _dailyKey, sp: dailyEarnedSp);
    }
  }

  // ---- クラブ対抗戦 ----

  /// クラブに加入する(週の集計は今週ぶんから始まる)。
  Future<void> joinClub(String id) async {
    if (clubById(id) == null) return;
    clubId = id;
    clubWeekKey = club.weekKeyFor(DateTime.now().toUtc());
    clubMyKm = 0;
    await _storage.saveClub(
        clubId: clubId, weekKey: clubWeekKey, myKm: clubMyKm);
    notifyListeners();
  }

  /// 前週結果バナーを消化する(表示側が一度読んだら消す)。
  ClubWeekResult? consumeClubResult() {
    final result = lastClubResult;
    if (result == null) return null;
    lastClubResult = null;
    notifyListeners();
    return result;
  }

  /// 週をまたいでいたら前週を決算して報酬を配り、今週ぶんをリセットする。
  /// 未加入・同一週なら何もしない。
  Future<void> _rolloverClubIfNeeded() async {
    final mine = myClub;
    if (mine == null) return;
    final currentKey = club.weekKeyFor(DateTime.now().toUtc());
    if (clubWeekKey == currentKey) return;

    final previousStart = club.weekStartFromKey(clubWeekKey);
    if (previousStart != null) {
      final opponent = club.pickOpponent(clubWeekKey, mine.id);
      final outcome = club.settle(mine, opponent, previousStart, clubMyKm);

      final rewardSp = outcome.won
          ? GameConfig.clubWinRewardSp
          : GameConfig.clubLoseRewardSp;
      spBalance += rewardSp;

      // 勝利ボーナスのボックスはスロットに空きがあるときだけ受け取れる
      var rewardBoxes = 0;
      if (outcome.won) {
        final free = GameConfig.boxSlots - boxes.length;
        rewardBoxes = min(GameConfig.clubWinRewardBoxes, max(0, free));
        for (var i = 0; i < rewardBoxes; i++) {
          boxes.add(MysteryBox(
            id: 'box-club-${DateTime.now().microsecondsSinceEpoch}-$i',
            obtainedAt: DateTime.now(),
          ));
        }
      }

      lastClubResult = ClubWeekResult(
        weekKey: clubWeekKey,
        myClubName: mine.name,
        opponentName: opponent.name,
        won: outcome.won,
        myTotal: outcome.myTotal,
        oppTotal: outcome.oppTotal,
        rewardSp: rewardSp,
        rewardBoxes: rewardBoxes,
      );

      await _storage.saveBalances(sp: spBalance, gp: gpBalance);
      await _storage.saveBoxes(boxes);
    }

    clubWeekKey = currentKey;
    clubMyKm = 0;
    await _storage.saveClub(
        clubId: clubId, weekKey: clubWeekKey, myKm: clubMyKm);
  }

  /// ムーブで走ったkmをクラブ貢献に加算する(週跨ぎなら先に決算)。
  Future<void> _addClubKm(double km) async {
    if (myClub == null) return;
    await _rolloverClubIfNeeded();
    clubMyKm += km;
    await _storage.saveClub(
        clubId: clubId, weekKey: clubWeekKey, myKm: clubMyKm);
  }

  Future<void> load() async {
    final savedInventory = await _storage.loadInventory();
    if (savedInventory == null) {
      // 初回起動: コモンのウォーカー1足を配布
      inventory = ShoeInventory([
        Shoe(
          id: 'shoe-initial',
          type: ShoeType.walker,
          rarity: Rarity.common,
          serial: 778894978,
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
    gems = await _storage.loadGems();
    skins = await _storage.loadSkins() ?? starterSkins();
    await _storage.saveSkins(skins);
    boxes = await _storage.loadBoxes();
    final balances = await _storage.loadBalances();
    spBalance = balances.sp;
    gpBalance = balances.gp;
    final profile = await _storage.loadProfile();
    userName = profile.name;
    totalKm = profile.totalKm;

    final daily = await _storage.loadDaily();
    _dailyKey = daily?.dayKey ?? '';
    dailyEarnedSp = daily?.sp ?? 0;
    _rolloverDailyIfNeeded();

    final savedClub = await _storage.loadClub();
    clubId = savedClub?.clubId;
    clubWeekKey = savedClub?.weekKey ?? '';
    clubMyKm = savedClub?.myKm ?? 0;
    // 前回起動から週をまたいでいたらここで前週を決算する
    await _rolloverClubIfNeeded();

    shopCatalog = await _storage.loadShopCatalog();
    if (shopCatalog.isEmpty) {
      shopCatalog = _shopService.generateCatalog();
      await _storage.saveShopCatalog(shopCatalog);
    }

    energyManager.applyRefills(DateTime.now().toUtc(), inventory.energyCap);
    await _storage.saveEnergy(energyManager);

    selectedShoeId ??=
        inventory.shoes.isNotEmpty ? inventory.shoes.first.id : null;
    loaded = true;
    notifyListeners();
  }

  // ---- シューズ操作 ----

  void selectShoe(String id) {
    selectedShoeId = id;
    notifyListeners();
  }

  void selectMode(EarnMode mode) {
    selectedMode = mode;
    notifyListeners();
  }

  Future<void> removeShoe(String id) async {
    inventory.shoes.removeWhere((s) => s.id == id);
    for (final gem in gems) {
      if (gem.equippedShoeId == id) gem.equippedShoeId = null;
    }
    if (selectedShoeId == id) {
      selectedShoeId =
          inventory.shoes.isNotEmpty ? inventory.shoes.first.id : null;
    }
    await _storage.saveInventory(inventory);
    await _storage.saveGems(gems);
    _refreshEnergy();
    notifyListeners();
  }

  /// レベルアップ(SP/GP消費・即時)。Lv+1 とレアリティ別ポイント付与。
  /// クリティカル抽選(critTier: 0=通常/1=大成功×2/2=超大成功×3)と
  /// 節目レベル(10/20/30)のポイント2倍が乗る。
  /// 残高不足・最大Lvなら null。
  Future<({int points, int critTier})?> levelUpShoe(Shoe shoe) async {
    if (shoe.level >= GameConfig.maxLevel) return null;
    final cost = GameConfig.levelUpCost(shoe.level);
    if (spBalance < cost.sp || gpBalance < cost.gp) return null;
    spBalance -= cost.sp;
    gpBalance -= cost.gp;
    shoe.level += 1;

    final r = _rng.nextDouble();
    final critTier = r < GameConfig.levelUpSuperCritChance
        ? 2
        : (r <
                GameConfig.levelUpSuperCritChance +
                    GameConfig.levelUpCritChance
            ? 1
            : 0);
    var points = GameConfig.pointsPerLevelByRarity[shoe.rarity.index] *
        (critTier + 1);
    if (GameConfig.milestoneLevels.contains(shoe.level)) {
      points *= GameConfig.milestonePointFactor;
    }
    shoe.unspentPoints += points;

    await _storage.saveInventory(inventory);
    await _storage.saveBalances(sp: spBalance, gp: gpBalance);
    notifyListeners();
    return (points: points, critTier: critTier);
  }

  /// 手動ポイント振り分け(1ポイント=対象属性+1)。成功時true。
  Future<bool> allocatePoint(Shoe shoe, ShoeAttr attr) async {
    if (shoe.unspentPoints <= 0) return false;
    shoe.unspentPoints -= 1;
    shoe.attrs[attr] = (shoe.attrs[attr] ?? 0) + 1.0;
    await _storage.saveInventory(inventory);
    notifyListeners();
    return true;
  }

  /// リペア費用(耐久degree量に対して)。
  double repairCost(Shoe shoe, double amount) =>
      amount * GameConfig.repairCostPerPoint(shoe.level);

  /// リペア(SP消費で耐久回復)。成功時true。
  Future<bool> repairShoe(Shoe shoe, double amount) async {
    final target = min(100.0, shoe.durability + amount);
    final actual = target - shoe.durability;
    if (actual <= 0) return false;
    final cost = repairCost(shoe, actual);
    if (spBalance < cost) return false;
    spBalance -= cost;
    shoe.durability = target;
    await _storage.saveInventory(inventory);
    await _storage.saveBalances(sp: spBalance, gp: gpBalance);
    notifyListeners();
    return true;
  }

  /// ミント実行。費用を消費し、子1〜2足を追加、消滅した親を除去する。
  /// 結果(子・消滅親・双子か)を返す。残高不足・条件不足ならnull。
  Future<({List<Shoe> children, List<Shoe> vanished, bool twin})?> mintShoes(
      Shoe parent, Shoe partner) async {
    if (!mint.canMint(parent) || !mint.canMint(partner)) return null;
    if (parent.id == partner.id) return null;
    final cost = mint.mintCost(parent, partner);
    if (spBalance < cost.sp || gpBalance < cost.gp) return null;

    spBalance -= cost.sp;
    gpBalance -= cost.gp;
    final result = mint.performMint(parent, partner);

    // 消滅した親を除去(装着ジェム/スキンは外す)
    for (final v in result.vanished) {
      inventory.shoes.removeWhere((s) => s.id == v.id);
      for (final gem in gems) {
        if (gem.equippedShoeId == v.id) gem.equippedShoeId = null;
      }
      if (selectedShoeId == v.id) selectedShoeId = null;
    }
    inventory.shoes.addAll(result.children);
    if (selectedShoeId == null || inventory.byId(selectedShoeId) == null) {
      selectedShoeId =
          inventory.shoes.isNotEmpty ? inventory.shoes.first.id : null;
    }

    await _storage.saveInventory(inventory);
    await _storage.saveGems(gems);
    await _storage.saveBalances(sp: spBalance, gp: gpBalance);
    _refreshEnergy();
    notifyListeners();
    return (
      children: result.children,
      vanished: result.vanished,
      twin: result.children.length > 1,
    );
  }

  /// フュージョン実行。生贄を消費してベース靴の属性を底上げ。
  /// 上がった属性→上げ幅を返す。条件・残高不足ならnull。
  Future<Map<ShoeAttr, double>?> fuseShoes(Shoe base, Shoe sacrifice) async {
    if (mint.fusionBlockReason(base, sacrifice) != null) return null;
    final cost = mint.fusionCost(base.rarity);
    if (spBalance < cost) return null;

    spBalance -= cost;
    final gains = mint.performFusion(base, sacrifice);
    // 生贄を消費(装着ジェムは外す)
    inventory.shoes.removeWhere((s) => s.id == sacrifice.id);
    for (final gem in gems) {
      if (gem.equippedShoeId == sacrifice.id) gem.equippedShoeId = null;
    }
    if (selectedShoeId == sacrifice.id) selectedShoeId = base.id;

    await _storage.saveInventory(inventory);
    await _storage.saveGems(gems);
    await _storage.saveBalances(sp: spBalance, gp: gpBalance);
    _refreshEnergy();
    notifyListeners();
    return gains;
  }

  /// エンハンス実行。素材5足と費用を消費し、結果の靴を返す。
  /// 失敗は無く、必ず1段上(大成功なら2段階上)へ進化する。
  /// 条件・残高不足ならnull。
  Future<({Shoe shoe, bool great, int steps})?> enhanceShoes(
      List<Shoe> materials) async {
    if (mint.enhanceBlockReason(materials) != null) return null;
    final cost = mint.enhanceCost(materials.first.rarity);
    if (spBalance < cost.sp || gpBalance < cost.gp) return null;

    spBalance -= cost.sp;
    gpBalance -= cost.gp;
    final result = mint.performEnhance(materials);
    for (final material in materials) {
      inventory.shoes.removeWhere((s) => s.id == material.id);
      for (final gem in gems) {
        if (gem.equippedShoeId == material.id) gem.equippedShoeId = null;
      }
    }
    inventory.shoes.add(result.shoe);
    if (selectedShoeId == null ||
        inventory.byId(selectedShoeId) == null) {
      selectedShoeId = result.shoe.id;
    }

    await _storage.saveInventory(inventory);
    await _storage.saveGems(gems);
    await _storage.saveBalances(sp: spBalance, gp: gpBalance);
    _refreshEnergy();
    notifyListeners();
    return result;
  }

  /// 売却。靴を手放してSPを得る。
  Future<double?> sellShoe(Shoe shoe) async {
    if (inventory.byId(shoe.id) == null) return null;
    final price = mint.sellPrice(shoe);
    spBalance += price;
    await removeShoe(shoe.id); // ジェム取り外し・保存・エナジー再計算込み
    await _storage.saveBalances(sp: spBalance, gp: gpBalance);
    notifyListeners();
    return price;
  }

  // ---- ジェム操作 ----

  /// 装着(同属性の既装着があれば入れ替え)。
  Future<void> equipGem(String shoeId, Gem gem) async {
    final current = equippedGemOf(shoeId, gem.type);
    current?.equippedShoeId = null;
    gem.equippedShoeId = shoeId;
    await _storage.saveGems(gems);
    notifyListeners();
  }

  Future<void> unequipGem(Gem gem) async {
    gem.equippedShoeId = null;
    await _storage.saveGems(gems);
    notifyListeners();
  }

  /// ジェム強化。結果(成功したジェム or null)を返す。
  /// 素材3個+費用SPを消費する。条件不足時は例外。
  Future<({Gem? result, double cost})> upgradeGems(
      GemType type, int level) async {
    final materials = unequippedGems(type)
        .where((g) => g.level == level)
        .take(3)
        .toList();
    if (materials.length < 3) {
      throw StateError('素材が足りません(同種同Lv3個必要)');
    }
    final cost = GameConfig.gemUpgradeCost(level);
    if (spBalance < cost) {
      throw StateError('SPが足りません');
    }
    spBalance -= cost;
    for (final m in materials) {
      gems.remove(m);
    }
    final result = _gemService.upgrade(materials);
    if (result != null) gems.add(result);
    await _storage.saveGems(gems);
    await _storage.saveBalances(sp: spBalance, gp: gpBalance);
    notifyListeners();
    return (result: result, cost: cost);
  }

  /// 強化の成功率表示用。
  double gemSuccessRate(int level) => _gemService.successRate(level);

  // ---- ミステリーボックス ----

  /// 開封: ボックスを消費してジェムLv1を得る。
  Future<Gem> openBox(MysteryBox box) async {
    boxes.remove(box);
    final gem = _gemService.dropGem();
    gems.add(gem);
    await _storage.saveBoxes(boxes);
    await _storage.saveGems(gems);
    notifyListeners();
    return gem;
  }

  // ---- ショップ ----

  /// 購入。残高不足ならfalse。
  Future<bool> buyShoe(ShopListing listing) async {
    if (spBalance < listing.priceSp) return false;
    if (!shopCatalog.contains(listing)) return false;
    spBalance -= listing.priceSp;
    shopCatalog.remove(listing);
    inventory.shoes.add(listing.shoe);
    selectedShoeId ??= listing.shoe.id;
    // 補充
    shopCatalog.add(_shopService.generateListing());
    shopCatalog.sort((a, b) => a.priceSp.compareTo(b.priceSp));
    await _storage.saveInventory(inventory);
    await _storage.saveBalances(sp: spBalance, gp: gpBalance);
    await _storage.saveShopCatalog(shopCatalog);
    _refreshEnergy();
    notifyListeners();
    return true;
  }

  Future<void> refreshShop() async {
    shopCatalog = _shopService.generateCatalog();
    await _storage.saveShopCatalog(shopCatalog);
    notifyListeners();
  }

  // ---- 設定 ----

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

  /// 次のエナジー回復時刻までの残り時間。
  Duration timeToNextRefill() {
    final nowJst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final hours = GameConfig.refillHoursJst;
    for (final h in hours) {
      final candidate = DateTime(nowJst.year, nowJst.month, nowJst.day, h);
      if (candidate.isAfter(nowJst)) return candidate.difference(nowJst);
    }
    final tomorrow = DateTime(
        nowJst.year, nowJst.month, nowJst.day + 1, hours.first);
    return tomorrow.difference(nowJst);
  }

  // ---- ムーブ ----

  bool get canStart =>
      !isMoving && selectedShoe != null && energyManager.energy > 0;

  void startMove() {
    final shoe = selectedShoe;
    if (shoe == null || isMoving) return;
    _rolloverDailyIfNeeded();
    _refreshEnergy();
    if (energyManager.isEmpty) {
      notifyListeners();
      return;
    }

    _engine = RewardEngine(
      shoe: shoe,
      mode: selectedMode,
      equippedGems: equippedGems(shoe.id),
    );
    _provider = simulationMode
        ? SimulatedLocationProvider(targetSpeedKmh: simSpeedKmh)
        : GpsLocationProvider();
    _moveStartedAt = DateTime.now();
    elapsedSeconds = 0;
    consumedEnergyThisMove = 0;
    consumedDurabilityThisMove = 0;
    isPaused = false;
    gpsReceived = false;
    locationError = null;
    lastResult = null;

    _locationSub = _provider!.start().listen((sample) {
      if (isPaused) return;
      gpsReceived = true;
      _engine?.processSample(sample);
      notifyListeners();
    }, onError: (Object e) {
      locationError = e.toString();
      notifyListeners();
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final engine = _engine;
      if (engine == null || isPaused) return;
      elapsedSeconds++;
      final used = energyManager.consume(1);
      consumedEnergyThisMove += used;

      final earned = engine.tick(
        1,
        energyAvailable: used > 0,
        dailyRemaining:
            engine.mode == EarnMode.sp ? dailyRemainingSp : double.infinity,
      );
      if (engine.mode == EarnMode.sp) dailyEarnedSp += earned;

      final decay = engine.durabilityDecay(1);
      final shoe = engine.shoe;
      final actualDecay = min(shoe.durability, decay);
      shoe.durability -= actualDecay;
      consumedDurabilityThisMove += actualDecay;

      notifyListeners();
    });

    notifyListeners();
  }

  void togglePause() {
    if (!isMoving) return;
    isPaused = !isPaused;
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

    // ボックスドロップ判定(幸運値で補正)
    final luck = engine.shoe.totalAttr(ShoeAttr.luck, equippedGems(engine.shoe.id));
    final drops = _gemService.rollBoxDrops(
      movedSeconds: elapsedSeconds,
      luck: luck,
      freeSlots: GameConfig.boxSlots - boxes.length,
    );
    for (var i = 0; i < drops; i++) {
      boxes.add(MysteryBox(
        id: 'box-${DateTime.now().microsecondsSinceEpoch}-$i',
        obtainedAt: DateTime.now(),
      ));
    }

    // すれ違いエンカウント(ボックスドロップ後の空きスロットで判定する)
    final encounters = _encounterService.rollEncounters(
      movedSeconds: elapsedSeconds,
      freeBoxSlots: GameConfig.boxSlots - boxes.length,
    );
    var skinObtained = false;
    for (var i = 0; i < encounters.length; i++) {
      final gift = encounters[i];
      switch (gift.kind) {
        case GiftKind.sp:
          spBalance += gift.amount;
        case GiftKind.gp:
          gpBalance += gift.amount;
        case GiftKind.box:
          boxes.add(MysteryBox(
            id: 'box-enc-${DateTime.now().microsecondsSinceEpoch}-$i',
            obtainedAt: DateTime.now(),
          ));
        case GiftKind.skin:
          if (gift.skin != null) {
            skins.add(gift.skin!);
            skinObtained = true;
          }
      }
    }
    if (skinObtained) await _storage.saveSkins(skins);
    lastEncounters = encounters;

    final session = MoveSession(
      startedAt: startedAt,
      endedAt: DateTime.now(),
      mode: engine.mode,
      shoeName: engine.shoe.displayName,
      distanceMeters: engine.distanceMeters,
      durationSeconds: elapsedSeconds,
      earnedPoints: engine.earnedPoints,
      consumedEnergy: consumedEnergyThisMove,
      consumedDurability: consumedDurabilityThisMove,
      boxesObtained: drops,
      encounters: encounters.length,
      rejectedSamples: engine.rejectedSamples,
    );

    switch (engine.mode) {
      case EarnMode.sp:
        spBalance += engine.earnedPoints;
      case EarnMode.gp:
        gpBalance += engine.earnedPoints;
    }

    totalKm += engine.distanceMeters / 1000;
    await _addClubKm(engine.distanceMeters / 1000);
    sessions.insert(0, session);
    lastResult = session;
    _engine = null;
    _moveStartedAt = null;
    isPaused = false;

    await _storage.saveSessions(sessions);
    await _storage.saveEnergy(energyManager);
    await _storage.saveBalances(sp: spBalance, gp: gpBalance);
    await _storage.saveInventory(inventory);
    await _storage.saveBoxes(boxes);
    await _storage.saveDaily(dayKey: _dailyKey, sp: dailyEarnedSp);
    await _storage.saveProfile(name: userName, totalKm: totalKm);

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
