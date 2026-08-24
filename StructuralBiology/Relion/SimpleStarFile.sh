#!/bin/bash
# Usage: ./make_relion_star.sh filelist.txt output.star

input=$1
output=$2

echo "data_" > "$output"
echo "" >> "$output"
echo "loop_" >> "$output"
echo "_rlnMicrographMovieName #1" >> "$output"

cat "$input" >> "$output"
