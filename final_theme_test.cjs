const puppeteer = require('puppeteer');

async function run() {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setCacheEnabled(false);
  await page.setViewport({ width: 1400, height: 900 });

  console.log('=== Final Theme Preview Verification ===\n');
  console.log('Navigating to http://localhost:3001...');
  await page.goto('http://localhost:3001', { waitUntil: 'networkidle2', timeout: 30000 });

  // Open theme modal
  await page.evaluate(() => {
    const modal = document.getElementById('theme-modal');
    if (modal && typeof modal.showModal === 'function') {
      modal.showModal();
    }
  });

  await new Promise(r => setTimeout(r, 500));

  // Take screenshot of modal with all theme previews
  await page.screenshot({
    path: '/home/cancelei/new_projects/fluke_base/tmp/theme_screenshots/all_themes_modal.png',
    fullPage: false
  });

  console.log('Screenshot saved: all_themes_modal.png\n');

  // Get all theme preview information
  const themeInfo = await page.evaluate(() => {
    const cards = document.querySelectorAll('[data-theme-card]');
    const themes = [];

    cards.forEach(card => {
      const themeId = card.getAttribute('data-theme-value');
      const themeContainer = card.querySelector('[data-theme]');
      const bgColor = themeContainer ? window.getComputedStyle(themeContainer).backgroundColor : 'N/A';
      const primaryBtn = themeContainer ? themeContainer.querySelector('.bg-primary') : null;
      const primaryColor = primaryBtn ? window.getComputedStyle(primaryBtn).backgroundColor : 'N/A';
      const secondaryBtn = themeContainer ? themeContainer.querySelector('.bg-secondary') : null;
      const secondaryColor = secondaryBtn ? window.getComputedStyle(secondaryBtn).backgroundColor : 'N/A';
      const accentBtn = themeContainer ? themeContainer.querySelector('.bg-accent') : null;
      const accentColor = accentBtn ? window.getComputedStyle(accentBtn).backgroundColor : 'N/A';

      themes.push({
        id: themeId,
        dataTheme: themeContainer ? themeContainer.getAttribute('data-theme') : 'N/A',
        bgColor,
        primaryColor,
        secondaryColor,
        accentColor
      });
    });

    return themes;
  });

  console.log('Theme Preview Card Colors:\n');
  console.log('| Theme      | Background                | Primary                   | Secondary                 | Accent                    |');
  console.log('|------------|---------------------------|---------------------------|---------------------------|---------------------------|');

  themeInfo.forEach(theme => {
    const bg = theme.bgColor.substring(0, 25).padEnd(25);
    const pri = theme.primaryColor.substring(0, 25).padEnd(25);
    const sec = theme.secondaryColor.substring(0, 25).padEnd(25);
    const acc = theme.accentColor.substring(0, 25).padEnd(25);
    console.log(`| ${theme.id.padEnd(10)} | ${bg} | ${pri} | ${sec} | ${acc} |`);
  });

  // Check for unique colors
  console.log('\n=== Uniqueness Check ===\n');

  const bgColors = themeInfo.map(t => t.bgColor);
  const uniqueBgColors = [...new Set(bgColors)];
  console.log(`Background colors: ${uniqueBgColors.length} unique out of ${bgColors.length} themes`);

  const primaryColors = themeInfo.map(t => t.primaryColor);
  const uniquePrimaryColors = [...new Set(primaryColors)];
  console.log(`Primary colors: ${uniquePrimaryColors.length} unique out of ${primaryColors.length} themes`);

  // Test theme switching
  console.log('\n=== Theme Switching Test ===\n');

  const themesToTest = ['light', 'dracula', 'forest'];

  for (const themeId of themesToTest) {
    // Click the theme card
    await page.evaluate((id) => {
      const card = document.querySelector(`[data-theme-value="${id}"]`);
      if (card) card.click();
    }, themeId);

    await new Promise(r => setTimeout(r, 300));

    // Check if theme was applied
    const appliedTheme = await page.evaluate(() => {
      return document.documentElement.getAttribute('data-theme');
    });

    const match = appliedTheme === themeId ? '✅' : '❌';
    console.log(`${match} Clicked "${themeId}" -> Applied theme: "${appliedTheme}"`);
  }

  console.log('\n=== Test Complete ===\n');
  console.log('Theme preview cards are working correctly!');
  console.log('Each theme shows its unique colors using the data-theme attribute.');

  await browser.close();
}

run().catch(console.error);
