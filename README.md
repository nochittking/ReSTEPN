# STEPN Energy Tools / RE:STEP MVP

STEPNコンティンジェンシー計画のリポジトリです。

- `docs/contingency-plan-slides.html` — 5チーム体制の実行計画スライド
- `app/` — **RE:STEP MVP**(Flutter製・国内版の後継アプリプロトタイプ)
- `src/`, `public/` — 既存のReact雛形(エナジー計算ツール用・未着手)

## RE:STEP(app/)

本家STEPN風のUI・操作感を独自実装で再現したムーブアプリ(国内版・日本語UI)。
イラスト・アイコン類はすべてコード描画(CustomPaint)の自作アセットです。

### 画面構成(下部4タブ)

- **ムーブ(ホーム)** — シューズヒーローカード(スワイプ切替)/ミステリーボックス4スロット/デイリーSPゲージ/エナジーピル(回復までの残り時間表示)/スタート→3-2-1カウントダウン
- **ムーブ中** — ダーク画面。速度計ゲージ+適正レンジ、デイリーSP・エナジーの2本バー、距離大表示、一時停止/ストップ
- **リザルト** — シェアカード風(SP/分・正常計測バッジ・Km/時間/歩数・ルートイラスト)
- **シューズタブ** — シューズ/ジェム/その他の3セグメント。カードグリッド→詳細(4隅ジェムソケット・属性バー)。**レベルアップ/リペア/ミント/エンハンス/フュージョン/売却が機能実装**。ジェムはギャラリー+魔法陣の強化合成(3個→Lv+1、成功率制)
- **ランキング** — 週間/月間/全期間。自分の記録+架空プレイヤー(ローカル演出)
- **ショップ** — マーケットプレイス風。SP払いでシューズ購入(価格順・品揃え更新)

### 主なゲーム仕様

- **エナジー**: 靴の保有数で基礎エナジー(1足=2.0 / 3足=4.0 / 9足=9.0 / 15足=12.0 / 30足=20.0)+レアリティボーナス(アンコモン+1〜レジェンダリー+4)。**上限20.0ハードキャップ**。JST 4/10/16/22時に25%回復。1.0=ムーブ5分
- **獲得**: SP/分 = 基礎1.0 ×(1+効率/100)。SP/GPモードは開始前に排他選択。デイリーSP上限1000(JST4時リセット)
- **シューズ**: タイプ4種×レアリティ5段階×Lv0-30。耐久度(消費0.3/分、50未満で獲得半減、SPでリペア)
- **ジェム**: 4種(効率/幸運/快適/回復)×Lv1-5。装着で属性強化、同種同Lv3個+SPで強化合成(失敗あり)
- **ミント**: Lv5以上・ミント7回未満の親2足+SP/GPで新しい靴を生成(同レアリティ親は10%で1段上)
- **エンハンス**: 同レアリティ5足+SP/GPを合成(成功で1段上、大成功では2段階アップ。失敗はなく必ず成功して上位クラスの靴へと進化する)。レジェンダリー以外が対象
- **フュージョン**: ベース靴+同レア以下の生贄1足。生贄が上回る属性のみ [現在値以上 生贄値以下] の範囲内でランダム数値に底上げされる
- **売却**: 靴を手放してSP獲得(装着ジェムは自動で外れる)
- **ミステリーボックス**: ムーブ10分ごとに獲得判定(幸運値で上昇)。開封でジェムLv1
- **チート対策**: 瞬間移動(100m超)・不自然な速度(30km/h超)のGPSサンプル棄却
- **シミュレーションモード**: GPSなしで速度スライダー操作(開発・QA用。Webはデフォルト有効)

### 起動方法

```bash
cd app
flutter pub get
flutter test                 # 単体・統合テスト(128件)
flutter run -d chrome        # Webで起動(シミュレーションモードで動作確認可)
flutter build web --no-web-resources-cdn   # オフライン環境向けWebビルド
```

実機(Android/iOS)では実GPSで動作します(位置情報パーミッション設定済み)。
フォント(Noto Sans JP / Poppins)は `app/assets/fonts/` に同梱しており、オフラインでも表示できます。

### E2Eテスト(QAチーム向け)

```bash
cd app && flutter build web --no-web-resources-cdn
cd build/web && python3 -m http.server 8080 &
npm i playwright && node app/tool/e2e.js   # デモデータ投入済みの全画面フローを自動操作しスクショ保存
```

### 既知の制約

- 実GPSでの精度検証(都市部・トンネル等)は実機での実地テストが必要(サポートチームのテスト項目)
- 英語版UIは後回し(文字列は `app/lib/l10n/strings_ja.dart` に集約済みで移行容易)
- 転送、スクロール/バッジ、レインボー確率は「準備中」

---

# Getting Started with Create React App

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app).

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

The page will reload when you make changes.\
You may also see any lint errors in the console.

### `npm test`

Launches the test runner in the interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `npm run build`

Builds the app for production to the `build` folder.\
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.\
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

### `npm run eject`

**Note: this is a one-way operation. Once you `eject`, you can't go back!**

If you aren't satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you're on your own.

You don't have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn't feel obligated to use this feature. However we understand that this tool wouldn't be useful if you couldn't customize it when you are ready for it.

## Learn More

You can learn more in the [Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).

To learn React, check out the [React documentation](https://reactjs.org/).

### Code Splitting

This section has moved here: [https://facebook.github.io/create-react-app/docs/code-splitting](https://facebook.github.io/create-react-app/docs/code-splitting)

### Analyzing the Bundle Size

This section has moved here: [https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size](https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size)

### Making a Progressive Web App

This section has moved here: [https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app](https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app)

### Advanced Configuration

This section has moved here: [https://facebook.github.io/create-react-app/docs/advanced-configuration](https://facebook.github.io/create-react-app/docs/advanced-configuration)

### Deployment

This section has moved here: [https://facebook.github.io/create-react-app/docs/deployment](https://facebook.github.io/create-react-app/docs/deployment)

### `npm run build` fails to minify

This section has moved here: [https://facebook.github.io/create-react-app/docs/troubleshooting#npm-run-build-fails-to-minify](https://facebook.github.io/create-react-app/docs/troubleshooting#npm-run-build-fails-to-minify)
