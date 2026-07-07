---
name: restep-verify
description: RE:STEPの変更を analyze→test→build→E2Eスクショ で通し検証する手順。Flutter Webセマンティクスの罠(結果ダイアログ・同名ボタン・シードの二重エンコード)と回避策込み。コード変更後の検証、スクショ提示、アイコン再生成のときに使う。
---

# RE:STEP 検証ループ

コード変更後は必ずこの順で全通しする。途中で失敗したら先に直してから次へ。

## 1. 静的解析とテスト

```bash
cd app
/opt/flutter/bin/flutter analyze    # "No issues found!" 必須
/opt/flutter/bin/flutter test       # 全パス必須(2026-07時点で87件)
```

- 確率もののテストは `_FixedRandom implements Random`(nextDouble固定値・nextInt=0・nextBool=true)
  で境界を決め打ちする。例: クリティカル判定は r=0.04→×3 / r=0.24→×2 / r=0.30→×1。
- 数値変更をしたら、その式をそのまま検算するテスト(期待値をコメントに書く)を必ず更新する。

## 2. Webビルド

```bash
/opt/flutter/bin/flutter build web --no-web-resources-cdn
```

## 3. E2Eスクショ通し

```bash
# 初回のみ: Playwrightを入れる(ブラウザはDLしない。/opt/pw-browsers/chromium を使う)
cd app/tool && PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm install --no-save playwright

# 配信 + 実行
python3 -m http.server 8080 -d ../build/web &   # ルート配信でOK(base-href不要)
rm -rf screenshots
CHROMIUM_PATH=/opt/pw-browsers/chromium node e2e.js
```

- `tool/e2e.js` がシード投入→全画面操作→ `tool/screenshots/` に連番PNGを保存する。
- 出力の `(skip tap: ...)` は操作失敗のサイン。**skipゼロが合格ライン**。
- 撮れたスクショのうち変更に関係する画面を SendUserFile でオーナーに見せる。
- 新しい画面・ダイアログを追加したら e2e.js に撮影ステップを足す。

## Flutter Webセマンティクスの罠(実測済み・重要)

1. **起動直後は `flt-semantics-placeholder` をクリック**してセマンティクスを有効化する
   (e2e.jsは対応済み)。タップは `getByRole('button', {name}).evaluate(el => el.click())`。
2. **「OK」だけの結果ダイアログが表示されている間、セマンティクスツリーが更新されない**
   (ノードが数個に崩壊し全ボタンが見えなくなる)。視覚描画と実タッチは正常なので
   **実機プレイには無影響**。E2Eでは `dismissDialog()`(Escキー)で閉じる。
   閉じた瞬間にツリーは完全復活する。
3. **同名ボタン問題**: 下部タブ「シューズ」とセグメント「シューズ」など同名が並ぶ画面では
   nth が安定しない。`tapRole('シューズ')` と `tapRole('シューズ', {nth:1})` を両方叩く
   (片方はno-op)。
4. **シードデータは二重JSONエンコード**: shared_preferences(web) は json.encode 済み文字列を
   期待するため `localStorage.setItem('flutter.<key>', JSON.stringify(JSON.stringify(obj)))`。
5. シードのインベントリは旧形式(attrs無し)のままにしてある = 移行パスの回帰確認を兼ねる。
6. GestureDetectorボタンのアクセシブル名はテキスト内容から決まる。アイコンのみのボタンは
   名前が無く role で掴めない → 撮影だけで済ませるか Semantics ラベルを付ける。

## アイコン再生成(ブランド変更時のみ)

```bash
cd app/tool && CHROMIUM_PATH=/opt/pw-browsers/chromium node make_icons.js
# web/icons/Icon-{192,512}.png / Icon-maskable-* / web/favicon.png を上書きする
```

モチーフは靴かかとの稲妻バッジ(sneaker_art.dart の `_drawBolt` と同じ頂点列)。

## 4. 仕上げ

- `git add -A` → 日本語のコミットメッセージでコミット → 指定ブランチへ `git push -u origin <branch>`。
- 変更した数値・仕様の「変更前→変更後」表をオーナーへの報告に含める。
