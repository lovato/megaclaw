# OpenClaw

Self-hosted AI assistant with browser automation.

## Quick Start

```bash
./build.sh          # Build the Docker image
./run.sh            # Run the container
```

## What This Provides

- **OpenClaw** - Personal AI assistant from [openclaw/openclaw](https://github.com/openclaw/openclaw)
- **Playwright** - Browser automation for AI web interactions
- **Node.js 22** - Runtime with pnpm

## Environment

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCLAW_GATEWAY_PORT` | 18789 | Gateway port |

## Usage

After building, run the container and complete onboarding:

```bash
podman run -it openclaw-local
```

Or mount config for persistence:

```bash
podman run -it -v ./config:/home/node/.openclaw openclaw-local
```
