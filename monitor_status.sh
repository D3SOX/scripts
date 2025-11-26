#!/usr/bin/env bash

status=$(kscreen-doctor --dpms show)

if echo "$status" | grep -q "on"; then
    # At least one monitor is on
    printf 1
else
    # No monitor is on
    printf 0
fi

