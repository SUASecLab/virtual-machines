#!/bin/bash
apt-get install -y php-{mysql,cgi,curl,intl,json,mbstring,common,,mysqli,phpseclib}

# Enable mysql
sed -i "s|;extension=mysqli|extension=mysqli|g" /etc/php/*/apache2/php.ini

# Install db configuration web tool (60%)
# phpmyadmin (70%) or adminer (30%)

DB_WEB_TOOL_PATH="/var/www/html"

if [ -d "/var/www/nextcloud" ]; then
    DB_WEB_TOOL_PATH="/var/www/nextcloud"
elif [ -d "/srv/wp" ]; then
    DB_WEB_TOOL_PATH="/srv/wp"
elif [ -d "/srv/drupal" ]; then
    DB_WEB_TOOL_PATH="/srv/drupal"
fi

if [ $((0 + $RANDOM % 10)) -lt 7 ]; then
   echo "configuration::phpmyadmin" >> /tmp/configuration.txt

    # Install phpmyadmin
    wget -P /tmp https://files.phpmyadmin.net/phpMyAdmin/4.9.11/phpMyAdmin-4.9.11-all-languages.tar.gz
    mkdir -p $DB_WEB_TOOL_PATH/phpmyadmin
    tar xvf /tmp/phpMyAdmin-4.9.11-all-languages.tar.gz --strip-components=1 -C $DB_WEB_TOOL_PATH/phpmyadmin
    cp $DB_WEB_TOOL_PATH/phpmyadmin/config.sample.inc.php $DB_WEB_TOOL_PATH/phpmyadmin/config.inc.php
    chown www-data:www-data $DB_WEB_TOOL_PATH/phpmyadmin -R
else
    echo "configuration::adminer" >> /tmp/configuration.txt
    wget -P /tmp https://github.com/vrana/adminer/releases/download/v5.3.0/adminer-5.3.0.php
    mv /tmp/adminer-5.3.0.php $DB_WEB_TOOL_PATH/adminer.php
    chown www-data:www-data $DB_WEB_TOOL_PATH/adminer.php
fi

