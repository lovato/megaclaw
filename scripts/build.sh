#!/bin/bash
podman build --cgroup-manager=cgroupfs --security-opt label=disable -t openclaw-local .
