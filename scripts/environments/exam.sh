#!/bin/bash

# Remove networking tools we don't want to have in exam mode
apt-get purge git wget curl lynx -y

apt-get purge firefox* -y