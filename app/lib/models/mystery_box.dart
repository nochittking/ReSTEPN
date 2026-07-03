/// ミステリーボックス。ムーブ終了時に確率で獲得し、開封するとジェムが出る。
class MysteryBox {
  MysteryBox({required this.id, required this.obtainedAt});

  final String id;
  final DateTime obtainedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'obtainedAt': obtainedAt.toIso8601String(),
      };

  factory MysteryBox.fromJson(Map<String, dynamic> json) => MysteryBox(
        id: json['id'] as String,
        obtainedAt: DateTime.parse(json['obtainedAt'] as String),
      );
}
