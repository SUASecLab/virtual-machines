#!/bin/bash

chmod u+x /tmp/*.sh

if [ $((0 + $RANDOM % 2)) -eq 0 ]; then
    echo "Installing Nextcloud"

    # Create nextcloud dir
    mkdir -p /var/www/nextcloud

    WEBSERVER=$((0 + $RANDOM % 2))

    if [ $WEBSERVER -eq 0 ]; then
        echo "Using LAMP stack"

        # Install LAMP
        bash /tmp/lamp.sh
        
        # Configure Apache
        mv /tmp/nextcloud_apache.conf /etc/apache2/sites-available/nextcloud.conf
        a2ensite nextcloud.conf
        a2enmod rewrite headers env dir mime
        systemctl restart apache2

    else
        echo "Using LEMP stack"

        # Install LEMP
        bash /tmp/lemp.sh

        # Configure nginx
        mv /tmp/nextcloud_nginx.conf /etc/nginx/sites-available/nextcloud
        unlink /etc/nginx/sites-enabled/default
        ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/nextcloud 
        systemctl restart nginx
    fi
    bash /tmp/nextcloud.sh
else
    echo "Installing SeaFile"
    bash /tmp/docker.sh
    bash /tmp/seafile.sh
fi