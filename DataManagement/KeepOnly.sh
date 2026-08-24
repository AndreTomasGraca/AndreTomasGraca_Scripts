#!/bin/bash
# ------------------------------------------------------------
# KeepOnly.sh - delete everything in a directory *except* the listed files
#
# Usage:
#   ./KeepOnly.sh <directory> <keep_list.txt> [--dry-run|--force]
#
# keep_list.txt should contain one filename per line (no paths).
# Lines starting with '#' or empty lines are ignored.
#
# Example:
#   ./KeepOnly.sh /data/myproject keep_list.txt
#   ./KeepOnly.sh /data/myproject keep_list.txt --dry-run
#   ./KeepOnly.sh /data/myproject keep_list.txt --force
# ------------------------------------------------------------

TARGET_DIR="$1"
KEEP_LIST="$2"
MODE="normal"

if [ -z "$TARGET_DIR" ] || [ -z "$KEEP_LIST" ]; then
    echo "❌ Usage: $0 <directory> <keep_list.txt> [--dry-run|--force]"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

if [ ! -f "$KEEP_LIST" ]; then
    echo "❌ Error: Keep list '$KEEP_LIST' not found."
    exit 1
fi

if [ "$3" == "--dry-run" ]; then
    MODE="dry-run"
elif [ "$3" == "--force" ]; then
    MODE="force"
fi

# Load keep list into an array
mapfile -t KEEP_ARRAY < <(grep -vE '^\s*$|^#' "$KEEP_LIST")

# Function to check if a file is in KEEP_ARRAY
should_keep() {
    local fname="$1"
    for k in "${KEEP_ARRAY[@]}"; do
        if [ "$k" == "$fname" ]; then
            return 0  # match found → keep
        fi
    done
    return 1  # no match → delete
}

# Find all files (no directories) recursively
find "$TARGET_DIR" -type f | while read -r file; do
    fname=$(basename "$file")

    if should_keep "$fname"; then
        echo "✅ Keeping: $file"
    else
        case "$MODE" in
            "dry-run")
                echo "👉 Would delete: $file"
                ;;
            "force")
                rm "$file" && echo "🗑️  Deleted: $file" || echo "❌ Failed: $file"
                ;;
            "normal")
                read -p "❓ Delete '$file'? [y/N] " answer
                case "$answer" in
                    [Yy]* ) rm "$file" && echo "🗑️  Deleted: $file" ;;
                    * ) echo "⏩ Skipped: $file" ;;
                esac
                ;;
        esac
    fi
done
