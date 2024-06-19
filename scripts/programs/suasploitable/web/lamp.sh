#!/bin/bash

echo "application::lamp" >> /tmp/apps.txt

bash /tmp/apache.sh
bash /tmp/db_install.sh
bash /tmp/php-apache.sh
bash /tmp/php-composer.sh