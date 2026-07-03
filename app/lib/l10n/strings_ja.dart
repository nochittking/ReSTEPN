/// UI文字列の集約(国内版)。
/// 英語版対応時はここをFlutter公式l10n(arb)へ移行する。
class S {
  S._();

  static const appTitle = 'RE:STEP MVP';

  // ホーム
  static const energy = 'エナジー';
  static const selectShoe = 'シューズを選択';
  static const selectMode = '報酬モード(どちらか一方のみ)';
  static const startMove = 'ムーブ開始';
  static const noShoes = 'シューズがありません。インベントリから追加してください。';
  static const noEnergy = 'エナジーがありません。回復を待ってください(4時・10時・16時・22時に25%回復)。';
  static const simulationMode = 'シミュレーションモード(開発・QA用)';
  static const inventory = 'インベントリ';
  static const history = '履歴';
  static const balances = '保有ポイント';

  // ムーブ
  static const currentSpeed = '現在速度';
  static const kmh = 'km/h';
  static const inRange = '適正レンジ内';
  static const outOfRange = 'レンジ外(獲得停止中)';
  static const energyEmpty = 'エナジー切れ(獲得停止中)';
  static const elapsed = '経過時間';
  static const distance = '距離';
  static const earned = '獲得';
  static const stopMove = 'ストップ';
  static const simSpeed = 'シミュレーション速度';
  static const gpsWaiting = 'GPS信号を待っています…';

  // リザルト
  static const resultTitle = 'リザルト';
  static const avgSpeed = '平均速度';
  static const duration = 'ムーブ時間';
  static const consumedEnergy = '消費エナジー';
  static const rejectedSamples = '棄却したGPSサンプル(チート検出)';
  static const backToHome = 'ホームへ戻る';

  // インベントリ
  static const inventoryTitle = 'シューズインベントリ';
  static const energyCapNote = '保有数とレアリティでエナジー上限が決まります(上限20.0)';
  static const addShoe = 'シューズを追加(擬似ミント)';
  static const shoeType = 'タイプ';
  static const rarity = 'レアリティ';
  static const add = '追加';
  static const cancel = 'キャンセル';
  static const delete = '削除';
  static const baseEnergyLabel = '保有数による基礎エナジー';
  static const rarityBonusLabel = 'レアリティボーナス';
  static const energyCapLabel = 'エナジー上限';

  // 履歴
  static const historyTitle = 'ムーブ履歴';
  static const noHistory = 'まだムーブの記録がありません。';
}
