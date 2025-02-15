#!/usr/bin/env bash
packages=$(paru -Qqem | grep kde)
if [[ -n "$packages" ]]; then paru -S --rebuild --noconfirm $packages; fi

packages=$(paru -Qqem | grep plasma)
if [[ -n "$packages" ]]; then paru -S --rebuild --noconfirm $packages; fi

packages=$(paru -Qqem | grep kwin)
if [[ -n "$packages" ]]; then paru -S --rebuild --noconfirm $packages; fi
