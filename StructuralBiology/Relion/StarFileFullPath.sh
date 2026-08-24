#!/bin/bash
# ------------------------------------------------------------
# resolve_relion_paths.sh
#
# Usage:
#   ./resolve_relion_paths.sh input.star output.star
#
# Description:
#   Reads a RELION .star file containing only filenames (no paths)
#   under the header '_rlnMicrographMovieName #1', searches recursively
#   for these files in the current directory, and writes a new .star
#   file with relative paths instead of bare filenames.
#
# ------------------------------------------------------------

input=$1
output=$2

if [[ -z "$input" || -z "$output" ]]; then
    echo "Usage: $0 input.star output.star"
    exit 1
fi

# Read header lines until we hit the data section
header=$(awk '/^data_/{print;getline;print;getline;print;getline;print;exit}' "$input")

# Write header to output file
echo "$header" > "$output"

# Extract filenames (skip header lines)
awk 'NR>4 {print $1}' "$input" | while read -r filename; do
    # Find file recursively
    found=$(find . -type f -name "$filename" -print -quit)
    if [[ -n "$found" ]]; then
        # Write relative path without leading "./"
        relpath="${found#./}"
        echo "$relpath" >> "$output"
    else
        echo "WARNING: File not found -> $filename" >&2
    fi
done

echo "✅ New .star file created: $output"

