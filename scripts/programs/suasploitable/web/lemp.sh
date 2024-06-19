#!/bin/bash

echo "application::lemp" >> /tmp/apps.txt

bash /tmp/nginx.sh
bash /tmp/db_install.sh
bash /tmp/php-nginx.sh
bash /tmp/php-composer.sh