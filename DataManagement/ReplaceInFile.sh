#!/bin/bash
# ------------------------------------------------------------
# ReplaceInFile.sh
# Replace a literal substring in each line of a file.
#
# Usage:
#   ./ReplaceInFile.sh <input_file> <output_file> <pattern> <replacement>
#
# Example:
#   ./ReplaceInFile.sh accepted_micrographs.txt final.txt \
#       "_EER_patch_aligned_doseweighted.mrc" "_EER.eer"
# ------------------------------------------------------------

INPUT_FILE="$1"
OUTPUT_FILE="$2"
PATTERN="$3"
REPLACEMENT="$4"

# Check arguments
if [ $# -ne 4 ]; then
    echo "❌ Usage: $0 <input_file> <output_file> <pattern> <replacement>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Error: File '$INPUT_FILE' not found."
    exit 1
fi

# Escape special characters for sed so PATTERN is treated literally
ESCAPED_PATTERN=$(printf '%s\n' "$PATTERN" | sed 's/[.[\*^$/]/\\&/g')
ESCAPED_REPLACEMENT=$(printf '%s\n' "$REPLACEMENT" | sed 's/[&/\]/\\&/g')

# Perform replacement
sed "s|$ESCAPED_PATTERN|$ESCAPED_REPLACEMENT|g" "$INPUT_FILE" > "$OUTPUT_FILE"

echo "✅ Done. Output saved to $OUTPUT_FILE"