#!/bin/bash

echo "application::mariadb" >> /tmp/apps.txt
apt-get install -y mariadb-server

# Enable remote connections for DB (50%)
if [ $((0 + $RANDOM % 10)) -lt 5 ]; then
    echo "configuration::db::remote-connections" >> /tmp/configuration.txt
    sed -i "s|127.0.0.1|0.0.0.0|g" /etc/mysql/mariadb.conf.d/50-server.cnf
fi