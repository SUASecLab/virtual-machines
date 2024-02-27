#!/bin/bash

## Create basic desktop entries

# Create desktop directory
mkdir -p /home/laboratory/Desktop
cd /home/laboratory/Desktop

# Shared files
ln -s /media/share 'Exercise files'

# Terminal
touch lxterminal.desktop
desktop-file-edit \
    --set-name="Shell" \
    --set-icon="lxterminal" \
    --set-key="Type" --set-value="Link" \
    --set-key="URL" --set-value="/usr/share/applications/lxterminal.desktop" \
    lxterminal.desktop

# FileZilla
touch filezilla.desktop
desktop-file-edit \
    --set-name="FileZilla" \
    --set-icon="filezilla" \
    --set-key="Type" --set-value="Link" \
    --set-key="URL" --set-value="/usr/share/applications/filezilla.desktop" \
    filezilla.desktop

# Set executable permissions
chmod u+x *.desktop
