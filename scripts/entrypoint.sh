#!/bin/bash
set -e

# Runs INSIDE the container on every startup.
# Passes through to the given command — no automatic skill updates.
# Use 'task update:skills' on the host to explicitly update skill definitions.

# Ensure standard workspace directories exist
mkdir -p /root/.openclaw/workspace/screenshots

exec "$@"
