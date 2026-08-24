#!/bin/bash
# ------------------------------------------------------------
# SafeDelete.sh - safer deletion of files/directories from a list
#
# Usage:
# ./SafeDelete.sh <list_file> [--dry-run|--force] [--dir <directory>] [--recursive]
#
# Modes:
# --dry-run   Only prints what would be deleted
# --force     Deletes without asking for confirmation
# --dir DIR   Search in this directory (instead of assuming full paths)
# --recursive Search subdirectories too
# ------------------------------------------------------------

LIST_FILE="$1"
shift

MODE="normal"
BASE_DIR=""
RECURSIVE=false

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run" ;;
    --force) MODE="force" ;;
    --dir) BASE_DIR="$2"; shift ;;
    --recursive) RECURSIVE=true ;;
    *) echo "❌ Unknown option: $1"; exit 1 ;;
  esac
  shift
done

if [ -z "$LIST_FILE" ]; then
  echo "❌ Error: No list file provided."
  echo "Usage: $0 <list_file> [--dry-run|--force] [--dir <directory>] [--recursive]"
  exit 1
fi

if [ ! -f "$LIST_FILE" ]; then
  echo "❌ Error: File '$LIST_FILE' does not exist."
  exit 1
fi

# --- Main loop ---
while IFS= read -r pattern; do
  if [ -z "$pattern" ] || [[ "$pattern" =~ ^# ]]; then
    continue
  fi

  # Determine search command
  if [ -n "$BASE_DIR" ]; then
    if $RECURSIVE; then
      matches=$(find "$BASE_DIR" -type f -name "$pattern")
    else
      matches=$(find "$BASE_DIR" -maxdepth 1 -type f -name "$pattern")
    fi
  else
    # If no base dir given, assume line is a full path
    matches="$pattern"
  fi

  if [ -z "$matches" ]; then
    echo "⚠️ No matches found for: $pattern"
    continue
  fi

  for target in $matches; do
    case "$MODE" in
      "dry-run")
        echo "👉 Would delete: $target"
        ;;
      "force")
        rm -v "$target" && echo "🗑️ Deleted: $target" || echo "❌ Failed: $target"
        ;;
      "normal")
        read -p "❓ Delete '$target'? [y/N] " answer
        case "$answer" in
          [Yy]* ) rm -v "$target" && echo "🗑️ Deleted: $target" ;;
          * ) echo "⏩ Skipped: $target" ;;
        esac
        ;;
    esac
  done
done < "$LIST_FILE"
