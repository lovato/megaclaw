#!/bin/bash
podman run -d --rm \
  --name openclaw \
  --ipc=host \
  -p 18789:18789 \
  -v ./db:/root/.openclaw \
  -v ./logs:/tmp/openclaw \
  openclaw-local
