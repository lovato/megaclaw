#!/bin/bash
set -e

BACKUP_FILE="megaclaw-db.zip"
DB_GITIGNORE="./db/.gitignore"
DB_GITIGNORE_CONTENT="*
!.gitignore"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: $BACKUP_FILE not found."
  exit 1
fi

extra_files=$(find ./db -mindepth 1 -not -name '.gitignore' 2>/dev/null | wc -l)
if [ "$extra_files" -gt 0 ]; then
  echo "Error: db folder is not clean. Remove everything except .gitignore before restoring."
  echo ""
  echo "Files found:"
  find ./db -mindepth 1 -not -name '.gitignore'
  exit 1
fi

unzip "$BACKUP_FILE"

if [ ! -f "$DB_GITIGNORE" ]; then
  printf "%s\n" "$DB_GITIGNORE_CONTENT" > "$DB_GITIGNORE"
  echo "Restored missing db/.gitignore"
fi

echo "Restore complete."
