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

NPM_PACKAGES=""
if [ -f "$SKILL_MD" ]; then
  # Extract packages from lines like: npm install -g todoist-ts-cli@^0.2.0
  NPM_PACKAGES=$(grep -oP '(?<=npm install -g )\S+' "$SKILL_MD" \
    | sort -u \
    | tr '\n' ' ')
  echo "  npm deps found: ${NPM_PACKAGES:-none}"
else
  echo "  Warning: SKILL.md not found at $SKILL_MD"
fi

# Resolve semver ranges to exact versions via npm view (runs inside container).
# e.g. todoist-ts-cli@^0.2.0 → todoist-ts-cli@0.2.1
resolve_packages() {
  local raw="$1"
  local resolved=""
  for pkg in $raw; do
    exact=$(podman run --rm --network=host megaclaw-runtime \
      npm view "$pkg" version 2>/dev/null | tail -1)
    if [ -n "$exact" ]; then
      # strip any range specifier from the package name before appending version
      name=$(echo "$pkg" | sed 's/@[^@]*$//' | sed 's/^\(@[^@]*\)@.*/\1/')
      resolved="$resolved ${name}@${exact}"
      echo "  resolved: $pkg → ${name}@${exact}" >&2
    else
      resolved="$resolved $pkg"
      echo "  warning: could not resolve $pkg — keeping as-is" >&2
    fi
  done
  echo "$resolved"
}

if [ -n "$NPM_PACKAGES" ]; then
  NPM_PACKAGES=$(resolve_packages "$NPM_PACKAGES")
fi

# Update deps.json on the host
python3 - "$SLUG" $NPM_PACKAGES <<'EOF'
import json, os, sys

slug = sys.argv[1]
packages = sys.argv[2:]  # already exact versions from resolve step

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
