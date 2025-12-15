const puppeteer = require('puppeteer');

async function run() {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();

  // Disable cache
  await page.setCacheEnabled(false);

  await page.setViewport({ width: 1400, height: 900 });

  console.log('Navigating to http://localhost:3001...');
  await page.goto('http://localhost:3001', { waitUntil: 'networkidle2', timeout: 30000 });

  // Open theme modal
  await page.evaluate(() => {
    const modal = document.getElementById('theme-modal');
    if (modal && typeof modal.showModal === 'function') {
      modal.showModal();
    }
  });

  await new Promise(r => setTimeout(r, 1000));

  // Take screenshot
  await page.screenshot({
    path: '/home/cancelei/new_projects/fluke_base/tmp/theme_screenshots/fresh_modal.png',
    fullPage: false
  });

  console.log('Screenshot saved!');

  // Also get the HTML of the first card
  const cardHtml = await page.evaluate(() => {
    const card = document.querySelector('[data-theme-value="light"]');
    return card ? card.outerHTML.substring(0, 500) : 'Card not found';
  });
  console.log('First card HTML preview:', cardHtml);

  await browser.close();
}

run().catch(console.error);
