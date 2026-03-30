# MegaClaw

OpenClaw in a container that actually works — with Playwright browsers pre-installed and onboarding baked in.

## Why not just use the official Podman setup?

The [official OpenClaw Podman setup](https://docs.openclaw.ai/install/podman) has three problems this project solves:

1. **No browsers.** The official base image (`node:24-bookworm`) ships no browsers. Playwright requires a manual post-install step, and the `OPENCLAW_DOCKER_APT_PACKAGES` workaround is [broken in the Podman path](https://github.com/openclaw/openclaw/issues/35397). Here, the base is `mcr.microsoft.com/playwright:v1.41.0-jammy` — Chromium is already there.

2. **Permission errors.** Rootless Podman remaps UIDs, which causes `EACCES: permission denied` on `~/.openclaw/openclaw.json` ([Issue #27336](https://github.com/openclaw/openclaw/issues/27336)) when bind-mounting the config directory. Here, the onboarded config is committed into the image — no bind-mount, no permission issue.

3. **Onboarding is skipped officially.** The official setup seeds a minimal JSON and bypasses the interactive wizard. Here, `task build:runtime` runs the full onboarding interactively and bakes the result into the runtime image.

## Prerequisites

The following tools are required to use this repo. None of them are standard Linux installs, so check each one.

| Tool | What it does | Install |
|------|-------------|---------|
| **Podman** | Runs the containers (Docker alternative, rootless-friendly) | [podman.io/docs/installation](https://podman.io/docs/installation) |
| **Task** | Task runner — replaces Makefile (`task build:base`, etc.) | [taskfile.dev/installation](https://taskfile.dev/installation/) |
| **Git** | Clone the repo and manage branches | [git-scm.com/downloads](https://git-scm.com/downloads) |

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

> Building the base image locally on Raspberry Pi works but takes significantly longer than on standard hardware. Use `task pull:base` instead.


## Quick Start

**On a regular machine (or if you want to build from source):**
```bash
task build:base       # Build base image locally
task build:runtime    # Run onboarding and bake config into runtime image
task run              # Start OpenClaw
```

**On a Raspberry Pi (or any slow machine):**
```bash
task pull:base        # Pull pre-built base image from GHCR — no compile needed
task build:runtime    # Run onboarding and bake config into runtime image
task run              # Start OpenClaw
```

You'll need:
- **OpenRouter API key** — https://openrouter.ai/settings/keys
- **A model** — free options available at https://openrouter.ai/models?max_price=0&order=most-popular

## All Tasks

```bash
task build:base       # Build base image locally
task pull:base        # Pull pre-built base image from GHCR
task build:runtime    # Run onboarding and bake config into runtime image
task run              # Run OpenClaw (interactive)
task start            # Run OpenClaw in background
task stop             # Stop the running container
task ssh:base         # Shell into base image
task ssh:runtime      # Shell into runtime image
task db:backup        # Zip db/ into megaclaw-db.zip (optional password)
task db:restore       # Restore db/ from megaclaw-db.zip
task db:wipe          # Wipe all data and reset
task test             # Run smoke tests (syntax + structure checks)
```

Run `task --list` to see all available tasks.

## How the images are built

`megaclaw-base` uses a multi-stage build:

| Stage | From | Purpose |
|-------|------|---------|
| 1 | `homebrew/brew:latest` | Provides a pre-built Homebrew installation |
| 2 | `mcr.microsoft.com/playwright:v1.41.0-jammy` | Base with Chromium and browser deps |

Homebrew is copied from stage 1 into stage 2 rather than installed from scratch. This is intentional — OpenClaw uses Homebrew at runtime to install packages on demand, and the Homebrew install script is unreliable in Docker/CI environments.

`megaclaw-base` is built automatically by GitHub Actions and published to `ghcr.io/lovato/megaclaw-base` as a multi-platform image (`linux/amd64` + `linux/arm64`). `podman pull` automatically picks the right variant — no flags needed, works transparently on both WSL and Raspberry Pi.

`megaclaw-runtime` is built locally only — it runs `openclaw onboard` interactively and commits the result into the image via `podman commit`. It is never pushed to any registry since it contains your API keys and config.

## Notes

- Uses `podman`, not Docker
- `./db` is mounted to `/root/.openclaw` for config persistence
- `./logs` is mounted for OpenClaw logs
- Browser automation is bundled but not fully tested yet
- **Never push `megaclaw-runtime` to any registry** — it contains your onboarding config and API keys baked into the image

## Accessing the Control UI

### Finding your URLs

If you're not sure where the dashboard is, shell into the running container and ask OpenClaw directly:

```bash
task ssh:runtime
openclaw dashboard
```

It will print the Control UI URL and gateway address.

### The simple path: localhost

The easiest setup is to open the Control UI from a browser **on the same machine running megaclaw**. No config changes needed — OpenClaw binds to `127.0.0.1` by default and browsers treat `localhost` as a secure context, so all features work out of the box.

### Remote access (non-localhost): it gets complicated

Accessing the Control UI from a different machine on the network requires several things to align, and it's easy to get stuck:

**1. Make the gateway listen on the network**

Edit `./db/openclaw.json` and change `gateway.bind` from `"loopback"` to `"lan"`:

```json
{ "gateway": { "bind": "lan" } }
```

> This exposes the gateway to your local network. Do not do this on untrusted networks and never port-forward this port to the internet.

**2. Allow your browser's origin**

Add `gateway.controlUi.allowedOrigins` set to the full origin of the host running megaclaw (protocol + IP + port). The origin is the **server's** address, not your browser's:

```json
{ "gateway": { "controlUi": { "allowedOrigins": ["http://192.168.1.100:18789"] } } }
```

**3. Deal with the secure context requirement**

Browsers only allow certain APIs (required by the Control UI) on `https://` or `localhost`. Since you're on plain `http://`, you need to explicitly flag the origin as trusted in Chrome:

```
chrome://flags/#unsafely-treat-insecure-origin-as-secure
```

Add your gateway URL (`http://192.168.1.100:18789`), enable the flag, relaunch Chrome.

**4. Pair your browser**

After all of the above, the Control UI will ask for pairing. Send a message to your OpenClaw bot (WhatsApp or Telegram) to get a pairing code, then enter it in the browser.

---

## Stuck Sessions

If an agent gets stuck in a loop (e.g., repeatedly calling the same tool), it can cause issues across restarts. You'll notice the session keeps running even after killing and relaunching OpenClaw.

**List all sessions:**
```bash
task ssh:runtime
openclaw sessions list
```

**Abort a stuck session:**
```bash
task ssh:runtime
openclaw sessions abort <session-id>
```

**Quick fix without SSH:**
Edit `db/agents/main/sessions/sessions.json` and change `"status": "running"` to `"status": "done"` for the affected session key. Then restart OpenClaw.

---

All four steps need to work together. If any one of them is missing you'll get a different error. For personal use, the localhost path is strongly recommended.
