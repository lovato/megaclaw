# AGENTS.md

## Project Overview

This repository contains a Dockerfile for building an OpenClaw container with Playwright browser automation.

## What is OpenClaw?

[OpenClaw](https://github.com/openclaw/openclaw) is a self-hosted AI assistant (219k+ stars) that can interact via multiple channels (WhatsApp, Telegram, Discord, Slack, etc.) and perform tasks using browser automation.

## Key Details

- **Default container tool**: `podman` (not docker)
- **Build command**: `./build.sh`
- **Run command**: `./run.sh` or `podman run -it openclaw-local`
- **Image name**: `openclaw-local`

## Build Process

The Dockerfile:
1. Uses `mcr.microsoft.com/playwright:v1.41.0-jammy` as base (includes browsers)
2. Runs the official OpenClaw installer: `curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard`
3. Installs Node.js 22 automatically
4. Sets gateway port to 18789

## Common Commands

```bash
# Build the image
./build.sh

# Run interactively
podman run -it openclaw-local

# Run with config persistence
podman run -it -v ./config:/home/node/.openclaw openclaw-local

# Run gateway
podman run -it openclaw-local openclaw gateway
```

## Notes

- On first run, complete onboarding: `openclaw onboard`
- Playwright browsers are pre-installed in the base image for AI web automation
