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

#!/bin/bash

set -euo pipefail

# ---- Defaults ----
# Source defaults to the current directory.
# Destination must be supplied with -d/--destination.
# Default behavior is to COPY files; --move changes this to MOVE.
# --dry-run only displays the operations without executing them.
SOURCE="."
DEST=""
MODE="copy"   # copy (default) or move
DRY_RUN=false


# ---- Detect exiftool ----
# exiftool is optional. If available, it gives us more reliable
# photo/video metadata such as the original capture date.
if command -v exiftool >/dev/null 2>&1; then
    HAS_EXIFTOOL=true
else
    HAS_EXIFTOOL=false
fi


# ---- Parse arguments ----
# Supported options:
#   -s / --source       Source directory
#   -d / --destination  Destination directory (required)
#   -m / --move         Move instead of copy
#   --dry-run           Show operations without making changes
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


# ---- Validate arguments/directories ----
# Destination is mandatory.
if [[ -z "$DEST" ]]; then
    echo "Error: Destination folder is required (-d)"
    exit 1
fi

# Source must already exist and be a directory.
if [[ ! -d "$SOURCE" ]]; then
    echo "Error: Source folder does not exist"
    exit 1
fi

# Create the destination if it doesn't exist.
mkdir -p "$DEST"

echo "Source: $SOURCE"
echo "Destination: $DEST"
echo "Mode: $MODE"
echo "Dry run: $DRY_RUN"
echo "Exiftool available: $HAS_EXIFTOOL"
echo "----------------------------------"


# ---- Function: extract date from a media file ----
#
# Attempts to find the file's original creation/capture date.
#
# Priority for JPG/JPEG:
#   1. EXIF DateTimeOriginal (if exiftool is available)
#   2. macOS Spotlight creation date (mdls)
#
# Priority for MP4:
#   1. MP4 CreateDate (if exiftool is available)
#   2. macOS Spotlight creation date (mdls)
#
# Final fallback:
#   filesystem modification date (stat)
#
# The resulting date is converted to YYMMDD.
# Example:
#   2026-08-24 09:15:00 -> 260824
get_date() {
    FILE="$1"

    # Extract the file extension and normalize it to lowercase.
    EXT="${FILE##*.}"
    EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

    DATE=""

    if [[ "$EXT_LOWER" == "jpg" || "$EXT_LOWER" == "jpeg" ]]; then

        # For photos, prefer the EXIF "original capture" date.
        if [[ "$HAS_EXIFTOOL" == true ]]; then
            DATE=$(exiftool \
                -DateTimeOriginal \
                -d "%Y-%m-%d %H:%M:%S" \
                -s3 "$FILE" 2>/dev/null)
        fi

        # If EXIF isn't available, ask macOS Spotlight for
        # the file's content creation date.
        if [[ -z "$DATE" ]]; then
            DATE=$(mdls \
                -name kMDItemContentCreationDate \
                -raw "$FILE" 2>/dev/null)
        fi

    elif [[ "$EXT_LOWER" == "mp4" ]]; then

        # For videos, use the MP4 CreateDate metadata.
        if [[ "$HAS_EXIFTOOL" == true ]]; then
            DATE=$(exiftool \
                -CreateDate \
                -d "%Y-%m-%d %H:%M:%S" \
                -s3 "$FILE" 2>/dev/null)
        fi

        # Fall back to macOS Spotlight metadata.
        if [[ -z "$DATE" ]]; then
            DATE=$(mdls \
                -name kMDItemContentCreationDate \
                -raw "$FILE" 2>/dev/null)
        fi
    fi


    # If no metadata date was found, use the filesystem
    # modification date as the last resort.
    if [[ -z "$DATE" || "$DATE" == "(null)" ]]; then
        DATE=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$FILE")
    fi


    # Convert:
    #   YYYY-MM-DD HH:MM:SS
    #
    # into:
    #   YYMMDD
    #
    # Example:
    #   2026-08-24 09:15:00 -> 260824
    #
    # If conversion fails, return "000000".
    date -j -f "%Y-%m-%d %H:%M:%S" "$DATE" "+%y%m%d" 2>/dev/null \
        || echo "000000"
}


# ---- Process matching files ----
#
# Look ONLY in SOURCE itself (-maxdepth 1).
#
# It processes files whose names begin with "Snap" and have
# a JPG/JPEG/MP4 extension.
#
# Examples:
#   Snap123.jpg
#   Snapshot01.jpeg
#   Snap20260824.mp4
#
# Files in subdirectories are NOT processed here.
find "$SOURCE" -maxdepth 1 -type f \
    \( -iname "Snap*.jpg" \
    -o -iname "Snap*.jpeg" \
    -o -iname "Snap*.mp4" \) |
while read -r FILE; do

    # Determine the file's capture/creation date.
    DATE=$(get_date "$FILE")

    # Create a directory inside SOURCE named after the date.
    # Example:
    #   /Photos/260824/
    TARGET_DIR="$SOURCE/$DATE"


    # ---- Dry-run mode ----
    # Instead of actually creating/moving/copying anything,
    # print the commands that WOULD be executed.
    if [[ "$DRY_RUN" == true ]]; then

        echo "[DRY] mkdir -p \"$TARGET_DIR\""

        if [[ "$MODE" == "move" ]]; then
            echo "[DRY] mv \"$FILE\" \"$TARGET_DIR/\""
        else
            echo "[DRY] rsync -chrltpDvulP --stats \"$FILE\" \"$TARGET_DIR/\""
        fi


    # ---- Real execution ----
    else
        mkdir -p "$TARGET_DIR"

        if [[ "$MODE" == "move" ]]; then

            # Physically move the original file into the date folder.
            mv "$FILE" "$TARGET_DIR/"

        else

            # Copy the file into the date folder while preserving
            # various file attributes and showing rsync progress.
            rsync -chrltpDvulP --stats "$FILE" "$TARGET_DIR/"
        fi
    fi

done


echo "----------------------------------"
echo "Copying organized folders to destination..."


# ---- Copy the date folders to the final destination ----
#
# Only folders whose names consist of exactly six digits are matched.
#
# Examples:
#   260824
#   260825
#   260901
#
# This is why the previous step creates directories in YYMMDD format.
if [[ "$DRY_RUN" == true ]]; then

    echo "[DRY] rsync -chrltpDvulP --stats \"$SOURCE\"/[0-9][0-9][0-9][0-9][0-9][0-9] \"$DEST\"/"

else

    # Copy all six-digit date directories from SOURCE into DEST.
    rsync -chrltpDvulP --stats \
        "$SOURCE"/[0-9][0-9][0-9][0-9][0-9][0-9] \
        "$DEST"/
fi


echo "Done."