#!/bin/bash

## Create desktop entries

# Create desktop directory
mkdir -p /home/laboratory/Desktop
cd /home/laboratory/Desktop

# Contiki source code
ln -s /home/laboratory/contiki-ng 'Contiki-NG code'

# Wireshark
touch org.wireshark.Wireshark.desktop
desktop-file-edit \
    --set-name="Wireshark" \
    --set-icon="org.wireshark.Wireshark" \
    --set-key="Type" --set-value="Link" \
    --set-key="URL" --set-value="/usr/share/applications/org.wireshark.Wireshark.desktop" \
    org.wireshark.Wireshark.desktop

# Cooja simulator
touch cooja.desktop
desktop-file-edit \
    --set-name="Cooja Simulator" \
    --set-icon="utilities-terminal" \
    --set-key="Type" --set-value="Application" \
    --set-key="Exec" --set-value="/home/laboratory/run_cooja.sh" \
    --set-key="Terminal" --set-value="false" \
    cooja.desktop

# View Remotes
touch motes.desktop
desktop-file-edit \
    --set-name="Show device" \
    --set-icon="utilities-terminal" \
    --set-key="Type" --set-value="Application" \
    --set-key="Exec" --set-value="/home/laboratory/show_remote.sh" \
    --set-key="Terminal" --set-value="true" \
    motes.desktop

# Set executable permissions
chmod u+x *.desktop
