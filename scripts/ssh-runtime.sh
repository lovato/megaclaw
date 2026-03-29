#!/bin/bash
set -e

podman run -it --rm --network=host -v ./db:/root/.openclaw openclaw-runtime /bin/bash
