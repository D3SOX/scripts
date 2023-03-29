#!/usr/bin/env bash

pull_git_dirs () {
    for D in *; do [ -d "$D/.git" ] && git -C "$D" pull; done
}

cd "$(dirname "$(spicetify -c)")/Extensions"
pull_git_dirs
cd "$(dirname "$(spicetify -c)")/Themes"
pull_git_dirs
cd "$(dirname "$(spicetify -c)")/CustomApps"
pull_git_dirs

spicetify apply -n
exit 0
