#!/bin/bash
podman run -it --rm --network=host -v ./db:/root/.openclaw openclaw-local openclaw onboard
