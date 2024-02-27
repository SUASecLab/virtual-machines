#!/bin/bash

# Update package sources
apt-get update

# Install python and dependencies
apt-get install -y python3 python3-pip \
    python-is-python3 idle \
    build-essential libssl-dev libffi-dev python3-dev
