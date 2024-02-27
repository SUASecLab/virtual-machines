#!/bin/bash

# Note: this will install the most basic tools to compile C/C++ source code.
# This targets the amd64 architecture/instruction set.
# If you want to program other architectures you have to install a corresponding compiler set.
# E.g. for contiki other compilers are included in the contiki.sh file

# Load latest sources
apt-get update

# Install build-essential, make and gdb
apt-get install -y build-essential make gdb

# Install manpages for GNU/Linux development
apt-get install -y manpages-dev