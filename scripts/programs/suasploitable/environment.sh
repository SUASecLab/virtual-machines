#!/bin/bash

apt-get install -y network-manager
apt-get install -y openssl
apt-get install -y wget
apt-get install -y openssh-server
apt-get install -y python3 python-is-python3 python3-pip python3-venv

# Create python venv
python -m venv /tmp/venv
source /tmp/venv/bin/activate
pip install pyyaml