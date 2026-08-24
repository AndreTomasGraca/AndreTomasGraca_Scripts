#!/bin/bash
# CompressTARGZ.sh - Compress tar.gz outputting a log file with start and end date.
# This is suitable to test or log how it takes to compress the desired set of files. 
# Usage: ./CompressTARGZ.sh -s <source_dir> -d <archive_path> [-l <log_file>] [--dry-run]

set -e

# Default values
LOGFILE=""
DRYRUN=0

# Parse options
while [[ "$#" -gt 0 ]]; do
 case $1 in
 -s) SOURCE="$2"; shift ;;
 -d) ARCHIVE="$2"; shift ;;
 -l) LOGFILE="$2"; shift ;;
 --dry-run) DRYRUN=1 ;;
 -h|--help)
 echo "Usage: $0 -s <source_dir> -d <archive_path> [-l <log_file>] [--dry-run]"
 exit 0 ;;
 *) echo "Unknown parameter passed: $1"; exit 1 ;;
 esac
 shift
done

# Check required arguments
if [[ -z "$SOURCE" || -z "$ARCHIVE" ]]; then
 echo "Error: source directory and archive path are required."
 echo "Usage: $0 -s <source_dir> -d <archive_path> [-l <log_file>] [--dry-run]"
 exit 1
fi

# If log file not specified, create one in the same folder as the archive
if [[ -z "$LOGFILE" ]]; then
 LOGFILE="$(dirname "$ARCHIVE")/$(basename "${ARCHIVE%.tar.gz}").log"
fi

# Ensure the parent directory of the archive exists
mkdir -p "$(dirname "$ARCHIVE")"

# Record start time
echo "START $(date)" | tee -a "$LOGFILE"

if [[ "$DRYRUN" -eq 1 ]]; then
 echo "DRY RUN: listing files that would be archived..." | tee -a "$LOGFILE"
 tar -czvf "$ARCHIVE" --list "$SOURCE" 2>&1 | tee -a "$LOGFILE"
else
 # Run tar with verbose output, logging everything
 tar -czvf "$ARCHIVE" "$SOURCE" 2>&1 | tee -a "$LOGFILE"
fi

# Record end time
echo "END $(date)" | tee -a "$LOGFILE"