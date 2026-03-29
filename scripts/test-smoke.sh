#!/bin/bash
set -e

PASS=0
FAIL=0

check() {
  local label="$1"
  shift
  if "$@" 2>/dev/null; then
    echo "  ok  $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL  $label"
    FAIL=$((FAIL + 1))
  fi
}

echo "==> Bash syntax"
for script in scripts/*.sh; do
  check "$script" bash -n "$script"
done

echo "==> Taskfile"
check "taskfile.yaml (yaml syntax)" python3 -c "import yaml, sys; yaml.safe_load(open('taskfile.yaml')) or sys.exit(1)"

echo "==> Dockerfiles"
for df in Dockerfile.*; do
  check "$df exists and is non-empty" test -s "$df"
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
