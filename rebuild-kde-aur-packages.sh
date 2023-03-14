#!/usr/bin/env bash
paru -Qqem | grep kde | paru -S --rebuild --noconfirm -
paru -Qqem | grep plasma | paru -S --rebuild --noconfirm -
paru -Qqem | grep kwin | paru -S --rebuild --noconfirm -
