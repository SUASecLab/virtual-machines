#!/bin/bash

# Remove these entries from the start menu
cd /usr/share/applications

declare -a entries=("audacious.desktop"
                    "connman-gtk.desktop"
                    "debian-uxterm.desktop"
                    "debian-xterm.desktop"
                    "gcr-prompter.desktop"
                    "gcr-viewer.desktop"
                    "gnome-disk-image-mounter.desktop"
                    "gnome-disk-image-writer.desktop"
                    "lxde-screenlock.desktop"
                    "lxhotkey-gtk.desktop"
                    "lxsession-default-apps.desktop"
                    "lxsession-edit.desktop"
                    "lxrandr.desktop"
                    "nm-applet.desktop"
                    "nm-connection-editor.desktop"
                    "notification-daemon.desktop"
                    "obconf.desktop"
                    "openbox.desktop"
                    "org.gnome.DiskUtility.desktop"
                    "org.gnome.Evince-previewer.desktop"
                    "pavucontrol.desktop"
                    "redhat-userinfo.desktop"
                    "redhat-usermount.desktop"
                    "redhat-userpasswd.desktop"
                    "shares.desktop"
                    "system-config-printer.desktop"
                    "time.desktop"
                    "users.desktop"
                    "xscreensaver-settings.desktop")

for i in "${entries[@]}"
do
   mv $i $i.bak
done
