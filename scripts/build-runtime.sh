#!/bin/bash
podman build -f Dockerfile.runtime -t openclaw-runtime .
podman run -it --network=host --name openclaw-onboard -v ./db:/root/.openclaw openclaw-runtime
podman commit openclaw-onboard openclaw-runtime
podman rm openclaw-onboard
