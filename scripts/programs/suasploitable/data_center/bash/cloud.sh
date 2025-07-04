#!/bin/bash

# Activate python venv
source /tmp/venv/bin/activate

# Make script executable
chmod a+x /tmp/cloud.py

# Generate installation script
python /tmp/cloud.py

# Run installation script
bash /tmp/install_script.sh