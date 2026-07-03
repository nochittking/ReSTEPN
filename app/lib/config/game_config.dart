/// ゲームバランスに関わる定数を一元管理する。
/// エナジー仕様の根拠: STEPN公式ホワイトペーパー(running-module/energy-system)と
/// 国内解説記事のクロスチェック結果(docs/contingency-plan-slides.html 参照)。
class GameConfig {
  GameConfig._();

  // ---- エナジー ----

  /// 1人あたりデイリーエナジーの絶対上限(ハードキャップ)
  static const double energyHardCap = 20.0;

  /// 靴の保有数 → 基礎エナジー(閾値を超えた最大の段が適用される)
  static const List<(int count, double energy)> energyCountTiers = [
    (1, 2.0),
    (3, 4.0),
    (9, 9.0),
    (15, 12.0),
    (30, 20.0),
  ];

  /// エナジー消費: 1.0エナジー = ムーブ5分(毎分0.2)
  static const double energyPerMinute = 0.2;

  /// 回復: 6時間ごとに上限値の25%(満タン時はスキップ)
  static const double refillRatio = 0.25;

  /// 回復時刻(日本時間・固定)
  static const List<int> refillHoursJst = [4, 10, 16, 22];

  // ---- ポイント獲得 ----

  /// ポイント獲得の基礎レート(適正速度レンジ内・1分あたり)
  static const double spPerMinuteBase = 1.0; // SP(ステップポイント)
  static const double gpPerMinuteBase = 0.5; // GP(ガバナンスポイント)

  /// SP/分 = 基礎レート × (1 + 効率値/100)
  /// 効率値 = レアリティ基礎値 + レベル成長 + ジェム補正

  /// デイリーSP獲得上限(JST 4:00リセット)
  static const double dailySpCap = 1000.0;

  /// デイリーリセット時刻(JST)
  static const int dailyResetHourJst = 4;

  // ---- シューズ属性 ----

  /// レアリティごとの属性基礎値(効率/幸運/快適/回復 共通)
  static const List<double> rarityBaseAttr = [1.0, 8.0, 18.0, 30.0, 45.0];

  /// レベルアップによる属性成長(効率+1.0/Lv、他+0.3/Lv)
  static const double efficiencyPerLevel = 1.0;
  static const double otherAttrPerLevel = 0.3;

  /// 最大レベル
  static const int maxLevel = 30;

  /// レベルアップ費用: SP (Lv+1)×10
  static double levelUpCost(int currentLevel) => (currentLevel + 1) * 10.0;

  // ---- 耐久度 ----

  /// 耐久度の減少: 1分あたり0.3 ×(1 - 回復値/200)
  static const double durabilityPerMinute = 0.3;

  /// 耐久度がこの値未満で獲得効率半減
  static const double durabilityPenaltyThreshold = 50.0;
  static const double durabilityPenaltyFactor = 0.5;

  /// リペア費用: 耐久1あたりSP 0.2 ×(1 + Lv×0.1)
  static double repairCostPerPoint(int level) => 0.2 * (1 + level * 0.1);

  // ---- ジェム ----

  /// 固定値ボーナス(Lv1〜5)
  static const List<double> gemFlatBonus = [2, 8, 25, 72, 200];

  /// 割合ボーナス: Lv×5%
  static const double gemPercentPerLevel = 5.0;

  /// 強化: 同種同Lv3個 → Lv+1を1個。成功率(Lv1→2から順)
  static const List<double> gemUpgradeSuccessRate = [0.55, 0.50, 0.45, 0.40];

  /// 強化費用: SP 100×Lv
  static double gemUpgradeCost(int level) => 100.0 * level;

  /// 最大ジェムレベル
  static const int maxGemLevel = 5;

  // ---- ミステリーボックス ----

  /// スロット数
  static const int boxSlots = 4;

  /// ムーブ10分ごとの基礎ドロップ率5% + 幸運値×0.2%
  static const double boxBaseChancePer10Min = 0.05;
  static const double boxChancePerLuck = 0.002;

  // ---- ショップ ----

  /// ショップ掲載数
  static const int shopCatalogSize = 8;

  /// 価格: 基礎50SP + レアリティ係数 + Lv×10
  static const List<double> shopRarityPrice = [50, 150, 400, 900, 2000];

  // ---- チート検出 ----

  /// この速度を超える瞬間速度のサンプルは棄却する(km/h)
  static const double maxPlausibleSpeedKmh = 30.0;

  /// サンプル間でこの距離(m)を超える瞬間移動は棄却する
  static const double maxJumpMeters = 100.0;

  /// 速度の移動平均に使うサンプル数
  static const int speedWindowSize = 5;

  // ---- その他 ----

  /// 歩数推定: 1歩あたりの距離(m)
  static const double metersPerStep = 0.7;
}
