#!/bin/bash

## Create desktop entries

# Create desktop directory
mkdir -p /home/laboratory/Desktop
cd /home/laboratory/Desktop

# Bluefish
touch bluefish.desktop
desktop-file-edit \
    --set-name="Bluefish Editor" \
    --set-icon="bluefish" \
    --set-key="Type" --set-value="Link" \
    --set-key="URL" --set-value="/usr/share/applications/bluefish.desktop" \
    bluefish.desktop

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

# Texstudio
touch texstudio.desktop
desktop-file-edit \
    --set-name="TeXstudio" \
    --set-icon="texstudio" \
    --set-key="Type" --set-value="Link" \
    --set-key="URL" --set-value="/usr/share/applications/texstudio.desktop" \
    texstudio.desktop

# Webroot
ln -s /home/laboratory/webroot 'webroot'

# Show served files
touch webroot.desktop
desktop-file-edit \
    --set-name="Show files served by webserver" \
    --set-icon="firefox" \
    --set-key="Type" --set-value="Application" \
    --set-key="Exec" --set-value="firefox http://localhost" \
    --set-key="Terminal" --set-value="false" \
    webroot.desktop

# Set executable permissions
chmod u+x *.desktop
