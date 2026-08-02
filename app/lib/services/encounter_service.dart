import 'dart:math';

import '../config/game_config.dart';
import '../models/npc.dart';
import '../models/shoe.dart';
import '../models/skin.dart';

/// すれ違いで貰えるギフトの種類。
enum GiftKind { sp, gp, box, skin }

/// すれ違ったNPCと、そのNPCがくれたギフト1件。
class EncounterGift {
  const EncounterGift({
    required this.npcName,
    required this.kind,
    required this.amount,
    this.skin,
  });

  /// すれ違った相手の名前。
  final String npcName;

  final GiftKind kind;

  /// SP/GPの量、ボックスなら個数。スキンは0。
  final double amount;

  /// `kind == GiftKind.skin` のときだけ入る。
  final Skin? skin;
}

/// ムーブ中の「すれ違いエンカウント」。
/// 10分ごとに1回、低確率でNPCとすれ違い、ちょっとしたギフトを貰う。
/// RNGは注入可能(テスト用)。
class EncounterService {
  EncounterService({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  int _seq = 0;

  /// スキンをくれる相手は名無しの職人にする(NPC名簿とは別枠)。
  static const skinGiverName = '旅のスキン職人';

  /// 自動生成スキンの名前テーブル(接頭 + 接尾)。
  static const _skinPrefixes = [
    'ミッドナイト',
    'サンライズ',
    'フォレスト',
    'シーサイド',
    'サンドストーム',
    'クリスタル',
    'チェリー',
    'アイアン',
    'ラベンダー',
    'ゴースト',
  ];

  static const _skinSuffixes = [
    'ダッシュ',
    'トレイル',
    'ウェーブ',
    'ステップ',
    'グロウ',
    'ライン',
    'ドリーム',
    'エッジ',
  ];

  /// 10分ごとに遭遇判定し、貰ったギフトを順に返す。
  /// `freeBoxSlots` はボックスの空きスロット数(足りないぶんはSPに振り替える)。
  List<EncounterGift> rollEncounters({
    required int movedSeconds,
    required int freeBoxSlots,
  }) {
    final gifts = <EncounterGift>[];
    var remainingSlots = max(0, freeBoxSlots);

    final chances = movedSeconds ~/ 600;
    for (var i = 0; i < chances; i++) {
      // 遭遇しなければこの回は何も起きない
      if (_rng.nextDouble() >= GameConfig.encounterChancePer10Min) continue;

      final r = _rng.nextDouble();
      if (r < GameConfig.encounterSkinChance) {
        gifts.add(EncounterGift(
          npcName: skinGiverName,
          kind: GiftKind.skin,
          amount: 0,
          skin: _randomSkin(),
        ));
      } else if (r < GameConfig.encounterBoxChance) {
        if (remainingSlots > 0) {
          remainingSlots--;
          gifts.add(EncounterGift(
            npcName: _randomNpcName(),
            kind: GiftKind.box,
            amount: 1,
          ));
        } else {
          // スロットが満杯ならSPに振り替える
          gifts.add(EncounterGift(
            npcName: _randomNpcName(),
            kind: GiftKind.sp,
            amount: _rollAmount(
                GameConfig.encounterSpMin, GameConfig.encounterSpMax),
          ));
        }
      } else if (r < GameConfig.encounterGpChance) {
        gifts.add(EncounterGift(
          npcName: _randomNpcName(),
          kind: GiftKind.gp,
          amount: _rollAmount(
              GameConfig.encounterGpMin, GameConfig.encounterGpMax),
        ));
      } else {
        gifts.add(EncounterGift(
          npcName: _randomNpcName(),
          kind: GiftKind.sp,
          amount: _rollAmount(
              GameConfig.encounterSpMin, GameConfig.encounterSpMax),
        ));
      }
    }
    return gifts;
  }

  String _randomNpcName() => npcNames[_rng.nextInt(npcNames.length)];

  /// 量を範囲から抽選(小数1桁)。
  double _rollAmount(double min, double max) {
    final v = min + _rng.nextDouble() * (max - min);
    return (v * 10).round() / 10;
  }

  /// 重み付きレアリティ抽選(コモンほど出やすい)。
  Rarity _rollRarity() {
    final weights = GameConfig.encounterSkinRarityWeights;
    final total = weights.reduce((a, b) => a + b);
    var roll = _rng.nextInt(total);
    for (var i = 0; i < weights.length; i++) {
      if (roll < weights[i]) return Rarity.values[i];
      roll -= weights[i];
    }
    return Rarity.common;
  }

  /// ランダムな新規スキン(名前・シルエット・配色・柄すべて抽選)。
  Skin _randomSkin() {
    final name = '${_skinPrefixes[_rng.nextInt(_skinPrefixes.length)]}・'
        '${_skinSuffixes[_rng.nextInt(_skinSuffixes.length)]}';
    return Skin(
      id: 'skin-enc-${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
      name: name,
      visualType: ShoeType.values[_rng.nextInt(ShoeType.values.length)],
      paletteRarity: _rollRarity(),
      seed: _rng.nextInt(100000000),
    );
  }
}
