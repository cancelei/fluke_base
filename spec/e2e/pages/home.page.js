export class HomePage {
  /**
   * @param {import('@playwright/test').Page} page
   */
  constructor(page) {
    this.page = page;
    this.navbar = page.locator('nav');
    this.root = page.locator('body');
  }

  async goto() {
    await this.page.goto('/');
  }

  async isLoaded() {
    await this.root.waitFor();
    return await this.navbar.isVisible().catch(() => false);
  }
}

