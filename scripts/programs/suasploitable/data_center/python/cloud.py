#!/bin/env python3

from configuration import *
import environment
import identities
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
    config = environment.docker(config)

    # Create and populate configuration directory
    config.install_script += """
mkdir -p /srv/seafile
cd /srv/seafile
mv /tmp/seafile_compose.yml docker-compose.yml
    """

    # Add container names to flags
    config.flags.append("seafile-mysql")
    config.flags.append("seafile-memcached")
    config.flags.append("seafile")

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
        config = webserver.tls(config)
        
        config.install_script += """
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
            config = webserver.tls(config)
            config.install_script += """
# Configure apache
mv /tmp/nextcloud_apache_tls.conf /etc/apache2/sites-available/nextcloud-tls.conf
a2ensite nextcloud-tls.conf
            """
        elif config.conf_dict["webserver"]["stack"] == "LEMP":
            config = webserver.tls(config)
            config.install_script += """
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
    if config.conf_dict["database"]["application"] == "mysql":
        config.install_script += f"""
mysql -u root -p{config.conf_dict["database"]["root_password"]} -e "CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;";
        """
    else:
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
        if config.conf_dict["database"]["application"] == "mysql":
            config.install_script += f"""
mysql -u root -p{config.conf_dict["database"]["root_password"]} -e "CREATE USER 'nextcloud'@'%' IDENTIFIED BY '{config.conf_dict["nextcloud"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON *.* TO 'nextcloud'@'%'; FLUSH PRIVILEGES;"
            """
        else:
            config.install_script += f"""
mysql -u root -e "CREATE USER 'nextcloud'@'%' IDENTIFIED BY '{config.conf_dict["nextcloud"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON *.* TO 'nextcloud'@'%'; FLUSH PRIVILEGES;"
            """
        config.conf_dict["nextcloud"]["db"]["privileges_on_all_dbs"] = True
    else:
        if config.conf_dict["database"]["application"] == "mysql":
            config.install_script += f"""
mysql -u root -p{config.conf_dict["database"]["root_password"]} -e "CREATE USER 'nextcloud'@'%' IDENTIFIED BY '{config.conf_dict["nextcloud"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'%'; FLUSH PRIVILEGES;"
            """
        else:
            config.install_script += f"""
mysql -u root -e "CREATE USER 'nextcloud'@'%' IDENTIFIED BY '{config.conf_dict["nextcloud"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'%'; FLUSH PRIVILEGES;"
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
if [[ $NEXTCLOUD_INSTALLED != *"Nextcloud was successfully installed"* ]]; then
    # fix installation (sometimes, NC install sets db user wrong)
    sudo -u www-data sed -i 's|oc_admin[0-9]*|nextcloud|g' /var/www/nextcloud/config/config.php
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

# Generate identities
config = identities.generate_identities(config)

# Install Samba
samba_flag = password.secure_password()
config.flags.append(samba_flag)
config.install_script += f"""
apt-get -y install samba
mkdir -p /srv/samba

echo "{samba_flag}" >> /srv/samba/flag.txt

cat > /tmp/smbconf << EOF

[sambashare]
    comment = Samba share
    path = /srv/samba
    read only = no
    browsable = yes
    writeable = yes
EOF
"""

# Public share (40%)
if config.gacha.pull(40, True):
    config.conf_dict["samba"]["public"] = True
    config.install_script += """
echo "public = yes" >> /tmp/smbconf
    """
else:
    # Generate list of valid SMB users
    valid_users = ""
    for user in config.conf_dict["identities"]:
        # Generate password
        config.install_script += f"""
(echo "{user["password"]}"; echo "{user["password"]}") | smbpasswd -s -a {user["userName"]}
        """

        # Add to user list
        if len(valid_users) == 0:
            valid_users = user["userName"]
        else:
            valid_users += " "
            valid_users += user["userName"]

    config.install_script += f"""
echo "valid users = {valid_users}" >> /tmp/smbconf
    """
    config.conf_dict["samba"]["public"] = False

# Write samba configuration
config.install_script += """
cat /tmp/smbconf >> /etc/samba/smb.conf
"""

config.conf_dict["ftp"]["server"] = "vsftpd" if config.gacha.pull(50) == True else "pureftpd"
if config.conf_dict["ftp"]["server"] == "vsftpd":
    # Install FTP server
    config.install_script += """
    apt-get -y install vsftpd
    systemctl enable vsftpd
    sed -i "s|listen=NO|listen=YES|g" /etc/vsftpd.conf
    sed -i "s|listen_ipv6=YES|#listen_ipv6=NO|g" /etc/vsftpd.conf
    """

    # Enable write (75%)
    if config.gacha.pull(75):
        config.install_script += """
    sed -i "s|#write_enable=YES|write_enable=YES|g" /etc/vsftpd.conf
    """ 
        config.conf_dict["ftp"]["write_enabled"] = True
    else:
        config.conf_dict["ftp"]["write_enabled"] = False

    # Enable anonymous FTP (40%)
    if config.gacha.pull(40):
        config.install_script += """
    sed -i "s|anonymous_enable=NO|anonymous_enable=YES|g" /etc/vsftpd.conf
    """
        config.conf_dict["ftp"]["anonymous"] = True

        # Allow everyone to upload files (70%)
        if config.gacha.pull(70):
            config.install_script += """
    sed -i "s|#anon_upload_enable=YES|anon_upload_enable=YES|g" /etc/vsftpd.conf
    """
            config.conf_dict["ftp"]["anonymous_upload"] = True
        else:
            config.conf_dict["ftp"]["anonymous_upload"] = False
    else:
        config.conf_dict["ftp"]["anonymous"] = False

    # Chroot to local dir (10%)
    if config.gacha.pull(90, True):
        config.conf_dict["ftp"]["chroot_local_user"] = False
    else:
        config.install_script += """
    sed -i "s|#chroot_local_user=YES|chroot_local_user=YES|g" /etc/vsftpd.conf
    """
        config.conf_dict["ftp"]["chroot_local_user"] = True

else:
    # Install old version with vulns (70%)
    if config.gacha.pull(70):
        config.conf_dict["ftp"]["version"] = "1.0.51"
        config.install_script += """
wget -P /tmp https://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-1.0.51.tar.gz
    """
        config.flags.append("CVE‑2024‑48208")
    else:
        config.conf_dict["ftp"]["version"] = "1.0.52"
        config.install_script += """
wget -P /tmp https://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-1.0.52.tar.gz
    """

    config.install_script += f"""
tar xvf /tmp/pure-ftpd-{config.conf_dict["ftp"]["version"]}.tar.gz -C /tmp
cd /tmp/pure-ftpd-{config.conf_dict["ftp"]["version"]}
./configure --with-everything
make install-strip
    """

    # Generate options
    options = ""
    
    # Enable anonymous FTP (40%)
    if config.gacha.pull(75):
        config.conf_dict["ftp"]["anonymous"] = True
        options += "--anonymousonly"

        config.install_script += """
mkdir -p /var/ftp
useradd -d /var/ftp -s /sbin/nologin ftp
chown ftp:ftp /var/ftp -R
        """

        # Allow everyone to upload files (30%)
        if config.gacha.pull(30):
            config.conf_dict["ftp"]["anonymous_write_enabled"] = True
        else:
            config.conf_dict["ftp"]["anonymous_write_enabled"] = False
            options += " --anonymouscantupload"
    else:
        config.conf_dict["ftp"]["anonymous"] = False
        options += "-l unix --noanonymous"
        
        # Chroot to local dir (10%, true)
        if config.gacha.pull(10):
            options += " --chrooteveryone"
            config.conf_dict["ftp"]["chroot_local_user"] = True
        else:
            config.conf_dict["ftp"]["chroot_local_user"] = False


    config.install_script += f"""
    # Create systemd service
cat >>/lib/systemd/system/pureftpd.service <<EOF
[Unit]
Description=FTP Server

[Service]
User=root
Group=root
ExecStart=/usr/local/sbin/pure-ftpd {options}
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

systemctl start pureftpd
systemctl enable pureftpd
"""

# Joker
config = password.joker(config)

# Change vagrant password
config = environment.change_vagrant_password(config)

# Write configuration
config.write_configuration()