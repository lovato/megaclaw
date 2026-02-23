# OpenClaw Docker Container

Self-hosted AI assistant with browser automation using https://openclaw.ai/ wrapped in a container.

## Quick Start

```bash
./build.sh          # Build the Docker image
./run.sh            # Run the container
```

## What This Provides

- **OpenClaw** - Installed via official `curl -fsSL https://openclaw.ai/install.sh`
- **Playwright** - Browser automation (from base image)
- **Node.js 22** - Installed automatically by OpenClaw installer

## Environment

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCLAW_GATEWAY_PORT` | 18789 | Gateway port |

## First Run

On first run, you'll need to complete onboarding to configure API keys and channels:

```bash
podman run -it openclaw-local openclaw onboard
```

To run the gateway:

```bash
podman run -it openclaw-local
```

For persistence, mount config:

```bash
podman run -it -v ./config:/home/node/.openclaw openclaw-local
```

## Build Notes

- Uses official OpenClaw installer script
- Skips onboard during build (`--no-onboard`)
- Includes Playwright browsers for AI web automation
