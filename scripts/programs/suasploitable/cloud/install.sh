#!/bin/bash

chmod u+x /tmp/*.sh

if [ $((0 + $RANDOM % 2)) -eq 0 ]; then
    echo "application::nextcloud" >> /tmp/apps.txt

    # Create nextcloud dir
    mkdir -p /var/www/nextcloud

    WEBSERVER=$((0 + $RANDOM % 2))

    if [ $WEBSERVER -eq 0 ]; then
        # Install LAMP
        bash /tmp/lamp.sh
        
        # Create configuration file for web server: 70% TLS 30% no TLS
        if [ $((0 + $RANDOM % 10)) -lt 7 ]; then
            bash /tmp/certs.sh
            bash /tmp/apache-tls.sh
            echo "configuration::nextcloud::tls::enabled" >> /tmp/configuration.txt
            mv /tmp/nextcloud_apache_tls.conf /etc/apache2/sites-available/nextcloud-tls.conf
            a2ensite nextcloud-tls.conf
        else
            echo "configuration::nextcloud::tls::disabled" >> /tmp/configuration.txt
            echo "no-tls" >> /tmp/flags.txt
        fi

        # Enable site
        mv /tmp/nextcloud_apache.conf /etc/apache2/sites-available/nextcloud.conf
        a2ensite nextcloud.conf
        a2enmod rewrite headers env dir mime
        systemctl restart apache2
    else
        # Install LEMP
        bash /tmp/lemp.sh

        # Configure NGINX: 70% TLS 30% no TLS
        if [ $((0 + $RANDOM % 10)) -lt 7 ]; then
            bash /tmp/certs.sh
            echo "configuration::nextcloud::tls::enabled" >> /tmp/configuration.txt
            mv /tmp/nextcloud_nginx_tls.conf /etc/nginx/sites-available/nextcloud-tls
            ln -s /etc/nginx/sites-available/nextcloud-tls /etc/nginx/sites-enabled/nextcloud-tls
        else
            echo "configuration::nextcloud::tls::disabled" >> /tmp/configuration.txt
            echo "no-tls" >> /tmp/flags.txt
        fi

        # Configure nginx
        mv /tmp/nextcloud_nginx.conf /etc/nginx/sites-available/nextcloud
        ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/nextcloud
        systemctl restart nginx
    fi
    bash /tmp/nextcloud.sh
else
    echo "application::seafile" >> /tmp/apps.txt
    bash /tmp/docker.sh
    bash /tmp/seafile.sh
fi