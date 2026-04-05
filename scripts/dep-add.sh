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
  clawhub install "$SLUG" --force --no-input

# Read SKILL.md on the host to discover npm dependencies
SKILL_MD="./db/workspace/skills/${SKILL_NAME}/SKILL.md"

# Get npm package names and version ranges from SKILL.md.
# Resolve ranges to exact versions using semver.maxSatisfying; fall back to @latest.
NPM_PACKAGES=""
if [ -f "$SKILL_MD" ]; then
  RAW_DEPS=$(grep -oP '(?<=npm install -g )\S+' "$SKILL_MD" | sort -u)
  echo "  npm deps in SKILL.md: ${RAW_DEPS:-none}"
  for dep in $RAW_DEPS; do
    # Split into name and range (handles scoped packages like @scope/pkg@^1.0)
    if echo "$dep" | grep -qP '^@'; then
      name=$(echo "$dep" | grep -oP '^@[^/]+/[^@]+')
      range=$(echo "$dep" | sed "s|^${name}@\?||")
    else
      name=$(echo "$dep" | cut -d@ -f1)
      range=$(echo "$dep" | cut -d@ -f2-)
      [ "$range" = "$name" ] && range=""
    fi

    if [ -n "$range" ]; then
      resolved=$(podman run --rm --network=host megaclaw-runtime node -e "
        const { execSync } = require('child_process');
        const semver = require('semver');
        try {
          const out = execSync('npm view ${name} versions --json 2>/dev/null').toString().trim();
          const versions = JSON.parse(out);
          const r = semver.maxSatisfying(Array.isArray(versions) ? versions : [versions], '${range}');
          console.log(r || '');
        } catch(e) { console.log(''); }
      " 2>/dev/null)
    fi

    if [ -n "$resolved" ]; then
      echo "  resolved: ${dep} → ${name}@${resolved}"
      NPM_PACKAGES="$NPM_PACKAGES ${name}@${resolved}"
    else
      echo "  fallback to latest: ${name}"
      NPM_PACKAGES="$NPM_PACKAGES ${name}@latest"
    fi
  done
else
  echo "  Warning: SKILL.md not found at $SKILL_MD"
fi

# Get the skill version from clawhub inspect (informational only)
SKILL_VERSION=$(podman run --rm --network=host megaclaw-runtime \
  clawhub inspect "$SLUG" --no-input 2>/dev/null \
  | grep -oP '(?<=Tags: latest=)\S+')
[ -n "$SKILL_VERSION" ] && echo "  skill version: $SKILL_VERSION"

# Update deps.json on the host
python3 - "$SLUG" $NPM_PACKAGES <<'EOF'
import json, os, sys

slug = sys.argv[1]
packages = sys.argv[2:]

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
