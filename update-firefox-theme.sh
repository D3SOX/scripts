#!/usr/bin/env bash
PROFILE="xn2ithkq.Private"
cd "$HOME/.mozilla/firefox/$PROFILE/chrome"
for D in *; do [ -d "$D" ] && git -C "$D" pull; done
exit 0
