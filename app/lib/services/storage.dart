import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/gem.dart';
import '../models/move_session.dart';
import '../models/mystery_box.dart';
import '../models/shoe_inventory.dart';
import '../models/skin.dart';
import 'energy_manager.dart';
import 'shop_service.dart';

/// shared_preferences(WebではlocalStorage)へのローカル保存。
class Storage {
  static const _keyInventory = 'restep.inventory';
  static const _keyEnergy = 'restep.energy';
  static const _keySessions = 'restep.sessions';
  static const _keyBalances = 'restep.balances';
  static const _keyGems = 'restep.gems';
  static const _keySkins = 'restep.skins';
  static const _keyBoxes = 'restep.boxes';
  static const _keyDaily = 'restep.daily';
  static const _keyShop = 'restep.shop';
  static const _keyProfile = 'restep.profile';
  static const _keyClub = 'restep.club';
  static const _keyDailyCap = 'restep.dailyCap';

  static const _keyComeback = 'restep.comeback';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> saveInventory(ShoeInventory inventory) async {
    (await _prefs).setString(_keyInventory, jsonEncode(inventory.toJson()));
  }

  Future<ShoeInventory?> loadInventory() async {
    final raw = (await _prefs).getString(_keyInventory);
    if (raw == null) return null;
    return ShoeInventory.fromJson(jsonDecode(raw) as List<dynamic>);
  }

  Future<void> saveEnergy(EnergyManager energy) async {
    (await _prefs).setString(_keyEnergy, jsonEncode(energy.toJson()));
  }

  Future<EnergyManager?> loadEnergy() async {
    final raw = (await _prefs).getString(_keyEnergy);
    if (raw == null) return null;
    return EnergyManager.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<void> saveSessions(List<MoveSession> sessions) async {
    (await _prefs).setString(
        _keySessions, jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }

  Future<List<MoveSession>> loadSessions() async {
    final raw = (await _prefs).getString(_keySessions);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => MoveSession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveBalances({required double sp, required double gp}) async {
    (await _prefs).setString(_keyBalances, jsonEncode({'sp': sp, 'gp': gp}));
  }

  Future<({double sp, double gp})> loadBalances() async {
    final raw = (await _prefs).getString(_keyBalances);
    if (raw == null) return (sp: 0.0, gp: 0.0);
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return (
      sp: (map['sp'] as num).toDouble(),
      gp: (map['gp'] as num).toDouble(),
    );
  }

  Future<void> saveGems(List<Gem> gems) async {
    (await _prefs)
        .setString(_keyGems, jsonEncode(gems.map((g) => g.toJson()).toList()));
  }

  Future<List<Gem>> loadGems() async {
    final raw = (await _prefs).getString(_keyGems);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Gem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveSkins(List<Skin> skins) async {
    (await _prefs).setString(
        _keySkins, jsonEncode(skins.map((s) => s.toJson()).toList()));
  }

  /// スキン一覧。未保存(初回)は null を返し、呼び出し側でスターター配布する。
  Future<List<Skin>?> loadSkins() async {
    final raw = (await _prefs).getString(_keySkins);
    if (raw == null) return null;
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Skin.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveBoxes(List<MysteryBox> boxes) async {
    (await _prefs).setString(
        _keyBoxes, jsonEncode(boxes.map((b) => b.toJson()).toList()));
  }

  Future<List<MysteryBox>> loadBoxes() async {
    final raw = (await _prefs).getString(_keyBoxes);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => MysteryBox.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// デイリー獲得SP(日付キーと獲得量)。
  Future<void> saveDaily({required String dayKey, required double sp}) async {
    (await _prefs)
        .setString(_keyDaily, jsonEncode({'dayKey': dayKey, 'sp': sp}));
  }

  Future<({String dayKey, double sp})?> loadDaily() async {
    final raw = (await _prefs).getString(_keyDaily);
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return (
      dayKey: map['dayKey'] as String,
      sp: (map['sp'] as num).toDouble(),
    );
  }

  /// 最後にムーブした日(JST4:00境界の通し番号)。復帰ボーナスの起点。
  Future<void> saveComeback({required int lastMoveDayIndex}) async {
    (await _prefs).setString(_keyComeback,
        jsonEncode({'lastMoveDayIndex': lastMoveDayIndex}));
  }

  Future<int?> loadComeback() async {
    final raw = (await _prefs).getString(_keyComeback);
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return (map['lastMoveDayIndex'] as num?)?.toInt();
  }

  Future<void> saveShopCatalog(List<ShopListing> catalog) async {
    (await _prefs).setString(
        _keyShop, jsonEncode(catalog.map((l) => l.toJson()).toList()));
  }

  Future<List<ShopListing>> loadShopCatalog() async {
    final raw = (await _prefs).getString(_keyShop);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) =>
            ShopListing.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveProfile({required String name, required double totalKm}) async {
    (await _prefs).setString(
        _keyProfile, jsonEncode({'name': name, 'totalKm': totalKm}));
  }

  Future<({String name, double totalKm})> loadProfile() async {
    final raw = (await _prefs).getString(_keyProfile);
    if (raw == null) return (name: 'RUNNER', totalKm: 0.0);
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return (
      name: map['name'] as String? ?? 'RUNNER',
      totalKm: (map['totalKm'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// デイリーSP上限の解放フラグ(GPでの買い切り)。
  Future<void> saveDailyCapUnlocked(bool unlocked) async {
    (await _prefs)
        .setString(_keyDailyCap, jsonEncode({'unlocked': unlocked}));
  }

  Future<bool> loadDailyCapUnlocked() async {
    final raw = (await _prefs).getString(_keyDailyCap);
    if (raw == null) return false;
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return map['unlocked'] as bool? ?? false;
  }

  /// クラブ対抗戦の所属と今週の貢献km。未加入なら保存しない。
  Future<void> saveClub({
    required String? clubId,
    required String weekKey,
    required double myKm,
  }) async {
    (await _prefs).setString(
        _keyClub,
        jsonEncode({'clubId': clubId, 'weekKey': weekKey, 'myKm': myKm}));
  }

  Future<({String? clubId, String weekKey, double myKm})?> loadClub() async {
    final raw = (await _prefs).getString(_keyClub);
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return (
      clubId: map['clubId'] as String?,
      weekKey: map['weekKey'] as String? ?? '',
      myKm: (map['myKm'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
