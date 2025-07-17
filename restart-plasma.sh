#!/usr/bin/env bash

echo "Attempting to restart plasma-plasmashell..."

if timeout 5 systemctl --user restart plasma-plasmashell; then
    echo "Successfully restarted plasma-plasmashell via systemctl"
else
    echo "systemctl didn't respond within 5 seconds, sending killall to plasmashell and trying again..."
    killall -9 plasmashell
    sleep 1
    systemctl --user start plasma-plasmashell
    echo "Killed plasmashell and restarted via systemctl"
fi
