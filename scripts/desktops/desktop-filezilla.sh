#!/bin/bash

## Create FileZilla desktop entry

# Create desktop directory if not existent
mkdir -p /home/laboratory/Desktop
cd /home/laboratory/Desktop

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
