#!/bin/bash
podman build --build-arg CACHE_BYPASS=$(date +%s) --cgroup-manager=cgroupfs --security-opt label=disable -t openclaw-base -f Dockerfile.base .
