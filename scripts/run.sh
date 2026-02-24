#!/bin/bash
MODE="${1:-interactive}"

IMAGE="${2:-$(podman image exists openclaw-runtime && echo openclaw-runtime || echo openclaw-base)}"

if [ "$MODE" = "daemon" ]; then
  podman run -d --rm \
    --name openclaw \
    --network=host \
    -v ./db:/root/.openclaw \
    -v ./logs:/tmp/openclaw \
    $IMAGE
else
  podman run -it --rm \
    --name openclaw \
    --network=host \
    -v ./db:/root/.openclaw \
    -v ./logs:/tmp/openclaw \
    $IMAGE
fi
