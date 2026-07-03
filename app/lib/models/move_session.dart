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
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final EarnMode mode;
  final String shoeName;
  final double distanceMeters;
  final int durationSeconds;
  final double earnedPoints;
  final double consumedEnergy;

  /// チート検出(瞬間移動・速度スパイク)で棄却したGPSサンプル数
  final int rejectedSamples;

  double get averageSpeedKmh {
    if (durationSeconds == 0) return 0;
    return distanceMeters / durationSeconds * 3.6;
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
        'rejectedSamples': rejectedSamples,
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
        rejectedSamples: json['rejectedSamples'] as int? ?? 0,
      );
}
