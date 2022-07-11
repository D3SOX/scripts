#!/usr/bin/env bash

if [ $# -eq 1 ]; then
    # to ask for pw directly with topgrade
    sudo echo
fi

PROFILE="xn2ithkq.Private"
cd "$HOME/.mozilla/firefox/$PROFILE/chrome"
for D in *; do [ -d "$D" ] && git -C "$D" pull; done
exit 0
