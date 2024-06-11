#!/bin/bash
cd /home/vagrant

# Install Apache
apt-get install -y apache2
rm /etc/apache2/sites-enabled/000-default.conf

# Install MariaDB
apt-get install -y mariadb-server

# Secure installation if requested
if [ ! -z "$SECURE" ]; then
# secure installation with probability of 90%
# https://bertvv.github.io/notes-to-self/2015/11/16/automating-mysql_secure_installation/
if [ $((0 + $RANDOM % 10)) -lt 9 ]; then

export DB_ROOT_PASSWORD=admin
# Use a secure password in 95% of the cases
if [ $((0 + $RANDOM % 20)) -lt 19 ]; then
export DB_ROOT_PASSWORD=$(openssl rand -base64 20)
fi

mysql --user=root <<_EOF_
UPDATE mysql.user SET Password=PASSWORD('${DB_ROOT_PASSWORD}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_
fi
fi

# Install PHP
apt-get install -y php libapache2-mod-php php-mysql

# PHP composer
php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
php -r "if (hash_file('sha384', '/tmp/composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php /tmp/composer-setup.php
php -r "unlink('/tmp/composer-setup.php');"
mv composer.phar /usr/local/bin/composer