#!/bin/bash
set -e

BACKUP_FILE="megaclaw-db.zip"

if [ -f "$BACKUP_FILE" ]; then
  echo "Error: $BACKUP_FILE already exists."
  echo "Delete it manually before creating a new backup."
  exit 1
fi

if [ -z "$(find ./db -mindepth 1 -not -name '.gitignore' 2>/dev/null)" ]; then
  echo "Warning: db folder appears empty — no config found."
  read -r -p "Continue anyway? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
fi

read -r -p "Password protect the backup? [y/N] " use_password
if [[ "$use_password" =~ ^[Yy]$ ]]; then
  zip -r -e "$BACKUP_FILE" db/
else
  zip -r "$BACKUP_FILE" db/
fi

echo "Backup created: $BACKUP_FILE"
