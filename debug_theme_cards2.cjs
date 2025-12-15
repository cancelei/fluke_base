const puppeteer = require('puppeteer');

async function run() {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
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

  // Debug: Get the raw style attribute of elements
  const debugInfo = await page.evaluate(() => {
    const card = document.querySelector('[data-theme-value="light"]');
    if (!card) return 'Card not found';

    // Get actual style attribute values
    const allDivsWithStyle = card.querySelectorAll('[style]');
    const styles = [];
    allDivsWithStyle.forEach((el, i) => {
      styles.push({
        index: i,
        tagName: el.tagName,
        styleAttr: el.getAttribute('style'),
        computedBg: window.getComputedStyle(el).backgroundColor
      });
    });

    return styles;
  });

  console.log('Style Attributes:');
  debugInfo.forEach((item, i) => {
    console.log(`\n${i}. ${item.tagName}`);
    console.log(`   style="${item.styleAttr}"`);
    console.log(`   computed bg: ${item.computedBg}`);
  });

  await browser.close();
}

run().catch(console.error);
