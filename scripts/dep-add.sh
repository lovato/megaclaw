#!/bin/bash
set -e

# Runs on the HOST.
# Takes a ClaWHub URL, installs the skill into ./db to get its SKILL.md,
# parses npm dependencies, and updates deps.json in the repo.
#
# Usage: dep-add https://clawhub.ai/mjrussell/todoist

URL="$1"

if [ -z "$URL" ]; then
  echo "Usage: task dep:add -- <clawhub-url>"
  echo "Example: task dep:add -- https://clawhub.ai/mjrussell/todoist"
  exit 1
fi

if ! podman image exists megaclaw-runtime; then
  echo "Error: megaclaw-runtime image not found. Run 'task build:runtime' first."
  exit 1
fi

# Extract slug: https://clawhub.ai/mjrussell/todoist → todoist
# ClaWHub slugs are the skill name only — the author segment in the URL is not part of the slug.
SLUG=$(echo "$URL" | sed 's|.*clawhub\.ai/[^/]*/||; s|.*clawhub\.ai/||')
SKILL_NAME="$SLUG"

echo "==> Adding skill: $SLUG"

# Install skill definition into ./db via a throwaway container
echo "==> Fetching skill definition from ClaWHub..."
podman run --rm \
  --network=host \
  -v "./db:/root/.openclaw" \
  megaclaw-runtime \
  clawhub install "$SLUG" --no-input

# Read SKILL.md on the host to discover npm dependencies
SKILL_MD="./db/workspace/skills/${SKILL_NAME}/SKILL.md"

NPM_PACKAGES=""
if [ -f "$SKILL_MD" ]; then
  # Extract package names from lines like: npm install -g todoist-ts-cli@^0.2.0
  NPM_PACKAGES=$(grep -oP '(?<=npm install -g )\S+' "$SKILL_MD" \
    | sed 's/@[^@]*$//' \
    | sort -u \
    | tr '\n' ' ')
  echo "  npm deps found: ${NPM_PACKAGES:-none}"
else
  echo "  Warning: SKILL.md not found at $SKILL_MD"
fi

# Update deps.json on the host
python3 - "$SLUG" $NPM_PACKAGES <<'EOF'
import json, os, sys

slug = sys.argv[1]
packages = [f"{p}@latest" for p in sys.argv[2:]]

path = "db/deps.json"
if os.path.exists(path):
    with open(path) as f:
        deps = json.load(f)
else:
    # Seed from default template if available
    import shutil
    if os.path.exists("deps.default.json"):
        shutil.copy("deps.default.json", path)
        with open(path) as f:
            deps = json.load(f)
    else:
        deps = {"version": 1, "core": {"npm": []}, "skills": {}}

deps["skills"][slug] = {"npm": packages}

with open(path, "w") as f:
    json.dump(deps, f, indent=2)
    f.write("\n")

print(f"  deps.json updated: {slug} -> npm: {packages}")
EOF

echo "==> Done. Run 'task build:runtime' to bake the new skill into the image."
