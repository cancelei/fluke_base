const puppeteer = require('puppeteer');

const THEMES = {
  light: ['light', 'nord', 'cupcake', 'emerald', 'corporate'],
  dark: ['dark', 'night', 'dracula', 'forest', 'business']
};

async function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function getComputedColors(page) {
  return await page.evaluate(() => {
    const html = document.documentElement;
    const computedStyle = getComputedStyle(html);

    const getColor = (prop) => {
      const value = computedStyle.getPropertyValue(prop).trim();
      return value;
    };

    return {
      theme: html.getAttribute('data-theme'),
      base100: getColor('--b1'),
      base200: getColor('--b2'),
      baseContent: getColor('--bc'),
      primary: getColor('--p'),
      secondary: getColor('--s'),
      accent: getColor('--a'),
      neutral: getColor('--n'),
      bodyBg: getComputedStyle(document.body).backgroundColor
    };
  });
}

async function testThemeSwitching(page, themeName) {
  console.log(`\n--- Testing theme: ${themeName} ---`);

  const themeCard = await page.$(`[data-theme-value="${themeName}"]`);
  if (!themeCard) {
    console.log(`  ❌ Theme card not found for: ${themeName}`);
    return { theme: themeName, success: false, error: 'Card not found' };
  }

  await themeCard.click();
  await delay(500);

  const colors = await getComputedColors(page);

  console.log(`  Current theme attribute: ${colors.theme}`);
  console.log(`  Primary color: ${colors.primary}`);
  console.log(`  Base-100 (bg): ${colors.base100}`);
  console.log(`  Body background: ${colors.bodyBg}`);

  const themeApplied = colors.theme === themeName;
  console.log(`  Theme applied correctly: ${themeApplied ? '✅' : '❌'}`);

  const hasColors = colors.primary && colors.primary.length > 0;
  console.log(`  Has theme colors: ${hasColors ? '✅' : '❌'}`);

  return {
    theme: themeName,
    success: themeApplied && hasColors,
    colors: colors
  };
}

async function captureThemeScreenshot(page, themeName, screenshotDir) {
  const screenshotPath = `${screenshotDir}/${themeName}.png`;
  await page.screenshot({ path: screenshotPath, fullPage: false });
  console.log(`  Screenshot saved: ${screenshotPath}`);
}

async function testThemePreviewCards(page) {
  console.log('\n=== Testing Theme Preview Cards in Modal ===\n');

  const previewCards = await page.$$eval('[data-theme-card]', cards => {
    return cards.map(card => {
      const themeValue = card.dataset.themeValue;
      const previewDiv = card.querySelector('[data-theme]');
      const previewTheme = previewDiv ? previewDiv.getAttribute('data-theme') : null;

      let previewBg = '';
      let primaryBtnBg = '';
      let secondaryBtnBg = '';
      let accentBtnBg = '';

      if (previewDiv) {
        const style = getComputedStyle(previewDiv);
        previewBg = style.backgroundColor;

        const primaryBtn = previewDiv.querySelector('.btn-primary');
        const secondaryBtn = previewDiv.querySelector('.btn-secondary');
        const accentBtn = previewDiv.querySelector('.btn-accent');

        if (primaryBtn) primaryBtnBg = getComputedStyle(primaryBtn).backgroundColor;
        if (secondaryBtn) secondaryBtnBg = getComputedStyle(secondaryBtn).backgroundColor;
        if (accentBtn) accentBtnBg = getComputedStyle(accentBtn).backgroundColor;
      }

      return {
        themeValue,
        previewTheme,
        matches: themeValue === previewTheme,
        previewBg,
        primaryBtnBg,
        secondaryBtnBg,
        accentBtnBg
      };
    });
  });

  console.log('Preview Card Analysis:');
  previewCards.forEach(card => {
    const status = card.matches ? '✅' : '❌';
    console.log(`  ${status} ${card.themeValue}:`);
    console.log(`      data-theme="${card.previewTheme}"`);
    console.log(`      Preview BG: ${card.previewBg}`);
    console.log(`      Primary BTN: ${card.primaryBtnBg}`);
    console.log(`      Secondary BTN: ${card.secondaryBtnBg}`);
    console.log(`      Accent BTN: ${card.accentBtnBg}`);
  });

  // Check for duplicate backgrounds
  console.log('\n=== Checking for themes with identical backgrounds ===');
  const bgGroups = {};
  previewCards.forEach(card => {
    const key = card.previewBg;
    if (!bgGroups[key]) bgGroups[key] = [];
    bgGroups[key].push(card.themeValue);
  });

  Object.entries(bgGroups).forEach(([bg, themes]) => {
    if (themes.length > 1) {
      console.log(`  ⚠️  Same BG "${bg}": ${themes.join(', ')}`);
    }
  });

  // Check for duplicate primary button colors
  console.log('\n=== Checking for themes with identical primary buttons ===');
  const primaryGroups = {};
  previewCards.forEach(card => {
    const key = card.primaryBtnBg;
    if (!primaryGroups[key]) primaryGroups[key] = [];
    primaryGroups[key].push(card.themeValue);
  });

  Object.entries(primaryGroups).forEach(([color, themes]) => {
    if (themes.length > 1) {
      console.log(`  ⚠️  Same Primary "${color}": ${themes.join(', ')}`);
    }
  });

  return previewCards;
}

async function run() {
  console.log('=== DaisyUI Theme Verification Test ===\n');

  const fs = require('fs');
  const screenshotDir = '/home/cancelei/new_projects/fluke_base/tmp/theme_screenshots';
  if (!fs.existsSync(screenshotDir)) {
    fs.mkdirSync(screenshotDir, { recursive: true });
  }

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1400, height: 900 });

  try {
    // Navigate to root - landing page has full layout with theme modal
    console.log('Navigating to http://localhost:3001...');
    await page.goto('http://localhost:3001', { waitUntil: 'networkidle2', timeout: 30000 });

    const initialColors = await getComputedColors(page);
    console.log(`Initial theme: ${initialColors.theme}`);
    console.log(`Initial primary color: ${initialColors.primary}`);

    await page.screenshot({ path: `${screenshotDir}/00_initial.png` });

    // Open theme modal via JavaScript
    console.log('\nOpening theme modal...');
    await page.evaluate(() => {
      const modal = document.getElementById('theme-modal');
      if (modal && typeof modal.showModal === 'function') {
        modal.showModal();
      }
    });
    await delay(500);

    const modalOpen = await page.evaluate(() => {
      const modal = document.getElementById('theme-modal');
      return modal && modal.open;
    });
    console.log(`Modal is open: ${modalOpen ? '✅' : '❌'}`);

    await page.screenshot({ path: `${screenshotDir}/01_modal_open.png` });

    if (!modalOpen) {
      const modalExists = await page.$('#theme-modal');
      console.log(`Modal element exists: ${modalExists ? 'Yes' : 'No'}`);

      const cards = await page.$$('[data-theme-card]');
      console.log(`Theme cards found on page: ${cards.length}`);

      if (cards.length === 0) {
        console.log('\nChecking page HTML for theme elements...');
        const hasModal = await page.evaluate(() => document.body.innerHTML.includes('theme-modal'));
        const hasCards = await page.evaluate(() => document.body.innerHTML.includes('data-theme-card'));
        console.log(`Page has theme-modal: ${hasModal}`);
        console.log(`Page has data-theme-card: ${hasCards}`);
      }
    }

    // Test preview cards
    await testThemePreviewCards(page);

    // Test each theme
    const results = [];
    const allThemes = [...THEMES.light, ...THEMES.dark];

    for (const theme of allThemes) {
      const result = await testThemeSwitching(page, theme);
      results.push(result);
      await captureThemeScreenshot(page, theme, screenshotDir);
      await delay(300);
    }

    // Summary
    console.log('\n=== SUMMARY ===\n');
    const successful = results.filter(r => r.success);
    const failed = results.filter(r => !r.success);

    console.log(`Total themes tested: ${results.length}`);
    console.log(`Successful: ${successful.length}`);
    console.log(`Failed: ${failed.length}`);

    if (failed.length > 0) {
      console.log('\nFailed themes:');
      failed.forEach(r => console.log(`  - ${r.theme}: ${r.error || 'Not applied'}`));
    }

    // Color comparison
    console.log('\n=== THEME COLOR COMPARISON ===\n');
    results.forEach(r => {
      if (r.colors) {
        console.log(`${r.theme}:`);
        console.log(`  Primary: ${r.colors.primary}`);
        console.log(`  Base-100: ${r.colors.base100}`);
        console.log(`  Body BG: ${r.colors.bodyBg}`);
      }
    });

    // Check for identical themes
    console.log('\n=== CHECKING FOR IDENTICAL THEME COLORS ===\n');
    const signatures = {};
    results.forEach(r => {
      if (r.colors) {
        const sig = `${r.colors.primary}|${r.colors.base100}`;
        if (!signatures[sig]) signatures[sig] = [];
        signatures[sig].push(r.theme);
      }
    });

    let identicalFound = false;
    Object.entries(signatures).forEach(([sig, themes]) => {
      if (themes.length > 1) {
        identicalFound = true;
        console.log(`  ⚠️  IDENTICAL: ${themes.join(' and ')} have same colors!`);
      }
    });
    if (!identicalFound) {
      console.log('  ✅ All themes have unique color combinations');
    }

  } catch (error) {
    console.error('Error during test:', error.message);
    console.error(error.stack);
    await page.screenshot({ path: `${screenshotDir}/error.png` });
  } finally {
    await browser.close();
  }

  console.log('\n=== Test Complete ===');
  console.log(`Screenshots saved to: ${screenshotDir}`);
}

run().catch(console.error);
