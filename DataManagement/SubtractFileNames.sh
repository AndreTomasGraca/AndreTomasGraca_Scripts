#!/bin/bash
# ------------------------------------------------------------
# SubtractFileNames.sh
# Compares two text files and creates a new file which removes lines that had equal content in both files.
# Ideal to create a new list with the symmetric difference (the negative of the intersection of two goroups) from two chosen text files.  
#
# Usage:
#   ./SubtractFileNames.sh fileA.txt fileB.txt
#
# Output:
#   FileNames_Subtracted.txt
# ------------------------------------------------------------
 
FILE_A="$1"
FILE_B="$2"
OUTPUT="FileNames_Subtracted.txt"
 
if [ $# -ne 2 ]; then
    echo "❌ Usage: $0 fileA.txt fileB.txt"
    exit 1
fi
 
if [ ! -f "$FILE_A" ]; then
    echo "❌ Error: File '$FILE_A' not found."
    exit 1
fi
 
if [ ! -f "$FILE_B" ]; then
    echo "❌ Error: File '$FILE_B' not found."
    exit 1
fi
 
# Remove matching lines
grep -F -v -x -f "$FILE_B" "$FILE_A" > "$OUTPUT"
 
echo "✅ Done. Non-matching file names written to $OUTPUT"
