# OpenClaw Fishtank

Self-hosted AI assistant with browser automation, trapped in a container.

## Quick Start

```bash
task build:base       # Build the base container image
task build:runtime    # Build runtime with onboarding baked in
task run              # Run the container (interactive)
```

## Tasks

```bash
task build:base       # Build base image (OpenClaw + Homebrew)
task build:runtime    # Build runtime image + run onboard
task run              # Run OpenClaw (interactive)
task start            # Run OpenClaw in background
task stop             # Stop the running container
task ssh:base         # Shell into base image
task ssh:runtime      # Shell into runtime image
task wipe             # Wipe all data and reset
```

## First Run

1. Build base: `task build:base`
2. Build runtime (runs onboard): `task build:runtime`
3. Run: `task run` or `task start`

## What This Provides

- **OpenClaw** - Installed via official installer
- **Playwright** - Browser automation (from base image)
- **Homebrew** - Installed in base image
- **Node.js 22** - Installed automatically

## What do you need?

### For a quick start:

- **OpenRouter** API Key - https://openrouter.ai/settings/keys
- **A Model** Get a Free one, from this list: https://openrouter.ai/models?max_price=0&order=most-popular

## Notes

- Uses `podman` (not docker)
- `./db` is mounted for config persistence at `/root/.openclaw`
- `./logs` is mounted for OpenClaw logs
- Run `task --list` to see all available tasks
