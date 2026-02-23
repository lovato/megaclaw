# OpenClaw Docker Container

Self-hosted AI assistant with browser automation.

## Quick Start

```bash
./build.sh          # Build the container image
./run.sh            # Run the container
```

## First Run

On first run, complete onboarding:

```bash
podman run -it -v ./data:/home/node/.openclaw openclaw-local openclaw onboard
```

## What This Provides

- **OpenClaw** - Installed via official installer
- **Playwright** - Browser automation (from base image)
- **Node.js 22** - Installed automatically

## Notes

- Uses `podman` (not docker)
- `./run.sh` mounts `./data` for config persistence at `/home/node/.openclaw`
