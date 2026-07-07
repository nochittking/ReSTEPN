# RE:STEP プロジェクトガイド

RE:STEP は STEPN 風 Move to Earn の**個人用**シミュレーターアプリ。Flutter 3.x 製(`app/` 配下)、
Provider + shared_preferences、完全ローカル動作・非公開が前提(法務上の理由で外部公開しない)。
オーナーとの対話・コミットメッセージ・コード内コメントは**日本語**。

## 絶対制約(違反しないこと)

1. **靴の描画エンジンは凍結**: `app/lib/widgets/sneaker_art.dart` の painter 内部
   (`_LowPolyPainter`・`_Spec`・パレット生成)は、オーナーがラフ案・配色方針を明示するまで
   一切変更しない。見た目の変更はスキン機構(type / paletteRarity / seed の差し替え)で行う。
   `SneakerArt` ウィジェットの受け口(skin パラメータ等)の拡張は可。
2. **ゲーム数値はオーナーが確定させたもの**: `game_config.dart` の定数を勝手に変えない。
   変更提案は「現在値 → 提案値 + 期待値計算」の表で提示し、承認を得てから実装する。
3. **用語を混同しない**(過去に混同事故あり):
   - **エンハンス** = 同レアリティ5足を合成して1段上のレアリティに挑戦(失敗でも同レア新品)
   - **フュージョン** = ベース靴 + 同レア生贄1足。生贄が上回る属性のみ (現在値, 生贄値] で底上げ

## アーキテクチャ地図(`app/lib/`)

| パス | 役割 |
|---|---|
| `config/game_config.dart` | 全ゲームバランス定数の一元管理(数値変更は必ずここ) |
| `models/` | Shoe(attrs個体値+unspentPoints)/ Gem / Skin / MysteryBox / MoveSession / ShoeInventory |
| `services/mint_service.dart` | ミント(消滅/双子)・エンハンス・フュージョン・売却価格 |
| `services/shop_service.dart` | ショップ生成(属性連動価格+8%半額SALE)・ShopListing |
| `services/gem_service.dart` | ジェム強化・ボックスドロップ判定 |
| `services/storage.dart` | shared_preferences 永続化(キーは `restep.*`) |
| `services/reward_engine.dart` / `energy_manager.dart` | ムーブ中の獲得・エナジー |
| `state/app_state.dart` | 唯一の ChangeNotifier。全画面がここを watch |
| `l10n/strings_ja.dart` | 全UI文字列(`S.*`)。文字列のハードコード禁止 |
| `theme/restep_theme.dart` | デザイントークン(`RS.*`: 色・タイポ) |
| `screens/` / `widgets/` | 画面と共有ウィジェット(StepnButton/StepnCard/PillBadge等) |

## 実装済みゲームシステム(概要)

- **属性個体値**: ミント/購入時にレアリティ帯(`mintAttrRange`)からロール。レベルアップは自動成長なし。
- **クリティカルLvアップ**: 基礎ポイント レアリティ別 4/6/8/10/12 pt。1ロールで 5%→×3(超大成功)、
  25%未満→×2(大成功)。節目 Lv10/20/30 は費用3倍+GP併用(SPの1/10)・ポイント2倍。
- **ミント改変**: 各親が自分の「何回目か」で消滅判定(`mintVanishByOccasion`、7回目=100%)。
  双子率 = 両親合計ミント回数×4%(上限48%)。ミント画面に事前オッズ表示あり。
- **スキン**: 靴に1枠装着で見た目だけ変更(ステータス不変)。付け外し自由・再利用可。
- **経済**: 売却 = ショップ基準×0.4 + Lv×5 + 属性合計×1.0。ショップ価格に属性合計×1.5、8%で半額SALE。

## コーディング規約

- コメント・テスト名は日本語。UI文字列は `strings_ja.dart` に集約。
- 複数戻り値はレコード型(例: `({double sp, double gp})`、`({int points, int critTier})`)。
- 乱数は全サービスでコンストラクタ注入(`MintService({Random? rng})`)。テストは `_FixedRandom`
  (nextDouble固定値)で境界を決め打ちする(例: r=0.04→超大成功、r=0.24→大成功)。
- セーブデータ互換: `fromJson` は旧形式(フィールド欠落)を必ずフォールバック移行する
  (例: attrs 無し → `rarityBaseAttr`+レベルから近似)。

## 検証の掟(変更のたびに全部)

```
cd app
/opt/flutter/bin/flutter analyze          # 0 issues
/opt/flutter/bin/flutter test             # 全パス(現在87件)
/opt/flutter/bin/flutter build web --no-web-resources-cdn
# E2Eスクショ通し(手順・罠は .claude/skills/restep-verify 参照)
```

段階(ステージ)ごとにコミット・プッシュ。ブランチはセッション指示に従う。

## オーナーとの進め方

- 仕様・数値はオーナーが決める。提案は選択肢2〜4個+推奨を付けて日本語で。
- 実装後はE2Eスクショを送って見せる(百聞は一見にしかず)。
- 「準備中」機能を勝手に実装しない。新機能のアイデアは歓迎されるが必ず承認を取る。
- 公開(GitHub Pages/PWA)は保留中 → 手順は `.claude/skills/restep-publish` に完備。
