#!/bin/bash
set -e

MODE="${1:-interactive}"

if [ "$MODE" = "daemon" ]; then
  podman run -d --rm \
    --name openclaw \
    --network=host \
    -v ./db:/root/.openclaw \
    -v ./logs:/tmp/openclaw \
    openclaw-runtime openclaw gateway
else
  podman run -it --rm \
    --name openclaw \
    --network=host \
    -v ./db:/root/.openclaw \
    -v ./logs:/tmp/openclaw \
    openclaw-runtime openclaw gateway
fi
