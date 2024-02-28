#!/bin/bash

# Note: this can only be run after the installation of docker
# Include 'docker.sh' before this script

# Create directories
mkdir -p /home/laboratory/.webserver-conf/apache
mkdir -p /home/laboratory/.webserver-conf/docker
mkdir -p /home/laboratory/webroot

# Create apache configuration file
cat >>/home/laboratory/.webserver-conf/apache/docker-php.conf <<EOF
<FilesMatch \.php$>
    SetHandler application/x-httpd-php
</FilesMatch>

DirectoryIndex disabled
DirectoryIndex index.php index.html

<Directory /var/www/>
    AllowOverride All
</Directory>
EOF

# Create docker configuration file
cat >>/home/laboratory/.webserver-conf/docker/webserver.yaml <<EOF
version: "3"
services:
  web:
    image: php:8.3-apache
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - "/home/laboratory/webroot:/var/www/html"
      - "/home/laboratory/.webserver-conf/apache:/etc/apache2/conf-available"
EOF

# Create php info file for webroot
cat >>/home/laboratory/webroot/phpinfo.php <<EOF
<?php phpinfo(); ?>
EOF

cd /home/laboratory/.webserver-conf/docker
docker compose -f webserver.yaml up -d