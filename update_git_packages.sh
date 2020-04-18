#!/bin/bash

# update yay hash cache
yay -Y --gendb

read -p "Force update every git package? " -n 1 -r
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
        yay -S ${package}
        echo
    done
fi
