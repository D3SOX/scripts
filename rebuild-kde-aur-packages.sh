#!/usr/bin/env bash
paru -Qqem | grep kde | paru -S --noconfirm -
paru -Qqem | grep plasma | paru -S --noconfirm -
paru -Qqem | grep kwin | paru -S --noconfirm -
