#!/bin/bash
# ------------------------------------------------------------
# ReplaceChars.sh - Replace characters in each line of a file
#
# Usage:
# ./ReplaceChars.sh <input_file> <start_pos> <num_chars> <replacement>
#
# Example:
# ./ReplaceChars.sh mylist.txt 6 3 XYZ
# → replaces 3 characters starting at position 6 with "XYZ"
# ------------------------------------------------------------

INPUT_FILE="$1"
START="$2" # starting position (1-based)
LENGTH="$3" # number of chars to replace
REPL="$4"

if [ $# -ne 4 ]; then
 echo "❌ Usage: $0 <input_file> <start_pos> <num_chars> <replacement>"
 exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
 echo "❌ Error: File '$INPUT_FILE' not found."
 exit 1
fi

while IFS= read -r line; do
 # Bash substring handling (1-based → convert to 0-based)
 prefix=${line:0:$((START-1))}
 suffix=${line:$((START-1+LENGTH))}
 echo "${prefix}${REPL}${suffix}"
done < "$INPUT_FILE"
