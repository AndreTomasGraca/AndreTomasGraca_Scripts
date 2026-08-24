# --------------------
# 	What it Does?
# --------------------
#
# Summary: This script is a simple shell script that continuously synchronizes a directory with another directory using rsync and waits for changes using inotifywait. The script will run indefinitely until manually stopped.
#
#
# In Detail:
#
# 	This is a breakdown of what each part of the script does:
#
#    	while true: This is the beginning of an infinite loop. The true command is always true, so this loop will run indefinitely until it is manually interrupted.
#
#    	do: This keyword indicates the start of the loop's body, and the commands that follow are part of the loop.
#
#    	rsync -avP "$PWD" /Path/To/Destination: This line uses the rsync command to synchronize the contents of the current working directory ("$PWD") with the directory /Path/To/Destination. Here's what the options used mean:
#       	-a: Archive mode, which includes recursion and preserves various file attributes (permissions, timestamps, etc.).
#        	-v: Verbose mode, which displays detailed information about the files being copied.
#        	-P: Combines the options -p (preserve permissions) and -t (preserve timestamps) along with progress information.
#
#    	inotifywait -r "$PWD": This line uses the inotifywait command to monitor changes in the current working directory ("$PWD") and its subdirectories (-r option). inotifywait is a command-line tool that can watch for file system events like file creation, modification, or deletion and report them in real-time.
#
#    	done: This keyword marks the end of the loop's body. After the done statement is reached, the script will loop back to the while true line and repeat the process.


while true
do
	rsync -avP "$PWD" /Path/To/Destination
	inotifywait -r "$PWD"
done