#!/bin/bash

echo "application::nginx" >> /tmp/apps.txt

# Install NGINX
apt-get install -y nginx
unlink /etc/nginx/sites-enabled/default