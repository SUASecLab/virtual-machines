#!/bin/bash

mkdir -p "/home/laboratory/Desktop/Screen Resolution"
cd "/home/laboratory/Desktop/Screen Resolution"

touch fullhd.desktop
desktop-file-edit \
    --set-name="FullHD" \
    --set-key="Type" --set-value="Application" \
    --set-key="Exec" --set-value="xrandr -s 1920x1080" \
    fullhd.desktop

touch wuxga.desktop
desktop-file-edit \
    --set-name="WUXGA" \
    --set-key="Type" --set-value="Application" \
    --set-key="Exec" --set-value="xrandr -s 1920x1200" \
    wuxga.desktop

touch 4k.desktop
desktop-file-edit \
    --set-name="4K" \
    --set-key="Type" --set-value="Application" \
    --set-key="Exec" --set-value="xrandr -s 3840x2160" \
    4k.desktop

chmod a+x *.desktop