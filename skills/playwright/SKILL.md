---
name: playwright
description: "Browser automation via Playwright: screenshots, scraping, PDF export, form interaction, SPA rendering. Use when: (1) capturing screenshots of URLs, (2) scraping JS-heavy pages, (3) filling and submitting forms, (4) exporting pages to PDF. NOT for: simple curl-accessible pages (use curl/wget), API calls (use curl/fetch directly), or tasks not requiring a real browser."
metadata:
  {
    "openclaw":
      {
        "emoji": "🎭",
        "requires": { "bins": ["npx"] },
      },
  }
---

# Playwright Skill

Use `playwright` (already installed in this container) for browser automation tasks.

## CRITICAL: Execution Rules

1. **Always run headless.** There is no display server (no XServer, no DISPLAY). Never launch a headed browser. Always pass `{ headless: true }` explicitly in scripts.
2. **Never use PTY mode.** These are plain non-interactive shell commands. PTY is not needed and will not help.
3. **Chromium only.** Use `--browser chromium` for CLI commands and `chromium.launch()` for scripts. Firefox and WebKit are available but Chromium is pre-configured for this environment.

## When to Use

✅ **USE this skill when:**
- Taking screenshots of URLs (including JS-rendered content)
- Scraping content from SPAs or pages requiring JavaScript
- Filling forms and clicking buttons on web UIs
- Exporting pages to PDF
- Waiting for dynamic content or network idle

❌ **DON'T use this skill when:**
- Static HTML or API endpoints → use `curl` instead
- Authentication flows requiring persistent sessions → see credentials setup
- Large-scale crawling → this is single-page tooling

## Output Directory

Always save files to `/root/.openclaw/workspace/screenshots/` — this directory is mounted from the host, so files are immediately accessible outside the container.

## Output Filename Format

Always name output files as `YYYYMMDD-<slug>.<ext>` where:
- `YYYYMMDD` is today's date (e.g. `20260405`)
- `<slug>` is derived from the URL: use the domain name, stripping `www.` and replacing dots/slashes with dashes (e.g. `https://www.example.com/page` → `example-com-page`)

Examples: `20260405-example-com.png`, `20260405-github-com-lovato.png`, `20260405-example-com.pdf`

Generate the filename in shell like this:

```bash
DATE=$(date +%Y%m%d)
SLUG=$(echo "https://www.example.com/page" | sed 's|https\?://||;s|www\.||;s|[/.]|-|g;s|-\+$||;s|^-\+||')
FILE="/root/.openclaw/workspace/screenshots/${DATE}-${SLUG}.png"
```

## Quick Commands

### Screenshot

```bash
DATE=$(date +%Y%m%d)
SLUG=$(echo "https://example.com" | sed 's|https\?://||;s|www\.||;s|[/.]|-|g;s|-\+$||;s|^-\+||')
playwright screenshot --browser chromium "https://example.com" /root/.openclaw/workspace/screenshots/${DATE}-${SLUG}.png

# Full-page screenshot
playwright screenshot --browser chromium --full-page "https://example.com" /root/.openclaw/workspace/screenshots/${DATE}-${SLUG}-full.png
```

### PDF Export

```bash
DATE=$(date +%Y%m%d)
SLUG=$(echo "https://example.com" | sed 's|https\?://||;s|www\.||;s|[/.]|-|g;s|-\+$||;s|^-\+||')
playwright pdf --browser chromium "https://example.com" /root/.openclaw/workspace/screenshots/${DATE}-${SLUG}.pdf
```

## Scripted Automation

For scraping, form interaction, or anything beyond a one-liner, write a temporary Node.js script and run it with `node`. Always pass `{ headless: true }` to `launch()`.

```bash
cat > /tmp/pw-script.mjs << 'EOF'
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
await page.goto('https://example.com');

// Scrape content
const title = await page.title();
const text = await page.textContent('body');
console.log(JSON.stringify({ title, text: text.slice(0, 500) }));

// --- OR: interact with a form ---
// await page.fill('#username', 'myuser');
// await page.fill('#password', 'mypass');
// await page.click('button[type=submit]');
// await page.waitForNavigation();

await browser.close();
EOF

node /tmp/pw-script.mjs
```

### Wait for Dynamic Content / SPA

```bash
cat > /tmp/pw-spa.mjs << 'EOF'
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
await page.goto('https://example.com', { waitUntil: 'networkidle' });
const html = await page.content();
console.log(html);
await browser.close();
EOF

node /tmp/pw-spa.mjs
```

## Import Path

Always use the absolute path — bare `'playwright'` imports fail inside the container:

```js
import pkg from '/usr/lib/node_modules/playwright/index.js';
const { chromium, firefox, webkit } = pkg;
```

## Tips

- Use `waitUntil: 'networkidle'` for SPAs that load content via AJAX
- Always save output files to `/root/.openclaw/workspace/screenshots/` — this is host-mounted so files are immediately visible on the host machine
- `page.evaluate(() => document.body.innerText)` is often the cleanest scrape method
- For login-protected pages, set cookies via `context.addCookies([...])`
