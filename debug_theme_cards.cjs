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

  // Debug: Get dimensions and visibility of first card's content
  const debugInfo = await page.evaluate(() => {
    const card = document.querySelector('[data-theme-value="light"]');
    if (!card) return 'Card not found';

    const cardRect = card.getBoundingClientRect();
    
    // Find all child divs with inline styles
    const coloredElements = card.querySelectorAll('div[style*="background-color"]');
    
    const elements = [];
    coloredElements.forEach((el, i) => {
      const rect = el.getBoundingClientRect();
      const styles = window.getComputedStyle(el);
      elements.push({
        index: i,
        bgColor: styles.backgroundColor,
        width: rect.width,
        height: rect.height,
        visible: rect.width > 0 && rect.height > 0,
        display: styles.display,
        visibility: styles.visibility,
        opacity: styles.opacity
      });
    });

    return {
      cardDimensions: { width: cardRect.width, height: cardRect.height },
      childElements: elements
    };
  });

  console.log('Debug Info:');
  console.log(JSON.stringify(debugInfo, null, 2));

  await browser.close();
}

run().catch(console.error);
