import { test, expect } from './fixtures/test-base.js';
import { HomePage } from './pages/home.page.js';

test('home page loads via POM', async ({ page }) => {
  const home = new HomePage(page);
  await home.goto();
  expect(await home.isLoaded()).toBe(true);
});

