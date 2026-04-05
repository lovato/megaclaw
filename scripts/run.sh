#!/bin/bash
set -e

MODE="${1:-interactive}"

# Remove any stale container left behind by a previous ctrl-c or crash
podman rm -f megaclaw 2>/dev/null || true

# Ensure persistent config dirs exist before mounting
mkdir -p ./db/config

if [ "$MODE" = "daemon" ]; then
  podman run -d --rm \
    --name megaclaw \
    --network=host \
    -v ./db:/root/.openclaw \
    -v ./db/config:/root/.config \
    -v ./logs:/tmp/openclaw \
    megaclaw-runtime openclaw gateway
else
  podman run -it --rm \
    --name megaclaw \
    --network=host \
    -v ./db:/root/.openclaw \
    -v ./db/config:/root/.config \
    -v ./logs:/tmp/openclaw \
    megaclaw-runtime openclaw gateway
fi
