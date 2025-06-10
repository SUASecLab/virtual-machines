#!/bin/bash

# installing (old) LAMP stack

# Install Apache
apt-get install -y apache2
rm /etc/apache2/sites-enabled/000-default.conf
rm /var/www/html/* -rf

echo "www-data" >> /tmp/flags.txt
echo "/var/www/html" >> /tmp/flags.txt

# Set FQDN
echo "127.0.0.1 basic.suaseclab.de" >> /etc/hosts
echo "ServerName basic.suaseclab.de" >> /etc/apache2/apache2.conf

# Install MariaDB
apt-get install -y mariadb-server

# Install PHP
apt-get install -y curl
curl -sSL https://packages.sury.org/php/README.txt | bash -x
apt-get update
apt-get install -y php7.4 \
    php7.4-{mysql,cgi,bcmath,curl,gd,intl,json,mbstring,opcache,sqlite3,xml,zip,snmp,imap,common,tidy,ldap,imagick,cli,apcu,bz2}
apt-get install -y php-mysqli php-pear php-phpseclib
apt-get install -y libapache2-mod-php libapache2-mod-php7.4

# Enable mysql
sed -i "s|;extension=mysqli|extension=mysqli|g" /etc/php/7.4/apache2/php.ini

# Install phpmyadmin
wget -P /tmp https://files.phpmyadmin.net/phpMyAdmin/4.9.11/phpMyAdmin-4.9.11-all-languages.tar.gz
mkdir -p /var/www/html/phpmyadmin
tar xvf /tmp/phpMyAdmin-4.9.11-all-languages.tar.gz --strip-components=1 -C /var/www/html/phpmyadmin
cp /var/www/html/phpmyadmin/config.sample.inc.php /var/www/html/phpmyadmin/config.inc.php

# Clone source
apt-get install -y unzip
wget -P /tmp https://github.com/bbalet/jorani/releases/download/v1.0.0/jorani-1.0.0.zip
unzip /tmp/jorani-1.0.0.zip -d /var/www/html

echo "CVE-2023-26469" >> /tmp/flags.txt

# Copy backup file
cp /tmp/jorani_backup.sql /var/www/html/backup.sql

# Date hired of Karolin Saenger
echo "2025-06-03" >> /tmp/flags.txt

# Email of user with id 5
echo "s.dietrich@suaseclab.de" >> /tmp/flags.txt

# Password of Kevin Faber
echo "bonus:53VQR8TE" >> /tmp/flags.txt

# Create DB
mysql -u root -e "CREATE DATABASE jorani CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
mysql -u root -e "CREATE USER 'lms'@'%' IDENTIFIED BY 'ZDS6P4Mw'; GRANT ALL PRIVILEGES ON jorani.* TO 'lms'@'%'; FLUSH PRIVILEGES;"
mysql -u root -e "USE jorani; source /tmp/jorani.sql;"

# Leave reason for leave of Katja Furst (1 word)
echo "maternity" >> /tmp/flags.txt

# Insecure DB users
mysql -u root -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'cocacola'; GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%'; FLUSH PRIVILEGES;"
mysql -u root -e "CREATE USER 'test'@'%' IDENTIFIED BY 'rainbow'; GRANT ALL PRIVILEGES ON *.* TO 'test'@'%'; FLUSH PRIVILEGES;"
mysql -u root -e "CREATE USER 'info'@'%' IDENTIFIED BY 'dolphins'; GRANT ALL PRIVILEGES ON *.* TO 'info'@'%'; FLUSH PRIVILEGES;"

echo "cocacola" >> /tmp/flags.txt
echo "rainbow" >> /tmp/flags.txt
echo "dolphins" >> /tmp/flags.txt

# Enable remote connections for DB
sed -i "s|127.0.0.1|0.0.0.0|g" /etc/mysql/mariadb.conf.d/50-server.cnf

# Set webserver configuration
sed -i "s|'hostname' => ''|'hostname' => 'localhost'|g" /var/www/html/application/config/database.php
sed -i "s|'username' => 'root'|'username' => 'lms'|g" /var/www/html/application/config/database.php
sed -i "s|'password' => ''|'password' => 'ZDS6P4Mw'|g" /var/www/html/application/config/database.php

# User for the jorani DB
echo "lms" >> /tmp/flags.txt

# Jorani user password
echo "ZDS6P4Mw" >> /tmp/flags.txt

# Create configuration file for web server
mv /tmp/jorani_apache.conf /etc/apache2/sites-available/jorani.conf

# Server administrator
echo "m.nickel@suaseclab.de" >> /tmp/flags.txt

# Copy password exercise
cp /tmp/files.zip /var/www/html/

# Add passwords to flag list (vagrant is user password)
echo "startrek" >> /tmp/flags.txt
echo "super" >> /tmp/flags.txt
echo "porsche" >> /tmp/flags.txt
echo "vagrant" >> /tmp/flags.txt

# Enable site
a2ensite jorani.conf
a2enmod rewrite dir env headers mime setenvif
systemctl restart apache2

# Fix access rights
chown -R www-data:www-data /var/www/html/
