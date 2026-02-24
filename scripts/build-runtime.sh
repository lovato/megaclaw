#!/bin/bash
podman build -f Dockerfile.runtime -t openclaw-runtime .
podman run -it --network=host --name openclaw-runtime -v ./db:/root/.openclaw openclaw-runtime
podman commit openclaw-runtime openclaw-runtime
podman rm openclaw-runtime
