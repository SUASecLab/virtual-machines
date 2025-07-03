#!/bin/bash
mkdir -p /srv/seafile
cd /srv/seafile

# Create compose file
# based on https://manual.seafile.com/docker/docker-compose/ce/11.0/docker-compose.yml
mv /tmp/seafile_compose.yml docker-compose.yml

# Old version with security issues (30% yes)
if [ $((0 + $RANDOM % 10)) -lt 3 ]; then
    echo "configuration::seafile::insecure" >> /tmp/configuration.txt
    sed -i "s|seafileltd/seafile-mc:11.0-latest|seafileltd/seafile-mc:11.0.10|g" docker-compose.yml
    echo "11.0.10" >> /tmp/flags.txt
else
    echo "configuration::seafile::secure" >> /tmp/configuration.txt
fi

# Change DB root password, 80%
if [ $((0 + $RANDOM % 10)) -lt 8 ]; then
# Secure password: 50 %
    if [ $((0 + $RANDOM % 10)) -lt 5 ]; then
        export SEAFILE_DB_PASSWORD=$(openssl rand -base64 20)
        echo "configuration::seafile::db-password::secure" >> /tmp/configuration.txt
    else
        export SEAFILE_DB_PASSWORD=$(/tmp/password.py)
        echo "configuration::seafile::db-password::top-500" >> /tmp/configuration.txt
        echo $SEAFILE_DB_PASSWORD >> /tmp/flags.txt
    fi
    sed -i "s|MYSQL_ROOT_PASSWORD=db_dev|MYSQL_ROOT_PASSWORD=$SEAFILE_DB_PASSWORD|g" docker-compose.yml
    sed -i "s|DB_ROOT_PASSWD=db_dev|DB_ROOT_PASSWD=$SEAFILE_DB_PASSWORD|g" docker-compose.yml
else
    echo "configuration::seafile::db-password::insecure" >> /tmp/configuration.txt
    echo "db_dev" >> /tmp/flags.txt
fi

# Change default user password, 70%
if [ $((0 + $RANDOM % 10)) -lt 7 ]; then
# Secure pasword: 50 %
    export SEAFILE_ADMIN_PASSWORD=$(/tmp/password.py)
    if [ $((0 + $RANDOM % 10)) -lt 5 ]; then
        export SEAFILE_ADMIN_PASSWORD=$(openssl rand -base64 20)
        echo "configuration::seafile::user-password::secure" >> /tmp/configuration.txt
    else
        echo "configuration::seafile::user-password::top-500" >> /tmp/configuration.txt
        echo $SEAFILE_ADMIN_PASSWORD >> /tmp/flags.txt
    fi
    sed -i "s|SEAFILE_ADMIN_PASSWORD=asecret|SEAFILE_ADMIN_PASSWORD=$SEAFILE_ADMIN_PASSWORD|g" docker-compose.yml
else
    echo "configuration::seafile::user-password::insecure" >> /tmp/configuration.txt
    echo "asecret" >> /tmp/flags.txt
fi

# HTTPS, 70%
if [ $((0 + $RANDOM % 10)) -lt 7 ]; then
    echo "configuration::seafile::tls::enabled" >> /tmp/configuration.txt

    # Certificate handling
    bash /tmp/certs.sh

    # Adjust docker configuration
    sed -i 's|#- "443:443"|- "443:443"|g' docker-compose.yml
    sed -i "s|#- FORCE_HTTPS_IN_CONF=true|- FORCE_HTTPS_IN_CONF=true|g" docker-compose.yml
    sed -i "s|SEAFILE_SERVER_LETSENCRYPT=false|SEAFILE_SERVER_LETSENCRYPT=true|g" docker-compose.yml
    sed -i "s|#- /srv/seafile/cert.pem:/shared/ssl/cloud.suaseclab.de.crt|- /srv/certs/cert.pem:/shared/ssl/cloud.suaseclab.de.crt|g" docker-compose.yml
    sed -i "s|#- /srv/seafile/key.pem:/shared/ssl/cloud.suaseclab.de.key|- /srv/certs/key.pem:/shared/ssl/cloud.suaseclab.de.key|g" docker-compose.yml
else
    echo "configuration::seafile::tls::disabled" >> /tmp/configuration.txt
    echo "TLS" >> /tmp/flags.txt
fi

docker compose -f docker-compose.yml up -d