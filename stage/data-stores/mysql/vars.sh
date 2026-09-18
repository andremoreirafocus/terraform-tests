#!/usr/bin/env bash

# Load .env from the same directory as this script.
source "$(dirname "${BASH_SOURCE[0]}")/.env" || return 1

# Check required values without printing them.
if [[ -z "${DB_USERNAME:-}" || -z "${DB_PASSWORD:-}" ]]; then
  echo "Set DB_USERNAME and DB_PASSWORD in .env" >&2
  return 1
fi
export TF_VAR_db_username="${DB_USERNAME}"
export TF_VAR_db_password="${DB_PASSWORD}"