#!/bin/bash

apt-get install -y network-manager
apt-get install -y openssl
apt-get install -y wget
apt-get install -y openssh-server

# Password generator
apt-get install -y python3
chmod a+x /tmp/password.py