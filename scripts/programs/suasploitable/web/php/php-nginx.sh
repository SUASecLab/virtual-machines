#!/bin/bash

echo "application::php-nginx" >> /tmp/apps.txt

# Install PHP
apt-get install -y php-fpm php-mysql