import '../config/game_config.dart';

/// 報酬モード。ムーブ開始前にどちらか一方を選択する(同時獲得は不可)。
enum EarnMode {
  sp('SP', 'ステップポイント'),
  gp('GP', 'ガバナンスポイント');

  const EarnMode(this.code, this.label);

  final String code;
  final String label;
}

/// 1回のムーブの記録。
class MoveSession {
  MoveSession({
    required this.startedAt,
    required this.endedAt,
    required this.mode,
    required this.shoeName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.earnedPoints,
    required this.consumedEnergy,
    required this.rejectedSamples,
    this.consumedDurability = 0,
    this.boxesObtained = 0,
    this.encounters = 0,
    this.comebackGapDays = 0,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final EarnMode mode;
  final String shoeName;
  final double distanceMeters;
  final int durationSeconds;
  final double earnedPoints;
  final double consumedEnergy;
  final double consumedDurability;
  final int boxesObtained;

  /// すれ違いエンカウントでギフトを貰った回数
  final int encounters;

  /// チート検出(瞬間移動・速度スパイク)で棄却したGPSサンプル数
  final int rejectedSamples;

  /// このムーブが「何日ぶり」だったか(前回ムーブからの休止日数)。
  /// 0 = 同じ日にすでに走っている、または初回。
  final int comebackGapDays;

  /// このムーブに乗った復帰ボーナスの倍率(通常は1.0)。
  double get comebackMultiplier =>
      GameConfig.comebackMultiplierFor(comebackGapDays);

  /// 復帰ボーナスが効いたムーブか。
  bool get hasComebackBonus => comebackMultiplier > 1.0;

  double get averageSpeedKmh {
    if (durationSeconds == 0) return 0;
    return distanceMeters / durationSeconds * 3.6;
  }

  /// 推定歩数(距離÷歩幅)
  int get estimatedSteps =>
      (distanceMeters / GameConfig.metersPerStep).round();

  /// 1分あたりの獲得ポイント
  double get pointsPerMinute {
    if (durationSeconds == 0) return 0;
    return earnedPoints / (durationSeconds / 60.0);
  }

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'mode': mode.name,
        'shoeName': shoeName,
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'earnedPoints': earnedPoints,
        'consumedEnergy': consumedEnergy,
        'consumedDurability': consumedDurability,
        'boxesObtained': boxesObtained,
        'encounters': encounters,
        'rejectedSamples': rejectedSamples,
        'comebackGapDays': comebackGapDays,
      };

  factory MoveSession.fromJson(Map<String, dynamic> json) => MoveSession(
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: DateTime.parse(json['endedAt'] as String),
        mode: EarnMode.values.byName(json['mode'] as String),
        shoeName: json['shoeName'] as String,
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
        durationSeconds: json['durationSeconds'] as int,
        earnedPoints: (json['earnedPoints'] as num).toDouble(),
        consumedEnergy: (json['consumedEnergy'] as num).toDouble(),
        consumedDurability:
            (json['consumedDurability'] as num?)?.toDouble() ?? 0,
        boxesObtained: json['boxesObtained'] as int? ?? 0,
        encounters: json['encounters'] as int? ?? 0,
        rejectedSamples: json['rejectedSamples'] as int? ?? 0,
        comebackGapDays: json['comebackGapDays'] as int? ?? 0,
      );
}
