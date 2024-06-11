#!/bin/bash

# Create installation directory
mkdir -p /srv
cd /srv

# Install dependencies
apt-get install -y zip unzip
apt-get install -y php-curl php-gd php-mbstring php-mysql php-opcache php-readline php-sqlite3 php-xml php-zip php-apcu

# Get code
export COMPOSER_ALLOW_SUPERUSER=1
composer create-project drupal/recommended-project drupal
cd /srv/drupal
composer update

# Add drush
composer require drush/drush
export PATH=/srv/drupal/vendor/bin:$PATH

# Fix access rights
chown www-data:www-data /srv/drupal/web -R

# Create DB
mysql -u root -e "CREATE DATABASE drupal CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";

# Create DB user
mysql -u root -e "CREATE USER 'vagrant'@'%' IDENTIFIED BY 'vagrant'; GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%'; FLUSH PRIVILEGES;"

# Configure with drush
drush site-install demo_umami --db-url=mysql://vagrant:vagrant@localhost:3306/drupal \
    --account-name=admin --account-mail=admin@example.-com --account-pass=admin \
    --site-mail=admin@example.com --site-name=SUASploitable --no-interaction