// RE:STEP Web版のE2E動作確認スクリプト(QAチーム用)。
// 使い方: build/web を localhost:8080 で配信してから `node e2e.js`
//   CHROMIUM_PATH: Chromium実行ファイルのパス(省略時はPlaywright既定)
//   SHOT_DIR: スクリーンショット保存先(省略時は ./screenshots)
const { chromium } = require('playwright');

const SHOT_DIR = process.env.SHOT_DIR || __dirname + '/screenshots';
require('fs').mkdirSync(SHOT_DIR, { recursive: true });

// デモデータ(UI確認しやすいように残高・シューズ・ジェム等を投入)。
// shared_preferences(web)は値をJSONエンコードした文字列で保存するため二重エンコードする。
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
      { id: 'shoe-3', type: 'runner', rarity: 'epic', level: 8, durability: 100.0, mintCount: 0, serial: 45441 },
      { id: 'shoe-4', type: 'allRounder', rarity: 'legendary', level: 22, durability: 100.0, mintCount: 7, serial: 9441 },
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
  const tapRole = async (name, { nth = 0 } = {}) => {
    await page
      .getByRole('button', { name })
      .nth(nth)
      .evaluate((el) => el.click());
    await page.waitForTimeout(1200);
  };
  const tapText = async (text, { nth = 0, exact = false } = {}) => {
    await page
      .getByText(text, { exact })
      .nth(nth)
      .evaluate((el) => el.click());
    await page.waitForTimeout(1200);
  };

  // 1. ホーム
  await shot('01-home');

  // 2. スタート → 3-2-1カウントダウン → ムーブ
  await tapRole('スタート');
  await page.waitForTimeout(3200);
  await shot('02-move');
  await page.waitForTimeout(9000); // 獲得が進むのを待つ
  await shot('03-move-earning');

  // 3. ストップ → リザルト
  await tapRole('ストップ');
  await page.waitForTimeout(1500);
  await shot('04-result');
  await tapRole('ホームへ戻る');
  await shot('05-home-after');

  // 4. シューズタブ(グリッド)
  await tapRole('シューズ');
  await shot('06-sneakers');

  // 5. シューズ詳細(レジェンダリー オールラウンダー)
  await tapRole('オールラウンダー');
  await page.waitForTimeout(800);
  await shot('07-shoe-detail');

  // 6. リペアダイアログ
  await tapRole('リペア');
  await shot('08-repair');
  await tapRole('キャンセル');

  // 7. ジェムギャラリー / 強化
  await page.goBack(); // シューズ詳細から戻る
  await page.waitForTimeout(1200);
  await tapRole('ジェム');
  await shot('09-gems');
  await tapRole('強化');
  await shot('10-gem-upgrade');

  // 8. ランキング
  await tapRole('ランキング');
  await shot('11-ranking');

  // 9. ショップ
  await tapRole('ショップ');
  await shot('12-shop');

  await browser.close();
  console.log('E2E done');
})().catch((e) => {
  console.error('E2E failed:', e.message);
  process.exit(1);
});
