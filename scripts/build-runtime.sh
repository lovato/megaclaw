#!/bin/bash
set -e

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

# Build the runtime image (bakes db/deps.json + scripts in via Dockerfile.runtime)
podman build \
  --build-arg CACHE_BYPASS="$(date +%s)" \
  --cgroup-manager=cgroupfs \
  --security-opt label=disable \
  -t megaclaw-runtime \
  -f Dockerfile.runtime \
  .

# Pass 1: interactive onboarding — user completes the wizard, then container exits
podman rm -f megaclaw-runtime 2>/dev/null || true
podman run -it --network=host --name megaclaw-runtime \
  -v ./db:/root/.openclaw \
  megaclaw-runtime openclaw onboard
podman commit megaclaw-runtime megaclaw-runtime
podman rm megaclaw-runtime

# Pass 2: install skill deps from deps.json into the committed image
# Runs non-interactively inside the container, then commits the result
echo "==> Installing skill dependencies..."
podman run --name megaclaw-runtime-deps \
  --network=host \
  -v ./db:/root/.openclaw \
  megaclaw-runtime install-deps
podman commit megaclaw-runtime-deps megaclaw-runtime
podman rm megaclaw-runtime-deps
