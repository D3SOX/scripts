#!/usr/bin/env bash

config_dir="$HOME/.config"
cache_file="$HOME/.cache/force-enable-menubars.cache"

# fix for non-english systems
export LC_ALL=C

# check for cache
if [ -f "$cache_file" ]; then
    # use cached data
    echo "Using cached data from $cache_file"
else
    # find new MenuBar=Disabled entries and cache
    echo "Searching for MenuBar=Disabled entries in ~/.config..."
    grep -rnw "$config_dir" -e 'MenuBar=Disabled' 2>/dev/null > "$cache_file"
    exit_code=$?
    # check if grep found nothing
    if [ $exit_code -eq 1 ]; then
        echo "No MenuBar=Disabled entries found"
        rm -f "$cache_file"
        exit 0
    fi
fi

matches=$(cat "$cache_file")

# check if empty
if [ -z "$matches" ]; then
    echo "No MenuBar=Disabled entries found"
    rm -f "$cache_file"
    exit 0
fi

echo "Now filtering for unique files entries"
# get only the paths and unique lines
matches=$(echo "$matches" | awk -F':' '{print $1}' | sort -u)

# print results
echo "Found $(echo "$matches" | wc -l) files with MenuBar=Disabled entries"
echo "$matches" | tr '\n' ' '

# add a prompt with y/n
echo
read -r -p "Do you want to fix these files? (y/N) " user_reply
if [[ ! $user_reply =~ ^[Yy]$ ]]; then
    echo "Okay, exiting"
    exit 0
fi

echo "Now fixing all files"

# now fix them
for file_path in $matches; do
    echo "Fixing $file_path"
    sed -i 's/MenuBar=Disabled/MenuBar=Enabled/g' "$file_path"
done

echo "Done fixing all files"
