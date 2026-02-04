#!/bin/bash

# Set hostname
echo "127.0.0.1       cloud.suaseclab.de" >> /etc/hosts

# Add joker
cp /tmp/joker.sh /opt
chmod 777 /opt/joker.sh
(crontab -l 2>/dev/null; echo "0 6 * * * sudo /opt/joker.sh") | crontab -

# Make script executable
chmod a+x /tmp/cloud.py

# Generate installation script
python /tmp/cloud.py

# Run installation script
bash /tmp/install_script.sh