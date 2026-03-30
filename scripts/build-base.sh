#!/bin/bash
set -e

# --cgroup-manager=cgroupfs: required for rootless Podman (e.g. Raspberry Pi, VPS)
# --security-opt label=disable: disables SELinux labeling to avoid mount permission issues
podman build \
  --build-arg CACHE_BYPASS="$(date +%s)" \
  --cgroup-manager=cgroupfs \
  --security-opt label=disable \
  -t megaclaw-base \
  -f Dockerfile.base \
  .
