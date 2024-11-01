#!/bin/bash

# Install Apache
apt-get install -y apache2
rm /etc/apache2/sites-enabled/000-default.conf
