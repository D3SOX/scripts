#!/bin/bash

# update yay hash cache
echo "Updating yay hash cache..."
yay -Y --gendb > /dev/null

read -p "Force update every git package? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Single command
    #yay -Qqm | grep '\-git' | yay -S -

    # We use a for loop because otherwise it stops when it can't find one package
    packages=$(yay -Qqm | grep '\-git')
    echo "We found the following git packages:"
    echo "${packages[*]}"
    echo

    for package in $packages; do
        echo "Now updating $package"
        echo
        yay -S "$package"
        echo
    done
    echo "Finished updating git packages: ${packages[*]}"
fi
