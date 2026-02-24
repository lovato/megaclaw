#!/bin/bash
podman build --build-arg CACHE_BYPASS=$(date +%s) -f Dockerfile.runtime -t openclaw-runtime .
podman rm -f openclaw-runtime 2>/dev/null || true
podman run -it --network=host --name openclaw-runtime -v ./db:/root/.openclaw openclaw-runtime
podman commit openclaw-runtime openclaw-runtime
podman rm openclaw-runtime
