#!/bin/bash

# Install DB
if [ $((0 + $RANDOM % 2)) -eq 0 ]; then
   bash /tmp/mariadb.sh
else
   bash /tmp/mysql.sh
fi

# Secure installation: 80%
if [ $((0 + $RANDOM % 10)) -eq 8 ]; then
   echo "configuration::db:secure" >> /tmp/configuration.txt
   bash /tmp/db_secure.sh
else
   echo "configuration::db:insecure" >> /tmp/configuration.txt
   echo "root" >> /tmp/flags.txt
fi
