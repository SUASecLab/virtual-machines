#!/bin/bash

# Note: this should be the first script to call as this updates the apt sources

# Remove cdrom
sed -i '/^deb cdrom/d' /etc/apt/sources.list

# Update sources
apt-get update
apt-get upgrade -y

# Install programs
apt-get install filezilla -y
apt-get install git git-lfs -y
apt-get install network-manager network-manager-gnome -y

# Uninstall unwanted software
apt-get purge libreoffice* -y
apt-get purge deluge* deluge-gtk* -y
apt-get purge smplayer -y
apt-get purge mpv -y
apt-get purge synaptic -y
apt-get purge xsane -y

# Remove mousepad, install featherpad which supports syntax highlighting
apt-get remove mousepad -y
apt-get install featherpad -y

# Remove no longer needed dependencies
apt-get autoremove -y