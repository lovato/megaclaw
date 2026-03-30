#!/bin/bash
set -e

MODE="${1:-interactive}"

if [ "$MODE" = "daemon" ]; then
  podman run -d --rm \
    --name megaclaw \
    --network=host \
    -v ./db:/root/.openclaw \
    -v ./logs:/tmp/openclaw \
    megaclaw-runtime openclaw gateway
else
  podman run -it --rm \
    --name megaclaw \
    --network=host \
    -v ./db:/root/.openclaw \
    -v ./logs:/tmp/openclaw \
    megaclaw-runtime openclaw gateway
fi
