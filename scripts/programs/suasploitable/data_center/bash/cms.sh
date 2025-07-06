#!/bin/bash

# Set hostname
echo "127.0.0.1       suaseclab.de" >> /etc/hosts

# Make script executable
chmod a+x /tmp/cms.py

# Generate installation script
python /tmp/cms.py

# Run installation script
bash /tmp/install_script.sh