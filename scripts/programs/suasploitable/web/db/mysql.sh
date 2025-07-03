#!/bin/bash

echo "application::mysql" >> /tmp/apps.txt
wget -P /tmp https://repo.mysql.com//mysql-apt-config_0.8.30-1_all.deb
dpkg -i /tmp/mysql-apt-config*.deb
apt-get update
apt-get install -y mysql-server

# Enable remote connections for DB (50%)
if [ $((0 + $RANDOM % 10)) -lt 5 ]; then
    echo "configuration::db::remote-connections" >> /tmp/configuration.txt
    echo "bind-address = 0.0.0.0" >> /etc/mysql/mysql.conf.d/mysqld.cnf
fi