# MegaClaw

OpenClaw in a container that actually works — with Playwright browsers pre-installed, onboarding baked in, and skill dependencies managed automatically.

## Why not just use the official Podman setup?

The [official OpenClaw Podman setup](https://docs.openclaw.ai/install/podman) has three problems this project solves:

1. **No browsers.** The official base image (`node:24-bookworm`) ships no browsers. Playwright requires a manual post-install step, and the `OPENCLAW_DOCKER_APT_PACKAGES` workaround is [broken in the Podman path](https://github.com/openclaw/openclaw/issues/35397). Here, the base is `mcr.microsoft.com/playwright:v1.41.0-jammy` — Chromium is already there.

2. **Permission errors.** Rootless Podman remaps UIDs, which causes `EACCES: permission denied` on `~/.openclaw/openclaw.json` ([Issue #27336](https://github.com/openclaw/openclaw/issues/27336)) when bind-mounting the config directory. Here, the onboarded config is committed into the image — no bind-mount, no permission issue.

3. **Onboarding is skipped officially.** The official setup seeds a minimal JSON and bypasses the interactive wizard. Here, `task runtime:build` runs the full onboarding interactively and bakes the result into the runtime image.

## Prerequisites

The following tools are required. None are standard Linux installs — check each one.

| Tool | What it does | Install |
|------|-------------|---------|
| **Podman** | Runs the containers (Docker alternative, rootless-friendly) | [podman.io/docs/installation](https://podman.io/docs/installation) |
| **Task** | Task runner — replaces Makefile | [taskfile.dev/installation](https://taskfile.dev/installation/) |
| **Git** | Clone the repo | [git-scm.com/downloads](https://git-scm.com/downloads) |

**Quick install on Debian/Ubuntu/Raspberry Pi OS:**

```bash
sudo apt update && sudo apt install -y podman git

# Task (go-task) — not in standard apt repos, use the official installer
curl -1sLf 'https://dl.cloudsmith.io/public/task/task/setup.deb.sh' | sudo -E bash
sudo apt install -y task
```

**Raspberry Pi only** — enable user lingering so containers survive logout:
```bash
sudo loginctl enable-linger $USER
```

> Building the base image locally on Raspberry Pi takes a long time. Use `task base:pull` instead.

## Quick Start

**On a regular machine (or if you want to build from source):**
```bash
task base:build        # Build base image locally
task runtime:build     # Run interactive onboarding and bake config into runtime image
task runtime:run       # Start OpenClaw
```

**On a Raspberry Pi (or any slow machine):**
```bash
task base:pull         # Pull pre-built base image from GHCR — no compile needed
task runtime:build     # Run interactive onboarding and bake config into runtime image
task runtime:run       # Start OpenClaw
```

You'll need:
- **OpenRouter API key** — https://openrouter.ai/settings/keys
- **A model** — free options at https://openrouter.ai/models?max_price=0&order=most-popular

## All Tasks

```bash
# Base image
task base:pull             # Pull pre-built base image from GHCR
task base:build            # Build base image locally (slow)
task base:ssh              # Open a shell in the base image

# Runtime image and container
task runtime:build         # First-time setup: interactive onboarding + install skill deps
task runtime:rebuild       # Rebuild without onboarding — reinstalls skill deps from existing db/
task runtime:run           # Start OpenClaw gateway (foreground)
task runtime:start         # Start OpenClaw gateway (background)
task runtime:stop          # Stop and remove the container
task runtime:ssh           # Open a shell in the running container

# Skills
task runtime:skills:add -- <url>   # Add a ClaWHub skill to deps.json
task runtime:skills:update         # Refresh skill definitions in the running container

# Personal data
task db:backup             # Zip db/ into megaclaw-db.zip (optional password)
task db:restore            # Restore db/ from megaclaw-db.zip
task db:wipe               # Wipe all data and config

# Other
task test                  # Smoke tests (syntax + structure checks)
```

Run `task --list` for the full list with descriptions.

## How the images are built

`megaclaw-base` uses a multi-stage build:

| Stage | From | Purpose |
|-------|------|---------|
| 1 | `homebrew/brew:latest` | Provides a pre-built Homebrew installation |
| 2 | `mcr.microsoft.com/playwright:v1.41.0-jammy` | Base with Chromium and browser deps |

Homebrew is copied from stage 1 into stage 2 rather than installed from scratch — OpenClaw uses Homebrew at runtime to install packages on demand, and the Homebrew install script is unreliable in Docker/CI environments.

`megaclaw-base` is built automatically by GitHub Actions and published to `ghcr.io/lovato/megaclaw-base` as a multi-platform image (`linux/amd64` + `linux/arm64`). `podman pull` automatically picks the right variant — works transparently on both x86 and Raspberry Pi.

`megaclaw-runtime` is built locally only — it runs `openclaw onboard` interactively and commits the result via `podman commit`. It is **never pushed to any registry** since it contains your API keys and config.

## Skill Dependencies

ClaWHub skills sometimes require additional npm packages (e.g. a Todoist CLI). MegaClaw manages these via `db/deps.json`.

**Add a skill:**
```bash
task runtime:skills:add -- https://clawhub.ai/mjrussell/todoist
task runtime:rebuild     # Bake it into the image
```

`skills:add` installs the skill, reads its `SKILL.md` for npm dependencies, resolves version ranges to exact pins, and updates `db/deps.json`. The `deps.json` file is personal (gitignored) and lives in `db/`. The repo ships `deps.default.json` as an empty template — it is seeded automatically on your first `runtime:build`.

**Rebuild after adding skills** — `runtime:rebuild` skips the interactive onboarding and only reinstalls deps. It's the right command whenever you add a skill or want to pick up a new base image without going through onboarding again.

**Update skill definitions** (no restart needed):
```bash
task runtime:skills:update
```

This runs `clawhub update` on the live container to pull the latest prompt/definition files without a full rebuild.

## Persistent data

| Host path | Container path | Contents |
|-----------|---------------|----------|
| `./db/` | `/root/.openclaw` | OpenClaw config, skill definitions, workspace |
| `./db/config/` | `/root/.config` | Tool auth tokens (e.g. `todoist auth`) |
| `./logs/` | `/tmp/openclaw` | OpenClaw logs |

`db/` is gitignored. Use `task db:backup` to create an encrypted zip and `task db:restore` to restore it. **Never commit `db/` or push `megaclaw-runtime`** — both contain your API keys.

## Accessing the Control UI

### Finding your URLs

Shell into the running container and ask OpenClaw directly:

```bash
task runtime:ssh
openclaw dashboard
```

It will print the Control UI URL and gateway address.

### The simple path: localhost

Open the Control UI from a browser **on the same machine running megaclaw**. No config changes needed — OpenClaw binds to `127.0.0.1` by default and browsers treat `localhost` as a secure context.

### Remote access (non-localhost)

Accessing the Control UI from a different machine requires all four steps below:

**1. Make the gateway listen on the network**

Edit `./db/openclaw.json`:
```json
{ "gateway": { "bind": "lan" } }
```
> Do not do this on untrusted networks. Never port-forward this to the internet.

**2. Allow your browser's origin**

Set `allowedOrigins` to the full origin of the **host running megaclaw** (not your browser):
```json
{ "gateway": { "controlUi": { "allowedOrigins": ["http://192.168.1.100:18789"] } } }
```

**3. Deal with the secure context requirement**

Browsers restrict certain APIs to `https://` or `localhost`. Flag your gateway URL as trusted in Chrome:
```
chrome://flags/#unsafely-treat-insecure-origin-as-secure
```
Add `http://192.168.1.100:18789`, enable the flag, relaunch Chrome.

**4. Pair your browser**

The Control UI will prompt for a pairing code. Send a message to your OpenClaw bot (WhatsApp or Telegram) to receive it.

All four steps must work together — if any one is missing you'll get a different error. For personal use, the localhost path is strongly recommended.

---

## Stuck Sessions

If an agent gets stuck in a loop, the session keeps running across restarts.

**List sessions:**
```bash
task runtime:ssh
openclaw sessions list
```

**Abort a stuck session:**
```bash
openclaw sessions abort <session-id>
```

**Quick fix without SSH:**
Edit `db/agents/main/sessions/sessions.json` — change `"status": "running"` to `"status": "done"` for the affected session, then restart OpenClaw.
