#!/usr/bin/env bash
systemctl --user daemon-reload
systemctl --user restart pipewire pipewire-pulse wireplumber
