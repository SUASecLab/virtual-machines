#!/bin/bash

chmod u+x /tmp/*.sh
if [ $((0 + $RANDOM % 2)) -eq 0 ]; then
    echo "Installing Drupal"

    WEBSERVER=$((0 + $RANDOM % 2))

    if [ $WEBSERVER -eq 0 ]; then
        echo "Using LAMP stack"

        # Install LAMP
        bash /tmp/lamp.sh
        
        # Create configuration file for web server
        mv /tmp/drupal_apache.conf /etc/apache2/sites-available/drupal.conf

        # Enable site
        a2ensite drupal.conf
        a2enmod rewrite
        systemctl restart apache2
    else
        echo "Using LEMP stack"

        # Install LEMP
        bash /tmp/lemp.sh

        # Configure NGINX
        mv /tmp/drupal_nginx.conf /etc/nginx/sites-available/drupal
        unlink /etc/nginx/sites-enabled/default
        ln -s /etc/nginx/sites-available/drupal /etc/nginx/sites-enabled/drupal 
        systemctl restart nginx
    fi

    # Install drupal
    bash /tmp/drupal.sh
else
    echo "Installing Wordpress"

    WEBSERVER=$((0 + $RANDOM % 2))
    if [ $WEBSERVER -eq 0 ]; then
        echo "Using LAMP stack"

        # Install LAMP
        bash /tmp/lamp.sh        

        # Create configuration file for web server
        mv /tmp/wp_apache.conf /etc/apache2/sites-available/wp.conf

        # Enable site
        a2ensite wp.conf
        a2enmod rewrite
        systemctl restart apache2
    else
        echo "Using LEMP stack"

        # Install LEMP
        bash /tmp/lemp.sh

        # Configure NGINX
        mv /tmp/wp_nginx.conf /etc/nginx/sites-available/wp
        unlink /etc/nginx/sites-enabled/default
        ln -s /etc/nginx/sites-available/wp /etc/nginx/sites-enabled/wp 
        systemctl restart nginx
    fi

    # Install WP
    bash /tmp/wp.sh
fi