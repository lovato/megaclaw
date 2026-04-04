# AGENTS.md

## Project Overview

MegaClaw packages OpenClaw into a Podman-friendly container with Playwright browsers and Homebrew pre-installed — solving three known issues with the official OpenClaw Podman setup.

## What is OpenClaw?

[OpenClaw](https://github.com/openclaw/openclaw) is a self-hosted AI assistant (219k+ stars) that can interact via multiple channels (WhatsApp, Telegram, Discord, Slack, etc.) and perform tasks using browser automation.

## Key Details

- **Container tool**: `podman` (not docker)
- **Tasks**: Use `task --list` to see available commands
- **Images**: `megaclaw-base` (base layer, published to GHCR), `megaclaw-runtime` (onboarded, local only)

## Image Layers

### megaclaw-base
- Built from `Dockerfile.base` using a **multi-stage build**:
  - **Stage 1** (`homebrew/brew:latest`): source for a pre-built Homebrew installation
  - **Stage 2** (`mcr.microsoft.com/playwright:v1.41.0-jammy`): actual base — includes Chromium and browser deps
  - Copies `/home/linuxbrew` from stage 1 into stage 2 (avoids running the Homebrew install script in CI)
  - Installs OpenClaw via `curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard`
- Published automatically to `ghcr.io/lovato/megaclaw-base` via GitHub Actions:
  - On every push to `main` that touches `Dockerfile.base` or the workflow file
  - On a **weekly schedule** (every Monday at 03:00 UTC) — ensures OpenClaw and ClaWHub are always rebuilt from their latest installers even without code changes
  - On manual trigger (`workflow_dispatch`) from the GitHub Actions UI
- Tagged as `latest`, `1.0.YYYYMMDD` (e.g. `1.0.20260404`), and `sha-<commit>`. The `1.0` prefix is bumped manually when the base image architecture changes significantly.
- Built for both `linux/amd64` and `linux/arm64` — `podman pull` automatically picks the right variant for the current machine (x86 on WSL, arm64 on Raspberry Pi)

### megaclaw-runtime
- Built from `Dockerfile.runtime` (`FROM megaclaw-base:latest`)
- `task build:runtime` runs `openclaw onboard` interactively, then commits the result with `podman commit`
- Onboarding config (API keys, settings) is baked into the image
- **Never push to any registry** — the image contains private credentials

## Common Commands

```bash
task pull:base        # Pull megaclaw-base from GHCR (preferred on Pi)
task build:base       # Build megaclaw-base locally from source
task build:runtime    # Run interactive onboarding and bake into runtime image
task run              # Run OpenClaw gateway (interactive)
task start            # Run OpenClaw gateway (background)
task stop             # Stop the running container
task ssh:base         # Shell into megaclaw-base
task ssh:runtime      # Shell into megaclaw-runtime
task db:backup        # Zip db/ into megaclaw-db.zip (optional password)
task db:restore       # Restore db/ from megaclaw-db.zip
task db:wipe          # Wipe db/ and reset config
task test             # Smoke tests (bash syntax, yaml, Dockerfiles)
```

## Upgrading OpenClaw or ClaWHub

Both are installed via their latest installers on every `task build:base` run — there are no pinned version numbers to update. To upgrade:

- **Locally**: `task build:base && task build:runtime`
- **On the Pi**: trigger the GitHub Actions workflow manually (or wait for Monday's scheduled build), then `task pull:base && task build:runtime`

The only thing that requires a deliberate version bump is the Playwright base image (`mcr.microsoft.com/playwright:v1.41.0-jammy` in `Dockerfile.base`). Update that line manually when a new Playwright version is needed.

## Notes

- Homebrew is intentionally pre-installed in `megaclaw-base` because OpenClaw uses it at runtime to install packages on the fly. Without it, OpenClaw attempts to install Homebrew itself and often fails mid-session.
- The multi-stage Homebrew approach (copy from `homebrew/brew`) was chosen because the Homebrew install script is not reliable in Docker/CI environments (root checks, network calls).
- **`CACHE_BYPASS`** is a build arg passed as `$(date +%s)` (current Unix timestamp) to `podman build` / Docker Buildx. Because Docker caches each `RUN` layer, the OpenClaw and ClaWHub installers would only run once and then be served from cache forever — even on a weekly scheduled build. `CACHE_BYPASS` is consumed by a `RUN echo` line placed just before the installers, which makes Docker see a changed layer and re-run everything after it. Without this, "weekly fresh build" would actually be "weekly cache hit, same old binaries."
- `./db` maps to `/root/.openclaw` — OpenClaw's config directory
- `./logs` maps to `/tmp/openclaw` — OpenClaw's log output
- `megaclaw-db.zip` is gitignored — use `task db:backup` / `task db:restore` to move config between machines
