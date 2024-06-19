#!/bin/bash

echo "application::php-apache" >> /tmp/apps.txt

# Install PHP
apt-get install -y php libapache2-mod-php php-mysql
