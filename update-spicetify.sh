#!/usr/bin/env bash

pull_git_dirs () {
    for D in *; do [ -d "$D/.git" ] && printf "%b" "\e[1;33m==> DEBUG: \e[0mNow pulling $D\n" && git -C "$D" pull; done
}

failed () {
    printf "%b" "\e[1;31m==> ERROR: \e[0mFailed to find spicetify directory.\n"
    exit 1
}

SPICETIFY_DIR="$(dirname "$(spicetify -c)")"

printf "%b" "\e[1;33m==> DEBUG: \e[0mSpicetify directory is $SPICETIFY_DIR\n"

if [ ! -d "$SPICETIFY_DIR" ]; then
    failed
fi

printf "%b" "\e[1;34m==> INFO: \e[0mNow pulling extensions\n"
cd "$SPICETIFY_DIR/Extensions" || failed
pull_git_dirs
printf "%b" "\e[1;34m==> INFO: \e[0mNow pulling themes\n"
cd "$SPICETIFY_DIR/Themes" || failed
pull_git_dirs
printf "%b" "\e[1;34m==> INFO: \e[0mNow pulling custom apps\n"
cd "$SPICETIFY_DIR/CustomApps" || failed
pull_git_dirs

printf "%b" "\e[1;92m==> SUCCESS: \e[0mDone. Running 'spicetify apply -n'\n"
# TODO: only apply when something was updated (https://stackoverflow.com/a/3278427)
spicetify apply -n
exit 0
