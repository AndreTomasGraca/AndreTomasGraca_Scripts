#!/usr/bin/env python3
# MergeFileLists.py - Outputs a file with all lines from both files avoiding repetition of common lines
#Usage: python MergeFileLists.py list1.txt list2.txt merged_list.txt

import sys

def merge_file_lists(file1, file2, output_file):
 # Read both files into sets (automatically removes duplicates)
 with open(file1, "r") as f1:
 paths1 = {line.strip() for line in f1 if line.strip()}

 with open(file2, "r") as f2:
 paths2 = {line.strip() for line in f2 if line.strip()}

 # Union of both sets
 all_paths = sorted(paths1 | paths2)

 # Write the result to the output file
 with open(output_file, "w") as out:
 for path in all_paths:
 out.write(path + "\n")

 print(f"✅ Combined list saved to {output_file} ({len(all_paths)} unique paths).")

if __name__ == "__main__":
 if len(sys.argv) != 4:
 print("Usage: python merge_lists.py <file1.txt> <file2.txt> <output.txt>")
 else:
 merge_file_lists(sys.argv[1], sys.argv[2], sys.argv[3])
