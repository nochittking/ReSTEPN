/// ゲームバランスに関わる定数を一元管理する。
/// 数値の根拠: STEPN公式ホワイトペーパー(running-module/energy-system)と
/// 国内解説記事のクロスチェック結果(docs/contingency-plan-slides.html 参照)。
class GameConfig {
  GameConfig._();

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

  /// ポイント獲得レート(適正速度レンジ内・1分あたり)
  static const double spPerMinuteBase = 1.0; // SP(ステップポイント)
  static const double gpPerMinuteBase = 0.5; // GP(ガバナンスポイント)

  /// レアリティごとの獲得倍率(コモン=1.0)
  static const double rarityEarnStep = 0.1;

  /// チート検出: この速度を超える瞬間速度のサンプルは棄却する(km/h)
  static const double maxPlausibleSpeedKmh = 30.0;

  /// チート検出: サンプル間でこの距離(m)を超える瞬間移動は棄却する
  static const double maxJumpMeters = 100.0;

  /// 速度の移動平均に使うサンプル数
  static const int speedWindowSize = 5;
}
