#!/bin/bash

# Note: this must be the last script to include because you will loose root rights after running this

# Set ownership for user's home directory
if id "laboratory" >/dev/null 2>&1; then
    chown laboratory /home/laboratory/ -R
fi
if id "vagrant" >/dev/null 2>&1; then
    chown vagrant /home/vagrant/ -R
fi

# Do not remove this line, removing the file prevents the user from running anything with root rights
if id "laboratory" >/dev/null 2>&1; then
    rm /etc/sudoers.d/laboratory
fi
if id "vagrant" >/dev/null 2>&1; then
    rm /etc/sudoers.d/vagrant
fi