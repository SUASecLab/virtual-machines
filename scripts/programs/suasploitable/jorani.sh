#!/bin/bash

# installing (old) LAMP stack

# Apache
apt-get install -y apache2
rm /etc/apache2/sites-enabled/000-default.conf
rm /var/www/html/* -rf

# Install MariaDB
apt-get install -y mariadb-server

# Install PHP
apt-get install -y curl
curl -sSL https://packages.sury.org/php/README.txt | bash -x
apt-get update
apt-get install -y php7.4 libapache2-mod-php7.4 php7.4-mysql php7.4-cgi php7.4-bcmath php7.4-curl \
    php7.4-gd php7.4-intl php7.4-json php7.4-mbstring php7.4-opcache php7.4-sqlite3 \
    php7.4-xml php7.4-zip php7.4-snmp php7.4-imap php7.4-common php7.4-tidy \
    php7.4-ldap php7.4-imagick

# Clone source
apt-get install -y unzip
wget -P /tmp https://github.com/bbalet/jorani/releases/download/v1.0.0/jorani-1.0.0.zip
mkdir -p /var/www/html
unzip /tmp/jorani-1.0.0.zip -d /var/www/html

echo "CVE-2023-26469" >> /tmp/flags.txt

# Create DB
mysql -u root -e "CREATE DATABASE jorani CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
mysql -u root -e "CREATE USER 'lms'@'%' IDENTIFIED BY 'jorani'; GRANT ALL PRIVILEGES ON jorani.* TO 'lms'@'%'; FLUSH PRIVILEGES;"
mysql -u root -e "USE jorani; source /var/www/html/sql/jorani.sql;"

# Set webserver configuration
sed -i "s|'hostname' => ''|'hostname' => 'localhost'|g" /var/www/html/application/config/database.php
sed -i "s|'username' => 'root'|'username' => 'lms'|g" /var/www/html/application/config/database.php
sed -i "s|'password' => ''|'password' => 'jorani'|g" /var/www/html/application/config/database.php

# Create configuration file for web server
mv /tmp/jorani_apache.conf /etc/apache2/sites-available/jorani.conf

# Enable site
a2ensite jorani.conf
a2enmod rewrite dir env headers mime setenvif
systemctl restart apache2

# Fix access rights
chown -R www-data:www-data /var/www/html/
