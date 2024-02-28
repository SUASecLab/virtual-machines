#!/bin/bash

## Create desktop entries

# Create desktop directory
mkdir -p /home/laboratory/Desktop
cd /home/laboratory/Desktop

# Geany
touch geany.desktop
desktop-file-edit \
    --set-name="Geany" \
    --set-icon="geany" \
    --set-key="Type" --set-value="Link" \
    --set-key="URL" --set-value="/usr/share/applications/geany.desktop" \
    geany.desktop

# Python IDLE
touch idle.desktop
desktop-file-edit \
    --set-name="IDLE" \
    --set-icon="/usr/share/pixmaps/idle.xpm" \
    --set-key="Type" --set-value="Link" \
    --set-key="URL" --set-value="/usr/share/applications/idle.desktop" \
    idle.desktop

# Set executable permissions
chmod u+x *.desktop
