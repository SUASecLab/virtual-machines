#!/bin/bash

# PHP modules
apt-get install -y libxml2 zip curl zlib1g
apt-get install -y php-ctype php-curl php-dom php-fileinfo php-gd php-json php-mbstring php-posix php-xml php-zip php-mysql

# Create DB
mysql -u root -e "CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;";

# Change password for DB user (30 % insecure, 70% secure)
export NEXTCLOUD_DB_PW=$(/tmp/password.py)

if [ $((0 + $RANDOM % 10)) -lt 2 ]; then
    echo "configuration::nextcloud::db-password::top-500" >> /tmp/configuration.txt;
    echo $NEXTCLOUD_DB_PW >> /tmp/flags.txt
else
    export NEXTCLOUD_DB_PW=$(openssl rand -base64 20)
    echo "configuration::nextcloud::db-password::secure" >> /tmp/configuration.txt;
fi

# Create DB user
# privileges on all databases: 60%
if [ $((0 + $RANDOM % 10)) -lt 6 ]; then
    echo "configuration::nextcloud::db-privileges::all" >> /tmp/configuration.txt
    echo "all-privileges" >> /tmp/flags.txt
    mysql -u root -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '${NEXTCLOUD_DB_PW}'; GRANT ALL PRIVILEGES ON *.* TO 'nextcloud'@'localhost'; FLUSH PRIVILEGES;"
else
    echo "configuration::nextcloud::db-privileges::nc-only" >> /tmp/configuration.txt
    mysql -u root -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '${NEXTCLOUD_DB_PW}'; GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost'; FLUSH PRIVILEGES;"
fi

# Decide if nextcloud user has insecure password (30% yes)
export NEXTCLOUD_USER_PW=$(/tmp/password.py)
if [ $((0 + $RANDOM % 10)) -lt 3 ]; then
    echo "configuration::nextcloud::user-password::top-500" >> /tmp/configuration.txt
    echo $NEXTCLOUD_USER_PW >> /tmp/flags.txt
else
    echo "configuration::nextcloud::user-password::secure" >> /tmp/configuration.txt
    export NEXTCLOUD_USER_PW=$(openssl rand -base64 20)
fi

# Decide if old nextcloud version with security vulnerabilities is installed (30% yes)
if [ $((0 + $RANDOM % 10)) -lt 3 ]; then
    echo "configuration::nextcloud::version::insecure" >> /tmp/configuration.txt
    echo "CVE-2024-37882" >> /tmp/flags.txt
    wget -P /tmp https://download.nextcloud.com/server/releases/nextcloud-28.0.3.tar.bz2
    tar -xf /tmp/nextcloud-28.0.3.tar.bz2 -C /var/www
else
    echo "configuration::nextcloud::version::secure" >> /tmp/configuration.txt
    wget -P /tmp https://download.nextcloud.com/server/releases/latest.tar.bz2
    tar -xf /tmp/latest.tar.bz2 -C /var/www
fi

# Fix access rights
chown -R www-data:www-data /var/www/nextcloud/

# Install
cd /var/www/nextcloud
NEXTCLOUD_INSTALLED=$(sudo -u www-data php occ maintenance:install \
    --database "mysql" --database-name "nextcloud" --database-user "nextcloud" \
    --database-pass ${NEXTCLOUD_DB_PW} --admin-user "admin" --admin-pass ${NEXTCLOUD_USER_PW})
if [[ $NEXTCLOUD_INSTALLED == *"Error"* ]]; then
    # fix installation (sometimes, NC install sets db user wrong)
    sudo -u www-data sed -i 's|oc_admin|nextcloud|g' /var/www/nextcloud/config/config.php
    sudo -u www-data php occ maintenance:install --database "mysql" --database-name "nextcloud" \
        --database-user "nextcloud" --database-pass ${NEXTCLOUD_DB_PW} --admin-user "admin" --admin-pass ${NEXTCLOUD_USER_PW}
fi

# Resolve access through untrusted domain
(crontab -l 2>/dev/null; echo "* * * * * sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 0 --value=\$(hostname -I | awk '{print \$1}')") | crontab -

# Add cloud domain
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 1 --value=cloud.suaseclab.de
