#!/bin/bash
podman run -it --rm \
  --name openclaw \
  --network=host \
  -v ./db:/root/.openclaw \
  -v ./logs:/tmp/openclaw \
  openclaw-local
