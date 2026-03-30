#!/bin/bash
set -e

MODE="${1:-interactive}"

# Remove any stale container left behind by a previous ctrl-c or crash
podman rm -f megaclaw 2>/dev/null || true

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
