# OpenClaw Docker Container

Self-hosted AI assistant with browser automation.

## Quick Start

```bash
task build          # Build the container image
task run            # Run the container
```

## First Run

On first run, complete onboarding:

```bash
task onboard
```

## Tasks

```bash
task build          # Build the container image
task run            # Run the container (requires prior onboarding)
task onboard        # Run onboarding wizard
task wipe           # Wipe all data and reset
```

## What This Provides

- **OpenClaw** - Installed via official installer
- **Playwright** - Browser automation (from base image)
- **Node.js 22** - Installed automatically

## What do you need?

### For a quick start:

- **OpenRouter** API Key - https://openrouter.ai/settings/keys
- **A Model** Get a Free one, from this list: https://openrouter.ai/models?max_price=0&order=most-popular

## Notes

- Uses `podman` (not docker)
- `./db` is mounted for config persistence at `/home/node/.openclaw`
- Run `task --list` to see all available tasks
