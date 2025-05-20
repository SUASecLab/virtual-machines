#/!bin/bash

# Disable screensaver
xfconf-query -c xfce4-power-manager -np '/xfce4-power-manager/blank-on-ac' -t 'int' -s 0
xfconf-query -c xfce4-power-manager -np '/xfce4-power-manager/dpms-enabled' -t 'bool' -s 'false'
xfconf-query -c xfce4-power-manager -np '/xfce4-power-manager/dpms-on-ac-off' -t 'int' -s 0
xfconf-query -c xfce4-power-manager -np '/xfce4-power-manager/dpms-on-ac-sleep' -t 'int' -s 0
xfconf-query -c xfce4-power-manager -np '/xfce4-power-manager/lock-screen-suspend-hibernate' -t 'bool' -s 'false'
xfconf-query -c xfce4-power-manager -np '/xfce4-power-manager/logind-handle-lid-switch' -t 'bool' -s 'false'
xfconf-query -c xfce4-power-manager -np '/xfce4-power-manager/power-button-action' -t 'int' -s 3
xfconf-query -c xfce4-power-manager -np '/xfce4-power-manager/show-panel-label' -t 'int' -s 0
xfconf-query -c xfce4-power-manager -np '/xfce4-power-manager/show-tray-icon' -t 'bool' -s 'false'
xfconf-query -c xfce4-screensaver -np '/lock/enabled' -t 'bool' -s 'false'
xfconf-query -c xfce4-screensaver -np '/lock/sleep-activation' -t 'bool' -s 'false'
xfconf-query -c xfce4-screensaver -np '/saver/enabled' -t 'bool' -s 'false'
xfconf-query -c xfce4-screensaver -np '/saver/mode' -t 'int' -s 0

# Clean desktop
xfconf-query -c xfce4-desktop -np '/desktop-icons/file-icons/show-filesystem' -t 'bool' -s 'false'
xfconf-query -c xfce4-desktop -np '/desktop-icons/file-icons/show-removable' -t 'bool' -s 'false'
xfconf-query -c xfce4-desktop -np '/desktop-icons/file-icons/show-trash' -t 'bool' -s 'false'