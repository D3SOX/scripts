#!/usr/bin/env bash
$(dirname $0)/stop-minidlna.sh
minidlnad -f /home/$USER/.config/minidlna/minidlna.conf -P /home/$USER/.config/minidlna/minidlna.pid
