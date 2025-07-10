#!/bin/bash

# Set hostname
echo "127.0.0.1       suaseclab.de" >> /etc/hosts

# Add joker
cp /tmp/joker.sh /opt
chmod 777 /opt/joker.sh
(crontab -l 2>/dev/null; echo "0 6 * * * sudo /opt/joker.sh") | crontab -

# Add git
apt-get install -y git

# Configure python
apt-get install -y python3-pip python3-venv

# Create and activate venv
python -m venv /opt/venv
source /opt/venv/bin/activate

# Install dependencies used in the installation script of the DevBox
pip install requests

# Make script executable
chmod a+x /tmp/devbox.py

# Generate installation script
python /tmp/devbox.py

# Run installation script
bash /tmp/install_script.sh