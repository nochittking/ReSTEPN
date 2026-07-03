const { chromium } = require('playwright');

const SHOT_DIR = process.env.SHOT_DIR || __dirname + '/screenshots';
require('fs').mkdirSync(SHOT_DIR, { recursive: true });

(async () => {
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
    args: ['--no-sandbox', '--ignore-certificate-errors'],
    proxy: process.env.HTTPS_PROXY
      ? {
          server: process.env.HTTPS_PROXY,
          bypass: 'localhost,127.0.0.1',
        }
      : undefined,
  });
  const page = await browser.newPage({
    viewport: { width: 420, height: 860 }, // スマホ相当の縦画面
  });

  page.on('console', (msg) => {
    if (msg.type() === 'error') console.log('[console.error]', msg.text());
  });

  await page.goto('http://localhost:8080/', { waitUntil: 'networkidle' });
  // Flutterの初回フレーム描画を待つ
  await page.waitForSelector('flutter-view', { timeout: 60000 });
  await page.waitForTimeout(4000);

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

  // 1. ホーム画面
  await shot('01-home');

  // 2. インベントリを開いてエナジー上限の計算表示を確認
  await page.getByRole('button', { name: 'インベントリ' }).click();
  await page.waitForTimeout(1500);
  await shot('02-inventory');

  // シューズを追加(擬似ミント)してエナジー上限が変わることを確認
  await page.getByRole('button', { name: /シューズを追加/ }).click();
  await page.waitForTimeout(1000);
  await shot('03-add-shoe-dialog');
  await page.getByRole('button', { name: '追加' }).click();
  await page.waitForTimeout(1000);
  await shot('04-inventory-after-add');

  // ホームへ戻る
  await page.getByRole('button', { name: /戻る|Back/ }).first().click();
  await page.waitForTimeout(1200);

  // 3. ムーブ開始(Webはデフォルトでシミュレーションモード)
  await page.getByRole('button', { name: 'ムーブ開始' }).click();
  await page.waitForTimeout(2000);
  await shot('05-move-start');

  // 10秒歩く(4.5km/h・適正レンジ内)
  await page.waitForTimeout(10000);
  await shot('06-move-earning');

  // 4. ストップ → リザルト
  await page.getByRole('button', { name: 'ストップ' }).evaluate((el) => el.click());
  await page.waitForTimeout(2000);
  await shot('07-result');

  // 5. ホームへ戻って残高反映を確認
  await page.getByRole('button', { name: 'ホームへ戻る' }).evaluate((el) => el.click());
  await page.waitForTimeout(1500);
  await shot('08-home-after');

  // 6. 履歴画面
  await page.getByRole('button', { name: '履歴' }).click();
  await page.waitForTimeout(1500);
  await shot('09-history');

  await browser.close();
  console.log('E2E done');
})().catch((e) => {
  console.error('E2E failed:', e.message);
  process.exit(1);
});
