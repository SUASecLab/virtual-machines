#!/bin/bash

# Note: this must be the last script to include because you will loose root rights after running this

# Set ownership for user's home directory
chown laboratory /home/laboratory/ -R

# Do not remove this line, removing the file prevents the user from running anything with root rights
rm /etc/sudoers.d/laboratory