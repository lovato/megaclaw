#!/bin/bash
set -e

# Runs INSIDE the container during task build:runtime (second pass, before final commit).
# Reads /etc/megaclaw/deps.json and installs all skill definitions + npm dependencies.

DEPS_FILE="/etc/megaclaw/deps.json"
WORKDIR="/root/.openclaw/workspace"

if [ ! -f "$DEPS_FILE" ]; then
  echo "No deps.json found at $DEPS_FILE, skipping."
  exit 0
fi

python3 - <<'EOF'
import json, subprocess, shutil, sys, os

with open("/etc/megaclaw/deps.json") as f:
    deps = json.load(f)

def run(cmd):
    r = subprocess.run(cmd)
    if r.returncode != 0:
        print(f"  warning: {' '.join(cmd)} exited {r.returncode}", file=sys.stderr)

# 1. Core npm packages (e.g. clawhub itself if not pre-installed)
core_npm = deps.get("core", {}).get("npm", [])
if core_npm:
    print("==> Installing core npm packages...")
    for pkg in core_npm:
        print(f"  npm install -g {pkg}")
        run(["npm", "install", "-g", pkg])

# 2. Skills + their npm deps
skills = deps.get("skills", {})
if not skills:
    print("==> No skills defined.")
    sys.exit(0)

if not shutil.which("clawhub"):
    print("==> Warning: clawhub not found — skipping skill installs.")
    print("    Ensure clawhub is selected during onboarding or added to core.npm in deps.json.")
else:
    print("==> Installing skills...")
    for slug, skill in skills.items():
        print(f"  clawhub install {slug}")
        run(["clawhub", "--workdir", "/root/.openclaw/workspace",
             "install", slug, "--no-input"])

        for pkg in skill.get("npm", []):
            print(f"  npm install -g {pkg}")
            run(["npm", "install", "-g", pkg])

print("==> install-deps complete.")
EOF
