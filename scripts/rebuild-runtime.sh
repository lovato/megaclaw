#!/bin/bash
set -e

# Non-interactive runtime rebuild — skips onboarding.
# Use when you already have a configured db/ and just need to reinstall skill deps.
# This is faster than build-runtime.sh: no interactive wizard, one commit pass only.

if [ ! -d "./db" ] || [ -z "$(ls -A ./db 2>/dev/null)" ]; then
  echo "Error: db/ is empty or missing. Run 'task runtime:build' first to complete onboarding."
  exit 1
fi

# Ensure the base image is available locally — pull from GHCR if not
if ! podman image exists megaclaw-base:latest; then
  echo "Base image not found locally, pulling from GHCR..."
  podman pull ghcr.io/lovato/megaclaw-base:latest
  podman tag ghcr.io/lovato/megaclaw-base:latest megaclaw-base:latest
fi

# Seed personal deps.json from default template if not present
if [ ! -f "./db/deps.json" ]; then
  echo "==> No db/deps.json found, seeding from deps.default.json..."
  cp deps.default.json ./db/deps.json
fi

# Rebuild the image (bakes latest db/deps.json + scripts)
podman build \
  --build-arg CACHE_BYPASS="$(date +%s)" \
  --cgroup-manager=cgroupfs \
  --security-opt label=disable \
  -t megaclaw-runtime \
  -f Dockerfile.runtime \
  .

# Install skill deps from deps.json — no onboarding, single commit
echo "==> Installing skill dependencies..."
podman rm -f megaclaw-runtime-deps 2>/dev/null || true
podman run --name megaclaw-runtime-deps \
  --network=host \
  -v ./db:/root/.openclaw \
  megaclaw-runtime install-deps
podman commit megaclaw-runtime-deps megaclaw-runtime
podman rm megaclaw-runtime-deps
