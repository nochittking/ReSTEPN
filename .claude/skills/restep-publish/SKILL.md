---
name: restep-publish
description: RE:STEPをGitHub Pagesに公開してiPhoneのホーム画面から遊べるようにする手順。Actionsワークフロー雛形・base-href・Pages有効化・PWAインストール・セーブデータ注意点込み。オーナーが「公開したい」「iPhoneで遊びたい」と言ったら使う。
---

# RE:STEP 公開手順(GitHub Pages / PWA)

アプリはPWA対応済み(アプリ名 RE:STEP・アイコン・テーマ色・standalone表示)。
公開 = このワークフローを1本足して Pages を有効化するだけ。

## 事前確認(必ずオーナーに伝える)

- **個人利用前提のアプリ**。公開URLは知っている人なら誰でも開ける。リポジトリが private の場合、
  GitHub Pages は有料プランでのみ使える(Free では public リポジトリのみ)。
  private のまま公開できない場合の選択肢: ①リポジトリを public にする(コードも公開になる)
  ②ビルド成果物 `app/build/web` を別の静的ホスティング(Cloudflare Pages 等)に手動アップ。
- セーブデータは localStorage(オリジン単位)。**公開URLが変わるとセーブは引き継がれない**。
  ローカル確認時のデータも公開版には引き継がれない。

## 1. ワークフローを追加

`.github/workflows/deploy.yml` を新規作成(下記そのまま使える):

```yaml
name: Deploy RE:STEP to GitHub Pages

on:
  push:
    branches: [main]   # 公開に使うブランチに合わせる
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Build web
        working-directory: app
        run: |
          flutter pub get
          flutter build web --release --no-web-resources-cdn \
            --base-href /stepn-energy-tools/
      - uses: actions/upload-pages-artifact@v3
        with:
          path: app/build/web

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

- `--base-href /stepn-energy-tools/` はリポジトリ名と一致させる(前後にスラッシュ必須)。
  リポジトリ名を変えたらここも変える。
- ローカルE2E(`python3 -m http.server`)は base-href なしのルート配信のままで良い。
  公開ビルドとローカル検証ビルドは引数が違うだけ。

## 2. Pages を有効化(オーナー作業・権限がないため必ず依頼する)

GitHub のリポジトリ → **Settings → Pages → Build and deployment → Source: GitHub Actions**。
その後、対象ブランチに push すれば Actions が走り、
`https://<owner>.github.io/stepn-energy-tools/` に公開される。

## 3. iPhone にインストール(オーナーに案内)

1. Safari で公開URLを開く
2. 共有ボタン → **「ホーム画面に追加」**
3. ホーム画面の稲妻アイコン(RE:STEP)から起動 → フルスクリーンのアプリとして動く
4. 実機ムーブは位置情報の許可が必要(初回にSafariがダイアログを出す)。
   ホーム画面では設定 → プライバシー → 位置情報 → Safari のここも確認。

## 4. 公開後の動作確認

- ホーム→シューズ→ショップが開き、初回起動でコモンのウォーカー1足+スターター・スキン4種が
  配布されること(セーブが空 = 新規開始)。
- シミュレーションモード(Web既定でON)でムーブ→リザルトまで通ること。
- アセット404が出る場合はほぼ base-href のミス。

## 更新の運用

対象ブランチに push するたびに自動で再デプロイされる。セーブデータは localStorage なので
アプリ更新では消えない(スキーマを変えるときは fromJson の移行フォールバックを必ず書く)。
