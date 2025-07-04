#!/bin/env python3

from configuration import *
import environment
import password
import webserver

config = Configuration()

# Unattended upgrades
config = environment.unattended(config)

# SSH
config = environment.ssh(config)

# Decide on cloud application (SeaFile or Nextcloud (50% each))
config.conf_dict["cloud_application"] = "nextcloud" if config.gacha.pull(50) == True else "seafile"

# Application is seafile
if config.conf_dict["cloud_application"] == "seafile":
    # Install docker
    config.install_script += """
bash /tmp/docker.sh
    """

    # Create and populate configuration directory
    config.install_script += """
mkdir -p /srv/seafile
cd /srv/seafile
mv /tmp/seafile_compose.yml docker-compose.yml
    """

    # Use old version with vulnerabilities (30&)
    if config.gacha.pull(30):
        config.install_script += """
sed -i "s|seafileltd/seafile-mc:11.0-latest|seafileltd/seafile-mc:11.0.10|g" docker-compose.yml
    """
        config.conf_dict["seafile"]["version"] = "11.0.10"
        config.flags.append("11.0.10")
    else:
        config.conf_dict["seafile"]["version"] = "latest"

    # Change DB root password (80%)
    if config.gacha.pull(20, True):
        # Insecure password
        config.conf_dict["db"]["password_type"] = "insecure"
        config.conf_dict["db"]["password"] = password.insecure_password()
        config.flags.append(config.conf_dict["db"]["password"])
    else:
        # Secure password
        config.conf_dict["db"]["password_type"] = "secure"
        config.conf_dict["db"]["password"] = password.secure_password()

    config.install_script += f"""
sed -i "s|MYSQL_ROOT_PASSWORD=db_dev|MYSQL_ROOT_PASSWORD={config.conf_dict["db"]["password"]}|g" docker-compose.yml
sed -i "s|DB_ROOT_PASSWD=db_dev|DB_ROOT_PASSWD={config.conf_dict["db"]["password"]}|g" docker-compose.yml
        """

    # Change default user password (80%)
    if config.gacha.pull(20, True):
        # Insecure password
        config.conf_dict["seafile"]["password_type"] = "insecure"
        config.conf_dict["seafile"]["password"] = password.insecure_password()
        config.flags.append(config.conf_dict["seafile"]["password"])
    else:
        # Secure password
        config.conf_dict["seafile"]["password_type"] = "secure"
        config.conf_dict["seafile"]["password"] = password.secure_password()
    
    config.install_script += f"""
sed -i "s|SEAFILE_ADMIN_PASSWORD=asecret|SEAFILE_ADMIN_PASSWORD={config.conf_dict["seafile"]["password"]}|g" docker-compose.yml
    """

    # Enable TLS (70%)
    if config.gacha.pull(70):
        config.conf_dict["web"]["tls"] = True
        
        config.install_script += """
# Certificate handling
bash /tmp/certs.sh

# Adjust docker configuration
sed -i 's|#- "443:443"|- "443:443"|g' docker-compose.yml
sed -i "s|#- FORCE_HTTPS_IN_CONF=true|- FORCE_HTTPS_IN_CONF=true|g" docker-compose.yml
sed -i "s|SEAFILE_SERVER_LETSENCRYPT=false|SEAFILE_SERVER_LETSENCRYPT=true|g" docker-compose.yml
sed -i "s|#- /srv/seafile/cert.pem:/shared/ssl/cloud.suaseclab.de.crt|- /srv/certs/cert.pem:/shared/ssl/cloud.suaseclab.de.crt|g" docker-compose.yml
sed -i "s|#- /srv/seafile/key.pem:/shared/ssl/cloud.suaseclab.de.key|- /srv/certs/key.pem:/shared/ssl/cloud.suaseclab.de.key|g" docker-compose.yml
        """
    else:
        config.conf_dict["web"]["tls"] = False
        config.flags.append("TLS")

    # Start SeaFile
    config.install_script += """
docker compose -f docker-compose.yml up -d
    """

    # Enable portainer (70%)
    if (config.gacha.pull(70)):
        config = environment.portainer(config)
else:
    # Nextcloud
    
    # Create directory
    config.install_script += """
mkdir -p /var/www/nextcloud
    """
    # Install LAMP or LAMP stack (50% each)
    if config.gacha.pull(50):
        config = webserver.lamp(config)
    else:
        config = webserver.lemp(config)

    # Enable TLS (70%)
    if config.gacha.pull(70):
        config.conf_dict["web"]["tls"] = True
        
        if config.conf_dict["webserver"]["stack"] == "LAMP":
            config.install_script += """
# Certificate handling
bash /tmp/certs.sh

# Configure apache
mv /tmp/nextcloud_apache_tls.conf /etc/apache2/sites-available/nextcloud-tls.conf
a2ensite nextcloud-tls.conf
            """
        elif config.conf_dict["webserver"]["stack"] == "LEMP":
            config.install_script += """
# Certificate handling
bash /tmp/certs.sh

# Configure nginx
mv /tmp/nextcloud_nginx_tls.conf /etc/nginx/sites-available/nextcloud-tls
ln -s /etc/nginx/sites-available/nextcloud-tls /etc/nginx/sites-enabled/nextcloud-tls
            """
    else:
        config.conf_dict["web"]["tls"] = False
        config.flags.append("TLS")

    #  Enable non-TLS site
    if config.conf_dict["webserver"]["stack"] == "LAMP":
        config.install_script += """
mv /tmp/nextcloud_apache.conf /etc/apache2/sites-available/nextcloud.conf
a2ensite nextcloud.conf
a2enmod rewrite headers env dir mime
systemctl restart apache2
            """
    elif config.conf_dict["webserver"]["stack"] == "LEMP":
        config.install_script += """
mv /tmp/nextcloud_nginx.conf /etc/nginx/sites-available/nextcloud
ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/nextcloud
systemctl restart nginx
            """

    # Install Nextcloud

    # Install required PHP modules
    config.install_script += """
apt-get install -y libxml2 zip curl zlib1g
apt-get install -y php-ctype php-curl php-dom php-fileinfo php-gd php-json php-mbstring php-posix php-xml php-zip php-mysql
    """

    # Create database
    config.install_script += """
mysql -u root -e "CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;";
    """

    # Password for Nextcloud DB user (insecure: 30%)
    if config.conf_dict["database"]["remote_connections_allowed"] \
        and not config.conf_dict["database"]["insecure_account"]["exists"] \
        and config.gacha.pull(30, True):
        config.conf_dict["nextcloud"]["db"]["password"] = password.insecure_password()
        config.flags.append(config.conf_dict["nextcloud"]["db"]["password"])
    else:
        config.conf_dict["nextcloud"]["db"]["password"] = password.secure_password()

    # Grant privileges on all databases (60%)
    if config.gacha.pull(60):
        config.install_script += f"""
mysql -u root -e "CREATE USER 'nextcloud'@'%' IDENTIFIED BY '{config.conf_dict["nextcloud"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON *.* TO 'nextcloud'@'localhost'; FLUSH PRIVILEGES;"
        """
        config.conf_dict["nextcloud"]["db"]["privileges_on_all_dbs"] = True
    else:
        config.install_script += f"""
mysql -u root -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '{config.conf_dict["nextcloud"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost'; FLUSH PRIVILEGES;"
        """
        config.conf_dict["nextcloud"]["db"]["privileges_on_all_dbs"] = False

    # Decide if Nextcloud user has insecure password (30% yes)
    config.conf_dict["nextcloud"]["user"] = "admin"

    if config.gacha.pull(30, True):
        config.conf_dict["nextcloud"]["password_insecure"] = True
        config.conf_dict["nextcloud"]["password"] = password.insecure_password()
        config.flags.append(config.conf_dict["nextcloud"]["password"])
    else:
        config.conf_dict["nextcloud"]["password_insecure"] = False
        config.conf_dict["nextcloud"]["password"] = password.secure_password()

    # Decide if insecure, old Nextcloud version is installed
    if config.gacha.pull(30):
        config.conf_dict["nextcloud"]["version"] = "28.0.3"
        config.install_script += """
wget -P /tmp https://download.nextcloud.com/server/releases/nextcloud-28.0.3.tar.bz2
tar -xf /tmp/nextcloud-28.0.3.tar.bz2 -C /var/www
        """
    else:
        config.install_script += """
wget -P /tmp https://download.nextcloud.com/server/releases/latest.tar.bz2
tar -xf /tmp/latest.tar.bz2 -C /var/www
        """
        config.conf_dict["nextcloud"]["version"] = "latest"

    # Fix access rights
    config.install_script += """
chown -R www-data:www-data /var/www/nextcloud/
    """

    # Install Nextcloud
    config.install_script += f"""
cd /var/www/nextcloud
NEXTCLOUD_INSTALLED=$(sudo -u www-data php occ maintenance:install \
    --database "mysql" --database-name "nextcloud" --database-user "nextcloud" \
    --database-pass {config.conf_dict["nextcloud"]["db"]["password"]} --admin-user "admin" --admin-pass {config.conf_dict["nextcloud"]["password"]})
if [[ $NEXTCLOUD_INSTALLED == *"Error"* ]]; then
    # fix installation (sometimes, NC install sets db user wrong)
    sudo -u www-data sed -i 's|oc_admin|nextcloud|g' /var/www/nextcloud/config/config.php
    sudo -u www-data php occ maintenance:install --database "mysql" --database-name "nextcloud" \
        --database-user "nextcloud" --database-pass {config.conf_dict["nextcloud"]["db"]["password"]} --admin-user "admin" --admin-pass {config.conf_dict["nextcloud"]["password"]}
fi
    """

    # Resolve access through untrusted domain
    config.install_script += """
(crontab -l 2>/dev/null; echo "* * * * * sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 0 --value=\$(hostname -I | awk '{print \$1}')") | crontab -
    """

    # Add cloud domain to list of trusted domains
    config.install_script += """
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 1 --value=cloud.suaseclab.de
    """

    # Run DB postinstall script
    config = webserver.database_postinstall(config)

# Write configuration
config.write_configuration()