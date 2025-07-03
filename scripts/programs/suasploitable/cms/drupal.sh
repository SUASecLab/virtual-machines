#!/bin/bash

# Create installation directory
mkdir -p /srv
cd /srv

# Install dependencies
apt-get install -y zip unzip
apt-get install -y php-curl php-gd php-mbstring php-mysql php-opcache php-readline php-sqlite3 php-xml php-zip php-apcu

# Get code
export COMPOSER_ALLOW_SUPERUSER=1

# Install drupal, version with security issues (40% yes)
if [ $((0 + $RANDOM % 10)) -lt 4 ]; then
    echo "configuration::drupal::version:10.1.3" >> /tmp/configuration.txt
    echo "CVE-2023-5256" >> /tmp/flags.txt
    composer create-project drupal/recommended-project:10.1.3 drupal
else
    echo "configuration::drupal::version:latest" >> /tmp/configuration.txt
    composer create-project drupal/recommended-project:10.3.6 drupal
fi

cd /srv/drupal
composer install

# Add drush
composer require drush/drush
export PATH=/srv/drupal/vendor/bin:$PATH

# Fix access rights
chown www-data:www-data /srv/drupal/web -R

# Create DB
mysql -u root -e "CREATE DATABASE drupal CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";

# Create DB user, insecure password 30%
export D_DB_PASSWORD=$(/tmp/password.py)
if [ $((0 + $RANDOM % 10)) -lt 3 ]; then
    echo "configuration::drupal::db-password::insecure" >> /tmp/configuration.txt
    echo $D_DB_PASSWORD >> /tmp/flags.txt
else
    echo "configuration::drupal::db-password::secure" >> /tmp/configuration.txt
    export D_DB_PASSWORD=$(openssl rand -base64 20)
fi

# Create DB user
# privileges on all databases: 60%
if [ $((0 + $RANDOM % 10)) -lt 6 ]; then
    echo "configuration::drupal::db-privileges::all" >> /tmp/configuration.txt
    echo "all-privileges" >> /tmp/flags.txt
    mysql -u root -e "CREATE USER 'vagrant'@'%' IDENTIFIED BY '${D_DB_PASSWORD}'; GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%'; FLUSH PRIVILEGES;"
else
    echo "configuration::drupal::db-privileges::drupal-only" >> /tmp/configuration.txt
    mysql -u root -e "CREATE USER 'vagrant'@'%' IDENTIFIED BY '${D_DB_PASSWORD}'; GRANT ALL PRIVILEGES ON drupal.* TO 'vagrant'@'%'; FLUSH PRIVILEGES;"
fi

# Insecure admin pw? (30%)
export D_ADMIN_PASSWORD=$(/tmp/password.py)
if [ $((0 + $RANDOM % 10)) -lt 3 ]; then
    echo "configuration::drupal::user-password::insecure" >> /tmp/configuration.txt
    echo $D_ADMIN_PASSWORD >> /tmp/flags.txt
else
    echo "configuration::drupal::user-password::secure" >> /tmp/configuration.txt
    export D_ADMIN_PASSWORD=$(openssl rand -base64 20)
fi


# Configure with drush
drush site-install demo_umami --db-url=mysql://vagrant:${D_DB_PASSWORD}@localhost:3306/drupal \
    --account-name=admin --account-mail=admin@example.-com --account-pass=${D_ADMIN_PASSWORD} \
    --site-mail=admin@example.com --site-name=SUASploitable --no-interaction