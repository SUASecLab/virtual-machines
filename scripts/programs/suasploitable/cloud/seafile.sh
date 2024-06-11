#!/bin/bash
echo "Installing SeaFile"

mkdir -p /srv/seafile
cd /srv/seafile

# Create compose file
# based on https://manual.seafile.com/docker/docker-compose/ce/11.0/docker-compose.ym
mv /tmp/seafile_compose.yml docker-compose.yml

# Change DB root password, 80%
if [ $((0 + $RANDOM % 10)) -lt 8 ]; then
    export SEAFILE_DB_PASSWORD=$(openssl rand -base64 20)
    echo "Changing seafile db password to $SEAFILE_DB_PASSWORD"
    sed -i "s|MYSQL_ROOT_PASSWORD=db_dev|MYSQL_ROOT_PASSWORD=$SEAFILE_DB_PASSWORD|g" docker-compose.yml
    sed -i "s|DB_ROOT_PASSWD=db_dev|DB_ROOT_PASSWD=$SEAFILE_DB_PASSWORD|g" docker-compose.yml
fi

# Change default user, 90%
if [ $((0 + $RANDOM % 10)) -lt 9 ]; then
    export SEAFILE_ADMIN_EMAIL=superuser@example.com
    export SEAFILE_ADMIN_PASSWORD=$(openssl rand -base64 20)
    echo "Changing seafile user password to $SEAFILE_ADMIN_PASSWORD"
    sed -i "s|SEAFILE_ADMIN_PASSWORD=asecret|SEAFILE_ADMIN_PASSWORD=$SEAFILE_DB_PASSWSEAFILE_ADMIN_PASSWORDORD|g" docker-compose.yml
fi

# HTTPS, 70%
if [ $((0 + $RANDOM % 10)) -lt 9 ]; then
    echo "Enabling HTTPS"

    # Generate certificate
    openssl req -x509 -newkey rsa:4096 -keyout /srv/seafile/key.pem -out /srv/seafile/cert.pem -sha256 -days 3650 -nodes -subj "/C=DE/ST=Thuringia/L=Schmalkalden/O=SUAS/OU=SUASecLab/CN=cloud.suaseclab.de"

    # Adjust docker configuration
    sed -i 's|#- "443:443"|- "443:443"|g' docker-compose.yml
    sed -i "s|#- FORCE_HTTPS_IN_CONF=true|- FORCE_HTTPS_IN_CONF=true|g" docker-compose.yml
    sed -i "s|SEAFILE_SERVER_LETSENCRYPT=false|SEAFILE_SERVER_LETSENCRYPT=true|g" docker-compose.yml
    sed -i "s|#- /srv/seafile/cert.pem:/shared/ssl/cloud.suaseclab.de.crt|- /srv/seafile/cert.pem:/shared/ssl/cloud.suaseclab.de.crt|g" docker-compose.yml
    sed -i "s|#- /srv/seafile/key.pem:/shared/ssl/cloud.suaseclab.de.key|- /srv/seafile/key.pem:/shared/ssl/cloud.suaseclab.de.key|g" docker-compose.yml
fi

docker compose -f docker-compose.yml up -d