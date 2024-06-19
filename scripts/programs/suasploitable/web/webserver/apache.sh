#!/bin/bash

echo "application::apache2" >> /tmp/apps.txt

# Install Apache
apt-get install -y apache2
rm /etc/apache2/sites-enabled/000-default.conf
