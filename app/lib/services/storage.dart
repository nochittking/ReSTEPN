import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/move_session.dart';
import '../models/shoe_inventory.dart';
import 'energy_manager.dart';

/// shared_preferences(WebではlocalStorage)へのローカル保存。
class Storage {
  static const _keyInventory = 'restep.inventory';
  static const _keyEnergy = 'restep.energy';
  static const _keySessions = 'restep.sessions';
  static const _keyBalances = 'restep.balances';

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
}
