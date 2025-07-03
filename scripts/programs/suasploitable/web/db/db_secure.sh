#!/bin/bash

# Postinstall for MariaDB and MySQL

# Use a secure password in 80% of the cases
export DB_ROOT_PASSWORD=$(/tmp/password.py)
if [ $((0 + $RANDOM % 10)) -lt 8 ]; then
    echo "configuration::db::root-password::secure" >> /tmp/configuration.txt
    export DB_ROOT_PASSWORD=$(openssl rand -base64 20)
else
    echo "configuration::db::root-password::top-500" >> /tmp/configuration.txt
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