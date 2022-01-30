#!/usr/bin/env bash
$(dirname $0)/stop-minidlna.sh
minidlnad -f $HOME/.config/minidlna/minidlna.conf -P $HOME/.config/minidlna/minidlna.pid
