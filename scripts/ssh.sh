#!/bin/bash
IMAGE=$(podman image exists openclaw-runtime && echo openclaw-runtime || echo openclaw-base)
podman run -it --rm --network=host -v ./db:/root/.openclaw $IMAGE /bin/bash
