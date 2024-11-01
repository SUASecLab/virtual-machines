#!/bin/bash

# Postinstall for MariaDB and MySQL

# Use a secure password in 95% of the cases
export DB_ROOT_PASSWORD=admin
if [ $((0 + $RANDOM % 20)) -lt 19 ]; then
    echo "configuration::sql::root-password::random" >> /tmp/configuration.txt
    export DB_ROOT_PASSWORD=$(openssl rand -base64 20)
else
    echo "configuration::sql::root-password::simple" >> /tmp/configuration.txt
    echo $DB_ROOT_PASSWORD >> /tmp/flags.txt
fi

mysql --user=root <<_EOF_
UPDATE mysql.user SET Password=PASSWORD('${DB_ROOT_PASSWORD}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_