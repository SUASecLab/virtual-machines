#!/bin/bash

# Activate python venv
source /tmp/venv/bin/activate

# Make script executable
chmod a+x /tmp/cms.py

# Generate installation script
python /tmp/cms.py

# Run installation script
bash /tmp/install_script.sh