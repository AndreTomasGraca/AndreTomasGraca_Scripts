#!/bin/bash
# MergeFileLists.sh - Output a file with all lines from both files avoiding repetition of common lines
# Usage: ./MergeFileLists.sh file1.txt file2.txt output.txt
 
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <file1.txt> <file2.txt> <output.txt>"
    exit 1
fi
 
file1=$1
file2=$2
output=$3
 
# Concatenate, remove duplicates, sort, and save to output
cat "$file1" "$file2" | sort -u > "$output"
 
echo "✅ Combined list saved to $output"