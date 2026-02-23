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

## What This Provides

- **OpenClaw** - Installed via official installer
- **Playwright** - Browser automation (from base image)
- **Node.js 22** - Installed automatically

## Notes

- Uses `podman` (not docker)
- `./db` is mounted for config persistence at `/home/node/.openclaw`
- Run `task --list` to see all available tasks
