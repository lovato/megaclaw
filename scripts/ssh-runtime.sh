#!/bin/bash
set -e

mkdir -p ./db/config
podman run -it --rm --network=host \
  -v ./db:/root/.openclaw \
  -v ./db/config:/root/.config \
  megaclaw-runtime /bin/bash
