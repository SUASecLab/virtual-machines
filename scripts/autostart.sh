#!/bin/bash

# Disable swap
(crontab -l 2>/dev/null; echo "@reboot sudo swapoff -a") | crontab -

# only run for laboratory users
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

    # Warning dialog
    apt-get -y install zenity
    touch warning.desktop
    desktop-file-edit \
        --set-name="Show warning dialog" \
        --set-key="Type" --set-value="Application" \
        --set-key="Exec" --set-value="zenity --warning --text=\"This machine is reset each day at 06:00 am. All stored user data will be removed by the reset.\"" \
        warning.desktop

    # Make scripts executable
    chmod a+x *.desktop
fi

