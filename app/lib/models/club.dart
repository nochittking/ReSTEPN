import 'npc.dart';

/// クラブ(週間のクラブ対抗戦で所属する陣営)。
/// 所属NPCは `npcNames` のインデックスで持つ。
class Club {
  const Club({
    required this.id,
    required this.name,
    required this.motto,
    required this.colorIndex,
    required this.memberBotIndices,
  });

  final String id;
  final String name;

  /// クラブの標語(選択カードに表示)。
  final String motto;

  /// テーマカラーの番号(画面側のパレット参照用)。
  final int colorIndex;

  /// 所属する擬似プレイヤーの `npcNames` 上のインデックス。
  final List<int> memberBotIndices;

  /// 所属NPCの表示名。
  List<String> get memberNames =>
      [for (final i in memberBotIndices) npcNames[i]];
}

/// 全クラブ(4クラブ・各NPC4名)。
const List<Club> allClubs = [
  Club(
    id: 'gale',
    name: '疾風ランナーズ',
    motto: '風より速く、今日も走る。',
    colorIndex: 0,
    memberBotIndices: [0, 3, 13, 18],
  ),
  Club(
    id: 'moonlit',
    name: '月夜さんぽ部',
    motto: '夜の静けさを、ゆっくり歩く。',
    colorIndex: 1,
    memberBotIndices: [4, 5, 12, 19],
  ),
  Club(
    id: 'engawa',
    name: '縁側ウォーカーズ',
    motto: 'のんびり、けれど毎日つづける。',
    colorIndex: 2,
    memberBotIndices: [1, 6, 7, 15],
  ),
  Club(
    id: 'stardust',
    name: '星降りジョガーズ',
    motto: '星を数えながら、軽やかに。',
    colorIndex: 3,
    memberBotIndices: [2, 8, 9, 16],
  ),
];

/// IDからクラブを引く(該当なしはnull)。
Club? clubById(String? id) {
  if (id == null) return null;
  for (final club in allClubs) {
    if (club.id == id) return club;
  }
  return null;
}
