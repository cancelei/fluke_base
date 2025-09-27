# Playwright MCP ↔ Rails E2E Patterns — Cross‑Reference & Quick File Guide

> Purpose: connect your **Rails + Playwright E2E cookbook** (`playwright_rails_testing_patterns.md`) with the **Playwright MCP** ecosystem. Use this to navigate “what lives where”, what each piece does, and how to bridge traditional Playwright tests with MCP‑driven automation.

---

## 1) Quick mental model

- **Rails E2E (your doc):** you own the browser via Playwright’s test runner; you boot Rails, seed/reset data, and write specs.
- **Playwright MCP:** an **MCP server** exposes browser tools (navigate, click, fill, etc.) so **AI clients** (Claude Desktop, VS Code Copilot Agent, Cursor, Windsurf, etc.) can drive the browser and even generate steps/tests. You configure it via your client’s *mcpServers* settings and run: `npx @playwright/mcp@latest`.

**Bridge in practice:** let MCP (AI) explore/generate a flow → export/curate as real Playwright specs → slot into your `/e2e/tests` with the patterns from your Rails doc.

---

## 2) Section‑by‑section map (Rails doc ↔ MCP)

| Rails patterns section | What you do there | Closest MCP piece | How to marry them |
|---|---|---|---|
| **0–1. Layout & Boot** | Dedicated `/e2e`, `webServer`, `Procfile.e2e`, `bin/e2e-serve` | **MCP “Getting Started / Config”**: client config with `"command": "npx", "args": ["@playwright/mcp@latest"]` | Keep your Rails boot as-is. Run MCP server in parallel (or let client spawn it). Point MCP actions to `BASE_URL` you already use. |
| **2. Playwright config** | `playwright.config.ts` (projects, reporter, tracing) | MCP server **caps** (e.g. `--caps=tracing`, `--caps=pdf`, `--caps=verify`) | Align artifacts: enable Playwright traces by default; enable MCP tracing cap when you want agentic sessions to capture extra evidence. |
| **3. Database strategies** | Reset endpoints, truncate, per‑worker DBs | MCP **tools** are browser‑centric; they won’t reset Rails | Keep your `/test_only/reset` endpoint. Expose a “Reset” prompt or tool in your client to call that endpoint between MCP sessions. |
| **4. Auth patterns** | UI login, programmatic session, storage state | MCP **browser_fill_form**, **browser_type**, **browser_click** | Use MCP to perform first login and then persist **storageState.json** for your Playwright projects. |
| **5. Turbo waits** | Assert DOM outcomes; helper `waitForTurbo` | MCP uses **accessibility snapshots** vs pixels | The same guidance applies: assert on roles/labels/DOM results. Favor role‑based descriptions when prompting the agent. |
| **6. Stimulus/Tailwind** | Prefer `getByRole`/`getByLabel` | MCP tools accept **human‑readable element descriptions** + **refs** | Structure your markup with solid ARIA to make agent intent unambiguous and tool permission prompts accurate. |
| **7. Helpers (uploads/downloads)** | `setInputFiles`, `page.waitForEvent('download')` | **browser_file_upload**, **browser_pdf_save** (with caps) | For code‑gen or exploratory runs, let MCP upload/create PDFs; then port the steps into deterministic Playwright specs. |
| **8. Mailer checks** | Test endpoints / letter_opener_web | MCP can hit URLs & read JSON | Add a read‑only `/test_only/last_mail` route; instruct the agent to fetch/validate subject/links before codifying it. |
| **9. Authorization (Pundit)** | Negative tests & forbidden flows | **browser_navigate** + assertions | Have the agent attempt direct URL access; export its successful checks as specs. |
| **10–11. Flake & CI** | Traces/videos; GH Actions matrix | MCP **tracing/verify** caps; clients’ own logs | Store MCP run artifacts under `/e2e/mcp-artifacts/` in CI for later triage alongside Playwright reports. |
| **12. Ruby client** | `playwright-ruby-client` + RSpec | MCP is Node‑first; clients talk STDIO | If you want all‑Ruby, keep Ruby tests; use MCP only for exploration/code‑gen, not for the stable suite. |
| **15. Background jobs** | Run real worker in test | MCP is agnostic | In agent sessions, wait for UI evidence of job completion (badges, rows) — same as your spec rules. |

---

## 3) Playwright MCP essentials you’ll actually touch

- **Client config snippet** (VS Code / Cursor / Claude Code, etc.):
  ```jsonc
  {
    "mcpServers": {
      "playwright": { "command": "npx", "args": ["@playwright/mcp@latest"] }
    }
  }
  ```
- **Common tools** (names abbreviated): `browser_navigate`, `browser_click`, `browser_type`, `browser_fill_form`, `browser_select_option`, `browser_hover`, `browser_file_upload`, XY mouse tools; optional via caps: `browser_pdf_save`, tracing & verification tools.
- **Capabilities flags** (pass as args in your client config): `--caps=tracing`, `--caps=pdf`, `--caps=verify`.
- **Access model**: tools act on **accessibility snapshot refs** + your **human‑readable description** (agent asks permission per element), which plays nicely with semantic/ARIA‑rich Rails views.

---

## 4) Practical “in‑betweens” (from prompt → stable spec)

1) **Exploration** (MCP): “Open /users/sign_in, login as admin, go to /products, create product, export CSV.”  
2) **Harvest** (export steps): capture the agent’s successful sequence and selectors/labels.  
3) **Codify** (Playwright spec): paste into `/e2e/tests/products.spec.ts`, replace any brittle selectors with `getByRole/getByLabel`, reuse your helpers (`waitForTurbo`, seeders).  
4) **Artifact parity**: keep **MCP traces** and **Playwright traces** side‑by‑side in CI.  
5) **Lock down data**: ensure `/test_only/reset` runs before each exploration to avoid flaky state.  

---

## 5) Repo/file quick‑reference (Playwright MCP)

- **`package.json`** — NPM entry (`@playwright/mcp`), CLI name, dependency metadata.  
- **`cli.js`** — entrypoint the client executes (`npx @playwright/mcp@latest`).  
- **`index.js` / `index.d.ts`** — server bootstrap & exported typings.  
- **`config.d.ts`** — shape of server config/arguments (caps, ports, timeouts).  
- **`playwright.config.ts`** — internal Playwright settings used by the MCP server.  
- **`src/`** — implementation of tools (navigate/click/type/etc.), element snapshotting, permission prompts.  
- **`tests/`** — self‑tests for the MCP server tools.  
- **`extension/`** — installer assets for IDEs/clients that support one‑click add.  
- **`Dockerfile`** — containerized server (handy for CI agent sandboxes).  

> Tip: Treat the **tools list** in the README as your *coverage checklist*; for each critical UI flow in Rails, confirm you can drive it with only these tools (no image/pixel hacks).

---

## 6) Minimal workflows you can reuse

- **Claude Code (CLI)**  
  ```bash
  claude mcp add playwright npx @playwright/mcp@latest
  # then chat: "Open http://localhost:5017, log in, create a Project, export steps as Playwright test"
  ```

- **VS Code Copilot Agent**  
  - Settings → *Add MCP* → paste the standard config.  
  - Command Palette: “Copilot: Start Agent” → instruct the flow, then copy generated steps.

- **Cursor / Windsurf**  
  - Settings → MCP → Add server with `npx @playwright/mcp@latest`  
  - Ask the agent to **generate a spec** that uses `getByRole`/`getByLabel` and avoids Tailwind classes.

---

## 7) Guard‑rails (security & stability)

- Keep test‑only endpoints (`/test_only/*`) behind **localhost** OR a secret header (`X‑E2E‑Token`).  
- Do **not** expose MCP server remotely without network policies; prefer STDIO spawn by the client.  
- Persist **storageState.json** post‑login and reuse across both MCP sessions and Playwright projects.  
- For Turbo Streams, require agents/tests to assert **post‑action DOM** (not network idle).

---

## 8) Where to look up details fast

- **MCP concepts:** Servers, Tools, Resources, Prompts; protocol ops (`tools/list`, `tools/call`, etc.).  
- **Playwright MCP README:** tools catalog, client config blocks, caps flags.  
- **Example clients:** HyperAgent and IDE agents that plug into MCP.  
- **Community servers:** alternative Playwright MCP servers offer examples of prompts/configs you can borrow.

---

## 9) Copy‑paste snippets

**Client config with tracing + PDF**  
```jsonc
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--caps=tracing,pdf"]
    }
  }
}
```

**Reset before exploration (Claude Desktop custom tool message)**  
```
POST {{BASE_URL}}/test_only/reset
Then: navigate to {{BASE_URL}}/users/sign_in and continue the flow.
```

**Exported steps into a spec scaffold**  
```ts
import { test, expect } from '@playwright/test';
import { waitForTurbo } from '../helpers/turbo';

test('admin creates a product and exports CSV', async ({ page }) => {
  await page.goto('/users/sign_in');
  await page.getByLabel('Email').fill('admin@example.com');
  await page.getByLabel('Password').fill('password');
  await page.getByRole('button', { name: /sign in/i }).click();

  await page.goto('/products');
  await page.getByRole('button', { name: /new product/i }).click();
  await page.getByLabel('Name').fill('Coffee Mug');
  await page.getByRole('button', { name: /create/i }).click();
  await waitForTurbo(page);

  const [download] = await Promise.all([
    page.waitForEvent('download'),
    page.getByRole('button', { name: /export csv/i }).click()
  ]);
  expect(await download.path()).toBeTruthy();
});
```

---

## 10) Next steps

- Plug MCP into your preferred client and **generate** the first flow for one domain (e.g., Orders).
- **Harden** it as a deterministic spec using your helpers and DB reset strategy.
- Add **caps** only where useful (tracing/PDF). Keep selectors semantic to help both the agent and specs.
