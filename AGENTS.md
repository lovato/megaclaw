# AGENTS.md

## Project Overview

This repository contains Dockerfiles for building OpenClaw containers with Playwright browser automation.

## What is OpenClaw?

[OpenClaw](https://github.com/openclaw/openclaw) is a self-hosted AI assistant (219k+ stars) that can interact via multiple channels (WhatsApp, Telegram, Discord, Slack, etc.) and perform tasks using browser automation.

## Key Details

- **Default container tool**: `podman` (not docker)
- **Tasks**: Use `task --list` to see available commands
- **Images**: `openclaw-base` (with Homebrew), `openclaw-runtime` (onboarded)

## Images

### openclaw-base
- Base image with OpenClaw, Homebrew, Playwright browsers
- Built from `Dockerfile.base`

### openclaw-runtime
- Runtime image with onboarded config baked in
- Built from `Dockerfile.runtime`
- Ready to run `openclaw gateway`

## Build Process

The base Dockerfile:
1. Uses `mcr.microsoft.com/playwright:v1.41.0-jammy` as base (includes browsers)
2. Installs build-essential, procps, file
3. Installs Homebrew
4. Runs the official OpenClaw installer: `curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard`

## Common Commands

```bash
# Build base image
task build:base

# Build runtime image (runs onboard interactively)
task build:runtime

# Run OpenClaw (interactive)
task run

# Run in background
task start

# Stop container
task stop

# Shell into containers
task ssh:base
task ssh:runtime
```

## Notes

- Run `task build:runtime` first - this runs onboarding interactively
- After onboard, the config is baked into the runtime image
- Use `task run` or `task start` to run the gateway on port 18789
- Playwright browsers are pre-installed in the base image for AI web automation
