#!/bin/bash

echo "application::mysql" >> /tmp/apps.txt
wget -P /tmp https://repo.mysql.com//mysql-apt-config_0.8.30-1_all.deb
dpkg -i /tmp/mysql-apt-config*.deb
apt-get update
apt-get install -y mysql-server