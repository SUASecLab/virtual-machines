#!/bin/bash

# PHP modules
apt-get install -y libxml2 zip curl zlib1g
apt-get install -y php-ctype php-curl php-dom php-fileinfo php-gd php-json php-mbstring php-posix php-xml php-zip php-mysql

# Create DB
mysql -u root -e "CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;";

# Create DB user
# privileges on all databases: 60%
if [ $((0 + $RANDOM % 10)) -lt 6 ]; then
    echo "configuration::nextcloud::db-privileges::all" >> /tmp/configuration.txt
    mysql -u root -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'nextcloud'; GRANT ALL PRIVILEGES ON *.* TO 'nextcloud'@'localhost'; FLUSH PRIVILEGES;"
else
    echo "configuration::nextcloud::db-privileges::nc-only" >> /tmp/configuration.txt
    mysql -u root -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'nextcloud'; GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost'; FLUSH PRIVILEGES;"
fi

# Get code
wget -P /tmp https://download.nextcloud.com/server/releases/latest.tar.bz2
tar -xf /tmp/latest.tar.bz2 -C /var/www

# Fix access rights
chown -R www-data:www-data /var/www/nextcloud/

# Install
cd /var/www/nextcloud
NEXTCLOUD_INSTALLED=$(sudo -u www-data php occ maintenance:install \
    --database "mysql" --database-name "nextcloud" --database-user "nextcloud" \
    --database-pass "nextcloud" --admin-user "admin" --admin-pass "password")
if [[ $NEXTCLOUD_INSTALLED == *"Error"* ]]; then
    # fix installation (sometimes, NC install sets db user wrong)
    sudo -u www-data sed -i 's|oc_admin|nextcloud|g' /var/www/nextcloud/config/config.php
    sudo -u www-data php occ maintenance:install --database "mysql" --database-name "nextcloud" \
        --database-user "nextcloud" --database-pass "nextcloud" --admin-user "admin" --admin-pass "password"
fi

# Resolve access through untrusted domain
(crontab -l 2>/dev/null; echo "* * * * * sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 0 --value=\$(hostname -I | awk '{print \$1}')") | crontab -

# Add cloud domain
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 1 --value=cloud.suaseclab.de
