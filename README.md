# MegaClaw

Self-hosted AI assistant containerized with Podman and browser automation via Playwright.

## Prerequisites

**Raspberry Pi only** — enable user lingering first:
```bash
sudo loginctl enable-linger $USER
```

**All Linux systems:**
```bash
sudo apt update
sudo apt install -y podman
curl -1sLf 'https://dl.cloudsmith.io/public/task/task/setup.deb.sh' | sudo -E bash
sudo apt install -y task
```

> Building on Raspberry Pi works but takes significantly longer than on standard hardware.

## Quick Start

```bash
task build:base       # Build base image (OpenClaw + Playwright + Homebrew)
task build:runtime    # Build runtime image (runs onboarding interactively)
task run              # Start OpenClaw
```

You'll need:
- **OpenRouter API key** — https://openrouter.ai/settings/keys
- **A model** — free options available at https://openrouter.ai/models?max_price=0&order=most-popular

## All Tasks

```bash
task build:base       # Build base image
task build:runtime    # Build runtime image + run onboard
task run              # Run OpenClaw (interactive)
task start            # Run OpenClaw in background
task stop             # Stop the running container
task ssh:base         # Shell into base image
task ssh:runtime      # Shell into runtime image
task wipe             # Wipe all data and reset
```

Run `task --list` to see all available tasks.

## What's Included

| Component | Details |
|-----------|---------|
| OpenClaw | Installed via official installer |
| Playwright | Browser automation (pre-installed in base image) |
| Homebrew | Available in base image |
| Node.js 22 | Installed automatically |

## Notes

- Uses `podman`, not Docker
- `./db` is mounted to `/root/.openclaw` for config persistence
- `./logs` is mounted for OpenClaw logs
- Browser automation is bundled but not fully tested yet
