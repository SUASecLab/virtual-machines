#!/bin/bash

chmod u+x /tmp/*.sh
if [ $((0 + $RANDOM % 2)) -eq 0 ]; then
    echo "application::drupal" >> /tmp/apps.txt

    WEBSERVER=$((0 + $RANDOM % 2))

    if [ $WEBSERVER -eq 0 ]; then
        # Install LAMP
        bash /tmp/lamp.sh
        
        # Create configuration file for web server: 70% TLS 30% no TLS
        if [ $((0 + $RANDOM % 10)) -lt 7 ]; then
            bash /tmp/certs.sh
            bash /tmp/apache-tls.sh
            echo "configuration::drupal::tls::enabled" >> /tmp/configuration.txt
            mv /tmp/drupal_apache_tls.conf /etc/apache2/sites-available/drupal-tls.conf
            a2ensite drupal-tls.conf
        else
            echo "configuration::drupal::tls::disabled" >> /tmp/configuration.txt
            echo "TLS" >> /tmp/flags.txt
        fi

        # Enable site
        mv /tmp/drupal_apache.conf /etc/apache2/sites-available/drupal.conf
        a2ensite drupal.conf
        a2enmod rewrite
        systemctl restart apache2
    else
        # Install LEMP
        bash /tmp/lemp.sh

        # Configure NGINX: 70% TLS 30% no TLS
        if [ $((0 + $RANDOM % 10)) -lt 7 ]; then
            bash /tmp/certs.sh
            echo "configuration::drupal::tls::enabled" >> /tmp/configuration.txt
            mv /tmp/drupal_nginx_tls.conf /etc/nginx/sites-available/drupal-tls
            ln -s /etc/nginx/sites-available/drupal-tls /etc/nginx/sites-enabled/drupal-tls
        else
            echo "configuration::drupal::tls::disabled" >> /tmp/configuration.txt
            echo "TLS" >> /tmp/flags.txt
        fi

        mv /tmp/drupal_nginx.conf /etc/nginx/sites-available/drupal
        ln -s /etc/nginx/sites-available/drupal /etc/nginx/sites-enabled/drupal 
        systemctl restart nginx
    fi

    # Install drupal
    bash /tmp/drupal.sh
else
    echo "application::wordpress" >> /tmp/apps.txt

    WEBSERVER=$((0 + $RANDOM % 2))
    if [ $WEBSERVER -eq 0 ]; then
        # Install LAMP
        bash /tmp/lamp.sh        

        # Create configuration file for web server: 70% TLS 30% no TLS
        if [ $((0 + $RANDOM % 10)) -lt 7 ]; then
            bash /tmp/certs.sh
            bash /tmp/apache-tls.sh
            echo "configuration::wp::tls::enabled" >> /tmp/configuration.txt
            mv /tmp/wp_apache_tls.conf /etc/apache2/sites-available/wp-tls.conf
            a2ensite wp-tls.conf
        else
            echo "configuration::wp::tls::disabled" >> /tmp/configuration.txt
            echo "TLS" >> /tmp/flags.txt
        fi

        # Enable site
        mv /tmp/wp_apache.conf /etc/apache2/sites-available/wp.conf
        a2ensite wp.conf
        a2enmod rewrite
        systemctl restart apache2
    else
        # Install LEMP
        bash /tmp/lemp.sh

        # Configure NGINX: 70% TLS 30% no TLS
        if [ $((0 + $RANDOM % 10)) -lt 7 ]; then
            bash /tmp/certs.sh
            echo "configuration::wp::tls::enabled" >> /tmp/configuration.txt
            mv /tmp/wp_nginx_tls.conf /etc/nginx/sites-available/wp-tls
            ln -s /etc/nginx/sites-available/wp-tls /etc/nginx/sites-enabled/wp-tls
        else
            echo "configuration::wp::tls::disabled" >> /tmp/configuration.txt
            echo "TLS" >> /tmp/flags.txt
        fi

        mv /tmp/wp_nginx.conf /etc/nginx/sites-available/wp        
        ln -s /etc/nginx/sites-available/wp /etc/nginx/sites-enabled/wp 
        systemctl restart nginx
    fi

    # Install WP
    bash /tmp/wp.sh
fi