#!/bin/bash

installed=($(yay -Qq | grep "qt5-"))

for i in "${installed[@]}"
do
    echo "Now downgrading $i..."
    downgrade $i
    echo "Done downgrading $i!"
done
