#!/bin/bash

# Note: this must be the last script to include because you will loose root rights after running this

# Make user scripts executable
if [ -f /home/laboratory/*.sh ]; then
    chmod a+x /home/laboratory/*.sh
fi

# Set ownership for user's home directory
chown laboratory /home/laboratory/ -R

# Do not remove this line, removing the file prevents the user from running anything with root rights
rm /etc/sudoers.d/laboratory