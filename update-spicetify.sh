#!/usr/bin/env bash
cd "$HOME/.config/spicetify/Extensions"
for D in *; do [ -d "$D" ] && git -C "$D" pull; done

cd "$HOME/.config/spicetify/Themes"
for D in *; do [ -d "$D" ] && git -C "$D" pull; done

spicetify restore backup apply
exit 0
