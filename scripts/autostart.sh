#!/bin/bash

# Disable swap
(crontab -l 2>/dev/null; echo "@reboot sudo swapoff -a") | crontab -

# only set screen resolution for laboratory users
if id "laboratory" >/dev/null 2>&1; then
    # Create autostart directory
    mkdir -p /home/laboratory/.config/autostart
    cd /home/laboratory/.config/autostart

    # Set screen resolution
    touch resolution.desktop
    desktop-file-edit \
        --set-name="Set screen resolution" \
        --set-key="Type" --set-value="Application" \
        --set-key="Exec" --set-value="xrandr -s 1920x1080" \
        resolution.desktop
fi

