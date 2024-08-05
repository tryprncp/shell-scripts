#!/bin/bash

# Create an array of directory paths from command line arguments
directories_to_shred=("$@")

# Function to shred a directory
shred_directory() {
    local dir="$1"
    if [ -d "$dir" ]; then
        find "$dir" -type f -exec shred -uzn 3 {} \;
        rm -rf "$dir"
        return 0
    else
        return 1
    fi
}

# Iterate through the array and shred each directory
for dir in "${directories_to_shred[@]}"; do
    shred_directory "$dir"
done

# Self-delete the script using 'shred'
shred -uzn 3 "$0"
