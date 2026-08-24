# THIS IS THE PARALLELIZED VERSION OF THE ORIGINAL SCRIPT 'FilesOrganize_MacOS.sh'
# 
# ---------------
#   What It Does
# ---------------
#
# Briefly:  
#       - This script is a file sorted/segregator for MacOS.
#       - It looks inside a given directory for JPG and MP4 files that share a common file naming structure, retrieves their file date and organizes them in new directories which are named according to their YYMMDD date.
#
# Note!
#       - This script is specifically written for macOS: mdls and the BSD/macOS form of stat and date are not portable to a typical Linux system.
#       - As it is written now, the script will look for files whose name matches the filenaming "Snap*", but that can easily be changed (more details below).
#
# In detail:
#   1) Takes a source folder and required destination folder as arguments.
#   2) Looks only in the source folder itself (not subfolders) for files named:
#       - Snap*.jpg
#       - Snap*.jpeg
#       - Snap*.mp4
#       - Can easily be changed to look for anything different sets of files with different name: just replace all "Snap" occurences in the scripts by whatever you wish, according to your file names.
#   3) Determines each file's date:
#       - JPG/JPEG: EXIF DateTimeOriginal, if exiftool is installed.
#       - MP4: metadata CreateDate, if exiftool is installed.
#       - Otherwise, macOS Spotlight metadata via mdls.
#       - Finally, the filesystem modification date via stat.
#   4) Converts the date to YYMMDD, e.g. 2026-08-24 → 260824.
#   5) Creates a folder such as 260824 inside the source directory and puts the file there.
#   6) By default, it copies the files using rsync. With --move, it actually moves them.
#   7) Finally, it copies all the resulting six-digit date folders from the source into the specified destination.
#   8) --dry-run shows what it would do without changing anything.
#
# One important detail: the date folders are created inside the source first, and then those folders are copied to the destination. So the destination ends up with folders like 260824, 260825, etc.
#
# ------------
#   Dependencies to Install
# ------------
# brew install exiftool
#
# ------------
#   Usage
# ------------
# Simple Usage: ~/FilesOrganize.sh -s /path/to/source -d /path/to/destination
# Move Instead of Copy: ~/FilesOrganize.sh -s /path/to/source -d /path/to/destination --move
# Move Instead of Copy (alternatively): ~/FilesOrganize.sh -s /path/to/source -d /path/to/destination -m
# Dry-run: ~/FilesOrganize.sh -s /path/to/source -d /path/to/destination --dry-run
#
#


#!/bin/bash

set -euo pipefail

# ---- Defaults ----
SOURCE="."
DEST=""
MODE="copy"   # copy (default) or move
DRY_RUN=false
JOBS=4        # parallel jobs (default)

# Detect exiftool
if command -v exiftool >/dev/null 2>&1; then
    HAS_EXIFTOOL=true
else
    HAS_EXIFTOOL=false
fi

# ---- Parse arguments ----
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source)
            SOURCE="$2"
            shift 2
            ;;
        -d|--destination)
            DEST="$2"
            shift 2
            ;;
        -m|--move)
            MODE="move"
            shift
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ---- Validate ----
if [[ -z "$DEST" ]]; then
    echo "Error: Destination folder is required (-d)"
    exit 1
fi

if [[ ! -d "$SOURCE" ]]; then
    echo "Error: Source folder does not exist"
    exit 1
fi

mkdir -p "$DEST"

echo "Source: $SOURCE"
echo "Destination: $DEST"
echo "Mode: $MODE"
echo "Dry run: $DRY_RUN"
echo "Parallel jobs: $JOBS"
echo "Exiftool available: $HAS_EXIFTOOL"
echo "----------------------------------"

# ---- Export vars/functions for parallel jobs ----
export SOURCE DEST MODE DRY_RUN HAS_EXIFTOOL

get_date() {
    FILE="$1"
    EXT="${FILE##*.}"
    EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

    DATE=""

    if [[ "$EXT_LOWER" == "jpg" || "$EXT_LOWER" == "jpeg" ]]; then
        if [[ "$HAS_EXIFTOOL" == true ]]; then
            DATE=$(exiftool -DateTimeOriginal -d "%Y-%m-%d %H:%M:%S" -s3 "$FILE" 2>/dev/null)
        fi

        if [[ -z "$DATE" ]]; then
            DATE=$(mdls -name kMDItemContentCreationDate -raw "$FILE" 2>/dev/null)
        fi

    elif [[ "$EXT_LOWER" == "mp4" ]]; then
        if [[ "$HAS_EXIFTOOL" == true ]]; then
            DATE=$(exiftool -CreateDate -d "%Y-%m-%d %H:%M:%S" -s3 "$FILE" 2>/dev/null)
        fi

        if [[ -z "$DATE" ]]; then
            DATE=$(mdls -name kMDItemContentCreationDate -raw "$FILE" 2>/dev/null)
        fi
    fi

    if [[ -z "$DATE" || "$DATE" == "(null)" ]]; then
        DATE=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$FILE")
    fi

    date -j -f "%Y-%m-%d %H:%M:%S" "$DATE" "+%y%m%d" 2>/dev/null || echo "000000"
}

export -f get_date

process_file() {
    FILE="$1"

    DATE=$(get_date "$FILE")
    TARGET_DIR="$SOURCE/$DATE"

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY] mkdir -p \"$TARGET_DIR\""
        if [[ "$MODE" == "move" ]]; then
            echo "[DRY] mv \"$FILE\" \"$TARGET_DIR/\""
        else
            echo "[DRY] rsync -a \"$FILE\" \"$TARGET_DIR/\""
        fi
    else
        mkdir -p "$TARGET_DIR"

        if [[ "$MODE" == "move" ]]; then
            mv "$FILE" "$TARGET_DIR/"
        else
            rsync -a "$FILE" "$TARGET_DIR/"
        fi
    fi
}

export -f process_file

# ---- Parallel processing ----
find "$SOURCE" -maxdepth 1 -type f \( -iname "Snap*.jpg" -o -iname "Snap*.jpeg" -o -iname "Snap*.mp4" \) -print0 |
xargs -0 -n 1 -P "$JOBS" bash -c 'process_file "$0"' 

echo "----------------------------------"
echo "Copying organized folders to destination..."

if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY] rsync -a \"$SOURCE\"/[0-9][0-9][0-9][0-9][0-9][0-9] \"$DEST\"/"
else
    rsync -a "$SOURCE"/[0-9][0-9][0-9][0-9][0-9][0-9] "$DEST"/
fi

echo "Done."