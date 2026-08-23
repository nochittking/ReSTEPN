import 'dart:math';

import '../config/game_config.dart';
import '../models/gem.dart';

/// ジェムの強化合成とドロップ生成。RNGは注入可能(テスト用)。
class GemService {
  GemService({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  int _seq = 0;

  String _newId() =>
      'gem-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  /// ランダムな種類のLv1ジェムを生成(ボックス開封用)。
  Gem dropGem() {
    final type = GemType.values[_rng.nextInt(GemType.values.length)];
    return Gem(id: _newId(), type: type, level: 1);
  }

  /// 強化の成功率(現在Lv→Lv+1)。
  double successRate(int level) {
    final rates = GameConfig.gemUpgradeSuccessRate;
    return rates[min(level - 1, rates.length - 1)];
  }

  /// 同種同Lvのジェム3個を合成する。
  /// 成功時は新しいLv+1ジェム、失敗時はnullを返す(素材はいずれも消費前提)。
  /// 事前条件を満たさない場合はArgumentError。
  Gem? upgrade(List<Gem> materials) {
    if (materials.length != 3) {
      throw ArgumentError('強化には同種同Lvのジェムが3個必要です');
    }
    final type = materials.first.type;
    final level = materials.first.level;
    if (materials.any((g) => g.type != type || g.level != level)) {
      throw ArgumentError('種類またはレベルが揃っていません');
    }
    if (level >= GameConfig.maxGemLevel) {
      throw ArgumentError('最大レベルのため強化できません');
    }
    if (materials.any((g) => g.equippedShoeId != null)) {
      throw ArgumentError('装着中のジェムは素材にできません');
    }

    if (_rng.nextDouble() < successRate(level)) {
      return Gem(id: _newId(), type: type, level: level + 1);
    }
    return null;
  }

  /// ムーブ結果からのボックスドロップ判定。
  /// 10分ごとに 基礎5%+幸運×0.2% で1回判定する。獲得数を返す。
  ///
  /// [chanceMultiplier] は復帰ボーナスによる出現率の倍率(通常は1.0)。
  /// [guaranteedDrops] は抽選と無関係に先取りする確定枠。
  /// どちらも [freeSlots] を超えて獲得することはない。
  int rollBoxDrops({
    required int movedSeconds,
    required double luck,
    required int freeSlots,
    double chanceMultiplier = 1.0,
    int guaranteedDrops = 0,
  }) {
    if (freeSlots <= 0) return 0;
    final chances = movedSeconds ~/ 600;
    final p = ((GameConfig.boxBaseChancePer10Min +
                luck * GameConfig.boxChancePerLuck) *
            chanceMultiplier)
        .clamp(0.0, 0.9);
    var drops = min(max(0, guaranteedDrops), freeSlots);
    for (var i = 0; i < chances && drops < freeSlots; i++) {
      if (_rng.nextDouble() < p) drops++;
    }
    return drops;
  }
}
