/// UI文字列の集約(国内版)。
/// 英語版対応時はここをFlutter公式l10n(arb)へ移行する。
class S {
  S._();

  static const appTitle = 'RE:STEP';

  // タブ
  static const tabMove = 'ムーブ';
  static const tabShoes = 'シューズ';
  static const tabRanking = 'ランキング';
  static const tabShop = 'ショップ';

  // ホーム
  static const start = 'スタート';
  static const howToPlay = 'あそびかた';
  static const refillIn = '回復まで';
  static const noShoes = 'シューズがありません。ショップで購入してください。';
  static const noEnergy = 'エナジー不足です。回復(4時・10時・16時・22時)を待ってください。';
  static const simulationMode = 'シミュレーション(開発用)';
  static const lootBox = 'ルートボックス';
  static const emptySlot = '空きスロット';
  static const openNow = '開封する';
  static const boxObtained = 'ミステリーボックスを獲得!';
  static const gemObtained = 'ジェムを入手!';

  // ムーブ
  static const walking = 'ウォーキング';
  static const paused = '一時停止中';
  static const kmh = 'km/h';
  static const kilometers = 'キロメートル';
  static const outOfRange = 'レンジ外(獲得停止中)';
  static const energyEmpty = 'エナジー切れ';
  static const dailyCapReached = 'デイリー上限到達';
  static const gpsWaiting = 'GPS待機中…';
  static const simSpeed = 'シミュレーション速度';

  // リザルト
  static const resultTitle = 'リザルト';
  static const normalMeasure = '正常計測';
  static const suspicious = '要確認';
  static const km = 'Km';
  static const time = '時間';
  static const steps = '歩数';
  static const perMin = '/分';
  static const backToHome = 'ホームへ戻る';
  static const slotsFull = 'スロットが満杯です';

  // シューズタブ
  static const segSneakers = 'シューズ';
  static const segGems = 'ジェム';
  static const segOthers = 'その他';
  static const subGallery = 'ギャラリー';
  static const subUpgrade = '強化';
  static const subScroll = 'スクロール';
  static const subBadges = 'バッジ';
  static const comingSoon = '準備中';
  static const mintLabel = 'ミント';
  static const noGems = 'ジェムがありません。ムーブでボックスを集めよう。';

  // シューズ詳細
  static const attributes = '属性';
  static const attrBase = '基礎値';
  static const attrWithGems = 'ジェム込み';
  static const levelUp = 'レベルアップ';
  static const repair = 'リペア';
  static const mint = 'ミント';
  static const sell = '売却';
  static const fusion = 'フュージョン';
  static const transfer = '転送';
  static const durability = '耐久度';
  static const cost = '費用';
  static const cancel = 'キャンセル';
  static const confirm = '決定';
  static const notEnoughSp = 'SPが足りません';
  static const maxLevelReached = '最大レベルです';
  static const removeGem = 'ジェムを外す';
  static const equipGem = '装着する';
  static const selectGem = 'ジェムを選択';
  static const enhance = 'エンハンス';
  static const attrPlusPoint = '+ポイント';
  static const unspentPoints = '未割り当てポイント';
  static const levelUpGrant = 'レベルアップで振り分けポイント +4';
  static const allocate = '割り振る';

  // ミント
  static const mintTitle = 'シューズミント';
  static const selectPartner = '相方のシューズを選択';
  static const matchingShoes = 'ミント可能なシューズ';
  static const tokenConsumption = '消費ポイント';
  static const mintButton = 'ミント';
  static const mintDone = 'ミント成功!新しいシューズが誕生!';
  static const noPartner = 'ミント可能な相方がいません(Lv5以上・ミント7回未満)';
  static const idLabel = 'ID';
  static const levelLabel = 'レベル';
  static const classLabel = 'クラス';
  static const shoeMintLabel = 'ミント回数';
  static const vanishChanceLabel = '消滅リスク(親)';
  static const twinChanceLabel = '双子確率';
  static const vanishNote = 'ミント回数が多い親ほど消滅しやすく、7回目は必ず引退します';

  // エンハンス(同レア5足→上位レアリティ)
  static const enhanceTitle = 'エンハンス';
  static const enhanceButton = 'エンハンス';
  static const enhanceNote = '同レアリティ5足を合成。成功で1段上、失敗でも同レアリティの靴が生まれます';
  static const enhanceSuccess = 'エンハンス成功!レアリティアップ!';
  static const enhanceFail = 'レアリティは上がらなかったが、新しい靴が誕生した';
  static const rainbowChance = 'レインボー確率(準備中)';
  static const notEnoughShoes = '同レアリティの靴が5足必要です';
  static const legendaryCannot = 'レジェンダリーは対象外です';

  // フュージョン(ベース+生贄1足で属性底上げ)
  static const fusionTitle = 'フュージョン';
  static const fusionButton = 'フュージョン';
  static const fusionNote = '生贄の値がベースを上回る属性を、範囲内でランダムに底上げします';
  static const fusionBase = 'ベース(強化される靴)';
  static const fusionSacrifice = '生贄の靴を選択';
  static const fusionMatching = '同レアリティの靴';
  static const fusionDone = 'フュージョン完了!属性が底上げされた';
  static const fusionNoGain = '底上げできる属性がありませんでした';
  static const baseAttributes = 'ベース属性';

  // スキン(見た目を変える独自アイテム)
  static const skin = 'スキン';
  static const segSkins = 'スキン';
  static const equipSkin = 'スキンを装着';
  static const removeSkin = 'スキンを外す';
  static const selectSkin = 'スキンを選択';
  static const noSkins = 'スキンがありません。';
  static const noSkinEquipped = 'スキン未装着(元の見た目)';
  static const skinNote = '装着すると見た目だけを変更します。ステータスやレアリティは変わりません。';
  static const skinInUse = '他の靴に装着中';

  // 売却
  static const sellTitle = '売却';
  static const sellConfirm = 'このシューズを売却しますか?装着中のジェムは外れます。';
  static const sellDone = '売却しました',
      sellPriceLabel = '売却価格';

  // ジェム強化
  static const upgradeTitle = 'ジェム強化';
  static const successRate = '成功率';
  static const upgradeFailNote = '失敗すると素材は失われます';
  static const upgradeButton = '強化する';
  static const upgradeSuccess = '強化成功!';
  static const upgradeFailed = '強化失敗…素材は失われました';
  static const notEnoughGems = '同種同Lvのジェムが3個必要です';

  // ランキング
  static const week = '週間';
  static const month = '月間';
  static const allTime = '全期間';
  static const me = 'ME';
  static const pts = 'pts';
  static const endingIn = '締切まで';
  static const rankingNote = '※ランキングはローカルの記録+架空プレイヤーです';

  // ショップ
  static const buy = '購入';
  static const lowestPrice = '価格が安い順';
  static const shopRefresh = '品揃えを更新';
  static const bought = '購入しました!';

  // 履歴
  static const historyTitle = 'ムーブ履歴';
  static const noHistory = 'まだムーブの記録がありません。';
  static const avgSpeed = '平均速度';
}
