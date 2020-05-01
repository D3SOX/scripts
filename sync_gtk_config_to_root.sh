#!/bin/bash
sudo mkdir -p /root/.config/gtk-3.0
sudo cp ~/.config/gtk-3.0/settings.ini /root/.config/gtk-3.0/
sudo cp ~/.gtkrc-2.0 /root/
echo "Successfully copied $USER's GTK config to root"
