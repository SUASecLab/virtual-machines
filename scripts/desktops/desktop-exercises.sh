#!/bin/bash

## Create exercises desktop entry

# Create desktop directory if not existent
mkdir -p /home/laboratory/Desktop
cd /home/laboratory/Desktop

# Shared files
ln -s /media/share 'Exercise files'
