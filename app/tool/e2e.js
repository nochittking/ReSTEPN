// RE:STEP Web版のE2E動作確認スクリプト(QAチーム用)。
// 使い方: build/web を localhost:8080 で配信してから `node e2e.js`
//   CHROMIUM_PATH: Chromium実行ファイルのパス(省略時はPlaywright既定)
//   SHOT_DIR: スクリーンショット保存先(省略時は ./screenshots)
const { chromium } = require('playwright');

const SHOT_DIR = process.env.SHOT_DIR || __dirname + '/screenshots';
require('fs').mkdirSync(SHOT_DIR, { recursive: true });

// デモデータ(UI確認しやすいように残高・シューズ・ジェム等を投入)。
// shared_preferences(web)は値をJSONエンコードした文字列で保存するため二重エンコードする。
// インベントリは旧形式(attrs無し)のまま=旧データ移行パスの動作確認を兼ねる。
function buildSeed() {
  const now = new Date();
  const iso = now.toISOString();
  const daysAgo = (d) => new Date(now.getTime() - d * 86400000).toISOString();
  // AppState.dayKeyForと同じ計算(JST4:00境界)
  const jst = new Date(now.getTime() + 9 * 3600000);
  const shifted = new Date(jst.getTime() - 4 * 3600000);
  const dayKey = `${shifted.getUTCFullYear()}-${shifted.getUTCMonth() + 1}-${shifted.getUTCDate()}`;

  const data = {
    'restep.balances': { sp: 4921.31, gp: 1578.89 },
    'restep.inventory': [
      { id: 'shoe-initial', type: 'walker', rarity: 'common', level: 5, durability: 95.0, mintCount: 0, serial: 778894978 },
      { id: 'shoe-2', type: 'jogger', rarity: 'rare', level: 12, durability: 88.5, mintCount: 2, serial: 311458571 },
      // Lv9 = 次のレベルアップが節目Lv10(費用3倍+GP・ポイント2倍)
      { id: 'shoe-3', type: 'runner', rarity: 'epic', level: 9, durability: 100.0, mintCount: 0, serial: 45441 },
      { id: 'shoe-4', type: 'allRounder', rarity: 'legendary', level: 22, durability: 100.0, mintCount: 7, serial: 9441 },
      { id: 'shoe-5', type: 'walker', rarity: 'common', level: 2, durability: 100.0, mintCount: 0, serial: 605516131 },
      { id: 'shoe-6', type: 'jogger', rarity: 'common', level: 0, durability: 100.0, mintCount: 0, serial: 21466847 },
      { id: 'shoe-7', type: 'runner', rarity: 'common', level: 1, durability: 100.0, mintCount: 0, serial: 53598989 },
      { id: 'shoe-8', type: 'walker', rarity: 'common', level: 6, durability: 100.0, mintCount: 1, serial: 72132079 },
    ],
    'restep.gems': [
      { id: 'gem-e1', type: 'efficiency', level: 1, equippedShoeId: null },
      { id: 'gem-e2', type: 'efficiency', level: 1, equippedShoeId: null },
      { id: 'gem-e3', type: 'efficiency', level: 1, equippedShoeId: null },
      { id: 'gem-e4', type: 'efficiency', level: 1, equippedShoeId: null },
      { id: 'gem-e5', type: 'efficiency', level: 2, equippedShoeId: 'shoe-4' },
      { id: 'gem-l1', type: 'luck', level: 1, equippedShoeId: null },
      { id: 'gem-l2', type: 'luck', level: 1, equippedShoeId: null },
      { id: 'gem-l3', type: 'luck', level: 1, equippedShoeId: null },
      { id: 'gem-c1', type: 'comfort', level: 1, equippedShoeId: null },
      { id: 'gem-r1', type: 'resilience', level: 1, equippedShoeId: null },
    ],
    // 半額セール品(掘り出し物)入りのショップカタログ
    'restep.shop': [
      {
        shoe: { id: 'shop-1', type: 'walker', rarity: 'common', level: 1, durability: 100.0, mintCount: 0, serial: 33018274, attrs: { efficiency: 6.2, luck: 4.1, comfort: 8.8, resilience: 3.5 } },
        priceSp: 103.9, onSale: false,
      },
      {
        shoe: { id: 'shop-2', type: 'runner', rarity: 'epic', level: 3, durability: 100.0, mintCount: 0, serial: 90781263, attrs: { efficiency: 38.2, luck: 29.1, comfort: 33.5, resilience: 27.8 } },
        priceSp: 570.2, onSale: true, // 元値1140.4の掘り出し物
      },
      {
        shoe: { id: 'shop-3', type: 'jogger', rarity: 'uncommon', level: 0, durability: 100.0, mintCount: 0, serial: 55103377, attrs: { efficiency: 15.3, luck: 9.9, comfort: 12.4, resilience: 16.7 } },
        priceSp: 246.5, onSale: false,
      },
      {
        shoe: { id: 'shop-4', type: 'allRounder', rarity: 'rare', level: 2, durability: 100.0, mintCount: 0, serial: 71442905, attrs: { efficiency: 22.6, luck: 18.3, comfort: 25.1, resilience: 20.9 } },
        priceSp: 553.4, onSale: false,
      },
    ],
    'restep.boxes': [
      { id: 'box-1', obtainedAt: iso },
      { id: 'box-2', obtainedAt: iso },
    ],
    'restep.sessions': [
      { startedAt: daysAgo(1), endedAt: daysAgo(1), mode: 'sp', shoeName: 'レア ジョガー', distanceMeters: 5530, durationSeconds: 2069, earnedPoints: 313.22, consumedEnergy: 6.8, consumedDurability: 9.2, boxesObtained: 1, rejectedSamples: 0 },
      { startedAt: daysAgo(3), endedAt: daysAgo(3), mode: 'sp', shoeName: 'コモン ウォーカー', distanceMeters: 3200, durationSeconds: 1800, earnedPoints: 152.4, consumedEnergy: 6.0, consumedDurability: 8.1, boxesObtained: 0, rejectedSamples: 0 },
      { startedAt: daysAgo(12), endedAt: daysAgo(12), mode: 'gp', shoeName: 'エピック ランナー', distanceMeters: 8100, durationSeconds: 2400, earnedPoints: 96.1, consumedEnergy: 8.0, consumedDurability: 10.4, boxesObtained: 1, rejectedSamples: 0 },
    ],
    'restep.energy': { energy: 20.0, lastUpdateUtc: iso },
    'restep.profile': { name: 'nochittking', totalKm: 22736.0 },
    'restep.daily': { dayKey: dayKey, sp: 601.2 },
    // restep.skins はシードしない=初回スターター配布の動作確認
  };

  let script = '';
  for (const [key, value] of Object.entries(data)) {
    // アプリが読むペイロード文字列PをJS文字列リテラルとして埋め込み、
    // 実行時に JSON.stringify(P) でクオート付きにして保存する
    // (shared_preferences webは json.encode された値を期待するため)。
    const payloadLiteral = JSON.stringify(JSON.stringify(value));
    script += `localStorage.setItem('flutter.${key}', JSON.stringify(${payloadLiteral}));\n`;
  }
  return script;
}

(async () => {
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
    args: ['--no-sandbox', '--ignore-certificate-errors'],
    proxy: process.env.HTTPS_PROXY
      ? { server: process.env.HTTPS_PROXY, bypass: 'localhost,127.0.0.1' }
      : undefined,
  });
  const page = await browser.newPage({
    viewport: { width: 420, height: 880 }, // スマホ相当の縦画面
  });

  page.on('console', (msg) => {
    if (msg.type() === 'error') console.log('[console.error]', msg.text());
  });

  await page.addInitScript(buildSeed());

  await page.goto('http://localhost:8080/', { waitUntil: 'networkidle' });
  await page.waitForSelector('flutter-view', { timeout: 60000 });
  await page.waitForTimeout(4500);

  // セマンティクスを有効化してDOM経由で操作できるようにする
  const placeholder = page.locator('flt-semantics-placeholder');
  if (await placeholder.count()) {
    await placeholder.first().evaluate((el) => el.click());
    await page.waitForTimeout(1500);
  }

  const shot = async (name) => {
    await page.screenshot({ path: `${SHOT_DIR}/${name}.png` });
    console.log('screenshot:', name);
  };
  const tapRole = async (name, { nth = 0, exact = false } = {}) => {
    try {
      await page
        .getByRole('button', { name, exact })
        .nth(nth)
        .evaluate((el) => el.click(), { timeout: 8000 });
    } catch (e) {
      console.log('  (skip tap:', name, ')');
    }
    await page.waitForTimeout(1000);
  };
  const tapRoleLast = async (name, { exact = false } = {}) => {
    try {
      await page
        .getByRole('button', { name, exact })
        .last()
        .evaluate((el) => el.click(), { timeout: 8000 });
    } catch (e) {
      console.log('  (skip tapLast:', name, ')');
    }
    await page.waitForTimeout(1000);
  };
  const tapText = async (text, { nth = 0, exact = false } = {}) => {
    try {
      await page
        .getByText(text, { exact })
        .nth(nth)
        .evaluate((el) => el.click(), { timeout: 8000 });
    } catch (e) {
      console.log('  (skip tapText:', text, ')');
    }
    await page.waitForTimeout(1200);
  };

  // 1. ホーム(ヒーローカード)
  await shot('01-home');

  // 2. スタート → 3-2-1カウントダウン → ムーブ → リザルト
  await tapRole('スタート');
  await page.waitForTimeout(3200);
  await shot('02-move');
  await page.waitForTimeout(9000); // 獲得が進むのを待つ
  await shot('03-move-earning');
  await tapRole('ストップ');
  await page.waitForTimeout(1500);
  await shot('04-result');
  await tapRole('ホームへ戻る');
  await shot('05-home-after');

  // 3. シューズタブ(グリッド)
  await tapRole('シューズ');
  await shot('06-sneakers');

  // 4. シューズ詳細(エピック ランナー Lv9): スキンスロット+属性+アクションバー
  await tapRole('エピック ランナー');
  await page.waitForTimeout(800);
  await shot('07-shoe-detail');

  // 5. 節目レベルアップ(Lv9→10): 費用3倍+GP・ポイント2倍の警告
  await tapRole('レベルアップ');
  await page.waitForTimeout(800);
  await shot('08-levelup-milestone');
  await tapRole('決定');
  await page.waitForTimeout(1200);
  await shot('09-levelup-result'); // クリティカル演出(出目のまま撮影)
  await tapRoleLast('OK');
  await page.waitForTimeout(800);
  await shot('10-detail-points'); // 未割り当てポイントのバナー

  // 6. スキン装着: ピッカー → オーロラ装着で見た目が変わる
  await tapText('スキン未装着(元の見た目)');
  await page.waitForTimeout(800);
  await shot('11-skin-picker');
  await tapText('オーロラ');
  await page.waitForTimeout(1000);
  await shot('12-detail-skinned');

  // 7. その他タブ = スキン一覧(装着状況)
  await page.goBack();
  await page.waitForTimeout(1200);
  await shot('13-grid-skinned');
  await tapRole('その他');
  await page.waitForTimeout(800);
  await shot('14-skins-gallery');

  // 8. ミント(レア ジョガー Lv12 mint2 を親に): 消滅%/双子%チップ
  await tapRole('シューズ', { nth: 1 }); // セグメントを「シューズ」に戻す
  await page.waitForTimeout(800);
  await tapRole('レア ジョガー');
  await page.waitForTimeout(800);
  await tapRole('ミント', { exact: true });
  await page.waitForTimeout(1000);
  await shot('15-mint');
  await tapRole('相方のシューズを選択');
  await page.waitForTimeout(800);
  await shot('16-mint-picker');
  await tapRole('候補 コモン ウォーカー');
  await tapRole('決定');
  await page.waitForTimeout(800);
  await shot('17-mint-odds'); // 消滅リスク・双子確率の事前表示
  await tapRoleLast('ミント', { exact: true });
  await page.waitForTimeout(1500);
  await shot('18-mint-result');
  await tapRoleLast('OK');
  await page.waitForTimeout(800);
  await tapRole('戻る'); // ミント画面から詳細へ
  await page.waitForTimeout(600);
  await page.goBack(); // 詳細からシューズタブへ
  await page.waitForTimeout(800);

  // 9. フュージョン(ベース+生贄で属性底上げ)
  await tapRole('コモン ウォーカー');
  await page.waitForTimeout(800);
  await tapRole('フュージョン', { exact: true });
  await page.waitForTimeout(1000);
  await tapText('生贄の靴を選択');
  await page.waitForTimeout(800);
  await tapRole('生贄 コモン ウォーカー');
  await page.waitForTimeout(800);
  await shot('19-fusion-preview'); // 属性表(底上げ範囲は緑)
  await tapRoleLast('フュージョン', { exact: true });
  await page.waitForTimeout(1500);
  await shot('20-fusion-result');
  await tapRoleLast('OK');
  await page.waitForTimeout(800);
  await tapRole('戻る'); // フュージョン画面から詳細へ
  await page.waitForTimeout(600);

  // 10. エンハンス(同レア5足→上位挑戦)
  await tapRole('エンハンス', { exact: true });
  await page.waitForTimeout(1000);
  for (let i = 0; i < 5; i++) {
    await tapRole('素材', { nth: i });
  }
  await shot('21-enhance');
  await tapRoleLast('エンハンス', { exact: true });
  await page.waitForTimeout(800);
  await shot('22-enhance-confirm');
  await tapRole('決定');
  await page.waitForTimeout(1500);
  await shot('23-enhance-result');
  await tapRoleLast('OK');
  await page.waitForTimeout(800);

  // 11. ジェム / ランキング
  await tapRole('戻る'); // エンハンス画面からタブへ
  await page.waitForTimeout(800);
  await tapRole('ジェム');
  await shot('24-gems');
  await tapRole('強化');
  await shot('25-gem-upgrade');
  await tapRole('ランキング');
  await shot('26-ranking');

  // 12. ショップ(SALEピル+取り消し線の元値)
  await tapRole('ショップ');
  await page.waitForTimeout(800);
  await shot('27-shop-sale');

  await browser.close();
  console.log('E2E done');
})().catch((e) => {
  console.error('E2E failed:', e.message);
  process.exit(1);
});
