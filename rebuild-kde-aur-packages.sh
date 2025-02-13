#!/usr/bin/env bash
paru -Qqem | grep kde | ifne paru -S --rebuild --noconfirm -
paru -Qqem | grep plasma | ifne paru -S --rebuild --noconfirm -
paru -Qqem | grep kwin | ifne paru -S --rebuild --noconfirm -
