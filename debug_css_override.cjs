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

  // Use DevTools Protocol to get CSS rules
  const client = await page.target().createCDPSession();
  await client.send('DOM.enable');
  await client.send('CSS.enable');

  // Get the first colored div
  const nodeFound = await page.evaluate(() => {
    const el = document.querySelector('[data-theme-value="light"] div[style*="background-color: #570df8"]');
    if (!el) return false;
    // Mark it for later retrieval
    el.id = '__debug_target__';
    return true;
  });

  if (nodeFound) {
    // Get document and find the node
    const doc = await client.send('DOM.getDocument');
    const searchResult = await client.send('DOM.performSearch', { query: '#__debug_target__' });

    if (searchResult.resultCount > 0) {
      const nodeIds = await client.send('DOM.getSearchResults', {
        searchId: searchResult.searchId,
        fromIndex: 0,
        toIndex: 1
      });

      const targetNodeId = nodeIds.nodeIds[0];

      // Get matched styles for this node
      const matchedStyles = await client.send('CSS.getMatchedStylesForNode', { nodeId: targetNodeId });

      console.log('\n=== Matched CSS Rules ===');

      // Look at inherited and matched rules
      if (matchedStyles.matchedCSSRules) {
        matchedStyles.matchedCSSRules.forEach((rule, i) => {
          const selector = rule.rule.selectorList ? rule.rule.selectorList.selectors.map(s => s.text).join(', ') : 'unknown';
          const props = rule.rule.style ? rule.rule.style.cssProperties : [];
          const bgProp = props.find(p => p.name === 'background-color' || p.name === 'background');
          if (bgProp) {
            console.log('\nRule ' + i + ': ' + selector);
            console.log('  ' + bgProp.name + ': ' + bgProp.value);
            console.log('  Important: ' + (bgProp.important ? 'YES' : 'no'));
          }
        });
      }

      // Check inline styles
      if (matchedStyles.inlineStyle) {
        console.log('\n=== Inline Style ===');
        matchedStyles.inlineStyle.cssProperties.forEach(prop => {
          console.log('  ' + prop.name + ': ' + prop.value);
        });
      }
    }
  } else {
    console.log('Target element not found');
  }

  await browser.close();
}

run().catch(console.error);
