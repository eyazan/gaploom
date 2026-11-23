// Regression test for iOS Safari touch identifiers (large, non-zero ids).
// Usage: serve build/web on :8765, then: node tools/web_ios_touch_test.js <screenshot_dir>
// Requires Playwright + Chromium. Drags the gap in level 1, taps "Next", taps "Back".
const { chromium, devices } = require('playwright');
(async () => {
  const out = process.argv[2], tid = 1234567;
  const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const ctx = await browser.newContext({ ...devices['iPhone 13'] });
  const page = await ctx.newPage();
  const logs = [];
  page.on('console', m => logs.push(m.text()));
  await page.goto('http://localhost:8765/index.html');
  for (let i = 0; i < 600 && !logs.some(l => l.includes('OpenGL API')); i++) await page.waitForTimeout(100);
  await page.waitForTimeout(2500);
  const cdp = await ctx.newCDPSession(page);
  const k = page.viewportSize().width / 720;
  const pt = (x, y, id) => [{ x: x * k, y: y * k, id, radiusX: 5, radiusY: 5, force: 1 }];
  async function tap(x, y, id) {
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: pt(x, y, id) });
    await page.waitForTimeout(80);
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await page.waitForTimeout(500);
  }
  async function drag(x0, y0, x1, y1, id) {
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: pt(x0, y0, id) });
    for (let i = 1; i <= 10; i++) {
      await page.waitForTimeout(30);
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: pt(x0 + (x1 - x0) * i / 10, y0 + (y1 - y0) * i / 10, id) });
    }
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await page.waitForTimeout(500);
  }
  await drag(230, 835, 360, 578, tid);          // level 1 by DRAG with iOS-style id
  await page.waitForTimeout(2500);
  await page.screenshot({ path: `${out}/e2e_1_solved.png` });
  await tap(475, 1103, tid + 7);                // "Next" button (GUI) with another iOS-style id
  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${out}/e2e_2_level2.png` });
  await tap(64, 75, tid + 9);                   // back button -> level select
  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${out}/e2e_3_select.png` });
  console.log(logs.filter(l => /error/i.test(l)).slice(0, 5).join('\n') || 'no console errors');
  await browser.close();
})();
