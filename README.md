# STEPN Energy Tools / RE:STEP MVP

STEPNコンティンジェンシー計画のリポジトリです。

- `docs/contingency-plan-slides.html` — 5チーム体制の実行計画スライド
- `app/` — **RE:STEP MVP**(Flutter製・国内版の後継アプリプロトタイプ)
- `src/`, `public/` — 既存のReact雛形(エナジー計算ツール用・未着手)

## RE:STEP MVP(app/)

現行STEPNと同等の操作感を独自実装で再現したムーブアプリのMVPです。

### 主な仕様(本家準拠・リサーチ済み)

- **エナジー**: 靴の保有数で基礎エナジーが決まり(1足=2.0 / 3足=4.0 / 9足=9.0 / 15足=12.0 / 30足=20.0)、レアリティボーナス(アンコモン+1 / レア+2 / エピック+3 / レジェンダリー+4)を合算。**上限は20.0でハードキャップ**。日本時間 4時/10時/16時/22時 に上限の25%ずつ回復。エナジー1.0=ムーブ5分(毎分0.2消費)
- **報酬モード**: SP(ステップポイント)/ GP(ガバナンスポイント)。ムーブ開始前にどちらか一方を選択(同時獲得不可)。当面はオフチェーンポイント(法務判定までトークン化しない)
- **シューズ**: タイプ4種(ウォーカー1–6km/h / ジョガー4–10 / ランナー8–20 / オールラウンダー1–20)× レアリティ5段階
- **チート対策(基本)**: 瞬間移動(サンプル間100m超)・不自然な速度(30km/h超)のGPSサンプルを棄却
- **シミュレーションモード**: GPSなしで速度を模擬できる開発・QA用モード(Webはデフォルトで有効)

### 起動方法

```bash
cd app
flutter pub get
flutter test                 # 単体・統合テスト(30件)
flutter run -d chrome        # Webで起動(シミュレーションモードで動作確認可)
flutter build web --no-web-resources-cdn   # オフライン環境向けWebビルド
```

実機(Android/iOS)では実GPSで動作します(位置情報パーミッション設定済み)。
日本語フォント(Noto Sans JP)は `app/assets/fonts/` に同梱しており、オフラインでも表示できます。

### E2Eテスト(QAチーム向け)

```bash
cd app && flutter build web --no-web-resources-cdn
cd build/web && python3 -m http.server 8080 &
npm i playwright && node app/tool/e2e.js   # スクリーンショットを app/tool/screenshots/ に保存
```

### 既知の制約

- 実GPSでの精度検証(都市部・トンネル等)は実機での実地テストが必要(サポートチームのテスト項目)
- 英語版UIは後回し(文字列は `app/lib/l10n/strings_ja.dart` に集約済みで移行容易)

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
