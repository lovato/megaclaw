#!/bin/bash
set -e

# Build the runtime image
podman build \
  --build-arg CACHE_BYPASS="$(date +%s)" \
  --cgroup-manager=cgroupfs \
  --security-opt label=disable \
  -t openclaw-runtime \
  -f Dockerfile.runtime \
  .

# Run interactive onboarding and commit the result into the image
podman rm -f openclaw-runtime 2>/dev/null || true
podman run -it --network=host --name openclaw-runtime \
  -v ./db:/root/.openclaw \
  openclaw-runtime openclaw onboard
podman commit openclaw-runtime openclaw-runtime
podman rm openclaw-runtime
