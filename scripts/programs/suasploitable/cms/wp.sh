#!/bin/bash

apt-get install -y software-properties-common zip unzip
apt-get install -y php-curl php-gd php-mbstring php-xml php-zip php-xmlrpc

# Create directory to be served
mkdir -p /srv/wp

# Install wp-cli
wget -P /tmp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /tmp/wp-cli.phar
mv /tmp/wp-cli.phar /usr/bin/wp

# Add wp user, insecure password: 30%
if [ $((0 + $RANDOM % 10)) -lt 3 ]; then
    echo "configuration::wordpress::system-user::password::insecure" >> /tmp/configuration.txt
    useradd -m -p wordpress -s /bin/bash wordpress
    echo "wordpress" >> /tmp/flags.txt
else
    export WP_USER_PASS=$(openssl rand -base64 20)
    echo "configuration::wordpress::system-user::password::secure" >> /tmp/configuration.txt
    useradd -m -p $WP_USER_PASS -s /bin/bash wordpress
fi
chown wordpress:wordpress /srv/wp -R

# Install wp: 40% latest, 30% 6.5.1 (XSS vuln), 30% 6.4.2 (information exposure)
WP_VERSION=$((0 + $RANDOM % 10))
if [ $WP_VERSION -lt 4 ]; then
    echo "configuration::wordpress::version::latest" >> /tmp/configuration.txt
    sudo -u wordpress wp core download --path=/srv/wp --version=latest
elif [ $WP_VERSION -lt 7 ]; then
    echo "configuration::wordpress::version::6.5" >> /tmp/configuration.txt
    sudo -u wordpress wp core download --path=/srv/wp --version=6.5
    echo "6.5.1" >> /tmp/flags.txt
else
    echo "configuration::wordpress::version::6.4.2" >> /tmp/configuration.txt
    sudo -u wordpress wp core download --path=/srv/wp --version=6.4.2
    echo "6.4.2" >> /tmp/flags.txt
fi

# Create DB
mysql -u root -e "CREATE DATABASE wp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";

export WP_DB_PASSWORD="wp"
# Insecure wp db password (20%)
if [ $((0 + $RANDOM % 10)) -lt 2 ]; then
    echo "configuration::wordpress::user-password::insecure" >> /tmp/configuration.txt
    echo $WP_DB_PASSWORD >> /tmp/flags.txt
else
    echo "configuration::wordpress::user-password::secure" >> /tmp/configuration.txt
    export WP_DB_PASSWORD=$(openssl rand -base64 20)
fi

# Create DB user
# privileges on all databases: 60%
if [ $((0 + $RANDOM % 10)) -lt 6 ]; then
    echo "configuration::wordpress::db-privileges::all" >> /tmp/configuration.txt
    echo "all-privileges" >> /tmp/flags.txt
    mysql -u root -e "CREATE USER 'wp'@'%' IDENTIFIED BY '${WP_DB_PASSWORD}'; GRANT ALL PRIVILEGES ON *.* TO 'wp'@'%'; FLUSH PRIVILEGES;"
else
    echo "configuration::wordpress::db-privileges::wp-only" >> /tmp/configuration.txt
    mysql -u root -e "CREATE USER 'wp'@'%' IDENTIFIED BY '${WP_DB_PASSWORD}'; GRANT ALL PRIVILEGES ON wp.* TO 'wp'@'%'; FLUSH PRIVILEGES;"
fi

# Creating config file
cd /srv/wp
sudo -u wordpress wp config create --dbname=wp --dbuser=wp --dbpass=${WP_DB_PASSWORD}

# (Re)create database
sudo -u wordpress wp db create

# Install wp, secure password: 80%
export WP_ADMIN_PW="admin"
if [ $((0 + $RANDOM % 10)) -lt 8 ]; then
    export WP_ADMIN_PW=$(openssl rand -base64 20)
    echo "configuration::wordpress::web-user::password::secure" >> /tmp/configuration.txt
    sudo -u wordpress wp core install --url=suaseclab.de --title="WP SUASploitable" --admin_user=admin --admin_password=${WP_ADMIN_PW} --admin_email=test@example.com
else
    echo "configuration::wordpress::web-user::password::insecure" >> /tmp/configuration.txt
    echo $WP_ADMIN_PW >> /tmp/flags.txt
    sudo -u wordpress wp core install --url=suaseclab.de --title="WP SUASploitable" --admin_user=admin --admin_password=${WP_ADMIN_PW} --admin_email=test@example.com
fi

# Update plugins (60%)
if [ $((0 + $RANDOM % 10)) -lt 6 ]; then
    echo "configuration::wordpress::plugins::updated" >> /tmp/configuration.txt
    sudo -u wordpress wp plugin update --all
else
    echo "configuration::wordpress::plugins::outdated" >> /tmp/configuration.txt
    echo "plugins" >> /tmp/flags.txt
fi

# Fix access rights
chown www-data:www-data /srv/wp -R
