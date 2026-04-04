#!/bin/bash
set -e

# Runs INSIDE the container on every startup.
# When launching the gateway: updates skill definitions from deps.json (fast, no npm).
# For any other command (onboard, install-deps, etc.): passes through directly.

DEPS_FILE="/etc/megaclaw/deps.json"

if [ "$1" = "openclaw" ] && [ "$2" = "gateway" ]; then
  if [ -f "$DEPS_FILE" ] && command -v clawhub >/dev/null 2>&1; then
    python3 - <<'EOF'
import json, subprocess

with open("/etc/megaclaw/deps.json") as f:
    deps = json.load(f)

skills = list(deps.get("skills", {}).keys())
if skills:
    print("==> Updating skills...")
    for slug in skills:
        print(f"  {slug}")
        subprocess.run(
            ["clawhub", "update", slug, "--no-input"],
            check=False
        )
EOF
  fi
fi

exec "$@"
