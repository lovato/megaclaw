#!/bin/bash
set -e

# Ensure the base image is available locally — pull from GHCR if not
if ! podman image exists megaclaw-base:latest; then
  echo "Base image not found locally, pulling from GHCR..."
  podman pull ghcr.io/lovato/megaclaw-base:latest
  podman tag ghcr.io/lovato/megaclaw-base:latest megaclaw-base:latest
fi

# Build the runtime image
podman build \
  --build-arg CACHE_BYPASS="$(date +%s)" \
  --cgroup-manager=cgroupfs \
  --security-opt label=disable \
  -t megaclaw-runtime \
  -f Dockerfile.runtime \
  .

# Run interactive onboarding and commit the result into the image
podman rm -f megaclaw-runtime 2>/dev/null || true
podman run -it --network=host --name megaclaw-runtime \
  -v ./db:/root/.openclaw \
  megaclaw-runtime openclaw onboard
podman commit megaclaw-runtime megaclaw-runtime
podman rm megaclaw-runtime
