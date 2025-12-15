const puppeteer = require('puppeteer');

async function run() {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();

  // Collect all console messages and errors
  const consoleMessages = [];
  const cspViolations = [];

  page.on('console', msg => {
    consoleMessages.push({type: msg.type(), text: msg.text()});
  });

  page.on('pageerror', error => {
    consoleMessages.push({type: 'error', text: error.message});
  });

  // Listen for security policy violations
  await page.evaluateOnNewDocument(() => {
    document.addEventListener('securitypolicyviolation', (e) => {
      console.log('CSP VIOLATION:', e.violatedDirective, e.blockedURI);
    });
  });

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

  // Print console messages
  console.log('\n=== Console Messages ===');
  consoleMessages.forEach(msg => {
    console.log(msg.type + ': ' + msg.text);
  });

  // Direct debug of inline styles
  const debugInfo = await page.evaluate(() => {
    const el = document.querySelector('[data-theme-value="light"] .flex-1.h-6');
    if (!el) return 'Element not found';

    return {
      styleAttr: el.getAttribute('style'),
      computedBg: window.getComputedStyle(el).backgroundColor,
      cssText: el.style.cssText,
      bgProperty: el.style.backgroundColor,
      bgPriority: el.style.getPropertyPriority('background-color')
    };
  });

  console.log('\n=== Style Debug ===');
  console.log(JSON.stringify(debugInfo, null, 2));

  await browser.close();
}

run().catch(console.error);
