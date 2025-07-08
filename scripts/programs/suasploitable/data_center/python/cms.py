#!/bin/env python3

from configuration import *
import environment
import identities
import mail
import password
import random
import webserver

config = Configuration()

# Unattended upgrades
config = environment.unattended(config)

# SSH
config = environment.ssh(config)

# Decide on CMS application (Drupal or WordPress (50% each))
config.conf_dict["cms_application"] = "drupal" if config.gacha.pull(50) == True else "wordpress"

# Application is Drupal
if config.conf_dict["cms_application"] == "drupal":
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
mv /tmp/drupal_apache_tls.conf /etc/apache2/sites-available/drupal-tls.conf
a2ensite drupal-tls.conf
            """
        elif config.conf_dict["webserver"]["stack"] == "LEMP":
            config = webserver.tls(config)
            config.install_script += """
# Configure nginx
mv /tmp/drupal_nginx_tls.conf /etc/nginx/sites-available/drupal-tls
ln -s /etc/nginx/sites-available/drupal-tls /etc/nginx/sites-enabled/drupal-tls
           """
    else:
        config.conf_dict["web"]["tls"] = False
        config.flags.append("TLS")


    #  Enable non-TLS site
    if config.conf_dict["webserver"]["stack"] == "LAMP":
        config.install_script += """
mv /tmp/drupal_apache.conf /etc/apache2/sites-available/drupal.conf
a2ensite drupal.conf
a2enmod rewrite
systemctl restart apache2
            """
    elif config.conf_dict["webserver"]["stack"] == "LEMP":
        config.install_script += """
mv /tmp/drupal_nginx.conf /etc/nginx/sites-available/drupal
ln -s /etc/nginx/sites-available/drupal /etc/nginx/sites-enabled/drupal 
systemctl restart nginx
            """

    # Install Drupal
    
    # Create installation directory and install dependencies
    config.install_script += """
mkdir -p /srv
cd /srv
apt-get install -y zip unzip
apt-get install -y php-curl php-gd php-mbstring php-mysql php-opcache php-readline php-sqlite3 php-xml php-zip php-apcu
export COMPOSER_ALLOW_SUPERUSER=1
    """

    # Configure to install old drupal version with security issues (40%)
    if config.gacha.pull(40):
        config.install_script += """
composer create-project drupal/recommended-project:10.1.3 drupal
        """
        config.flags.append("CVE-2023-5256")
        config.conf_dict["drupal"]["version"] = "10.1.3"
    else:
        config.install_script += """
composer create-project drupal/recommended-project:10.5.1 drupal
        """
        config.conf_dict["drupal"]["version"] = "10.5.1"

    # Add dependencies and fix access rights
    config.install_script += """
cd /srv/drupal
composer install
composer require drush/drush
export PATH=/srv/drupal/vendor/bin:$PATH
chown www-data:www-data /srv/drupal/web -R
    """
    
    # Create Drupal database
    if config.conf_dict["database"]["application"] == "mysql":
        config.install_script += f"""
mysql -u root -p{config.conf_dict["database"]["root_password"]} -e "CREATE DATABASE drupal CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
        """
    else:
        config.install_script += """
mysql -u root -e "CREATE DATABASE drupal CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
        """

    # Set Drupal DB user credentials (insecure password: 30%)
    config.conf_dict["drupal"]["db"]["user"] = "vagrant"

    if config.conf_dict["database"]["remote_connections_allowed"] \
        and not config.conf_dict["database"]["insecure_account"]["exists"] \
        and config.gacha.pull(30, True):
        config.conf_dict["drupal"]["db"]["password"] = password.insecure_password()
        config.flags.append(config.conf_dict["drupal"]["db"]["password"])
    else:
        config.conf_dict["drupal"]["db"]["password"] = password.secure_password()
 
    # Grant privileges on all databases (60%)
    if config.gacha.pull(60):
        if config.conf_dict["database"]["application"] == "mysql":
            config.install_script += f"""
mysql -u root -p{config.conf_dict["database"]["root_password"]} -e "CREATE USER '{config.conf_dict["drupal"]["db"]["user"]}'@'%' IDENTIFIED BY '{config.conf_dict["drupal"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON *.* TO '{config.conf_dict["drupal"]["db"]["user"]}'@'%'; FLUSH PRIVILEGES;"
        """
        else:
            config.install_script += f"""
mysql -u root -e "CREATE USER '{config.conf_dict["drupal"]["db"]["user"]}'@'%' IDENTIFIED BY '{config.conf_dict["drupal"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON *.* TO '{config.conf_dict["drupal"]["db"]["user"]}'@'%'; FLUSH PRIVILEGES;"
        """
            config.conf_dict["drupal"]["db"]["privileges_on_all_dbs"] = True
    else:
        if config.conf_dict["database"]["application"] == "mysql":
            config.install_script += f"""
mysql -u root -p{config.conf_dict["database"]["root_password"]} -e "CREATE USER '{config.conf_dict["drupal"]["db"]["user"]}'@'%' IDENTIFIED BY '{config.conf_dict["drupal"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON drupal.* TO '{config.conf_dict["drupal"]["db"]["user"]}'@'%'; FLUSH PRIVILEGES;"
            """
        else:
            config.install_script += f"""
mysql -u root -e "CREATE USER '{config.conf_dict["drupal"]["db"]["user"]}'@'%' IDENTIFIED BY '{config.conf_dict["drupal"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON drupal.* TO '{config.conf_dict["drupal"]["db"]["user"]}'@'%'; FLUSH PRIVILEGES;"
            """
        config.conf_dict["drupal"]["db"]["privileges_on_all_dbs"] = False
    
    # Set insecure admin password (30%)
    config.conf_dict["drupal"]["user"]["name"] = "admin"

    if config.gacha.pull(30, True):
        config.conf_dict["drupal"]["user"]["password"] = password.insecure_password()
        config.flags.append(config.conf_dict["drupal"]["user"]["password"])
    else:
        config.conf_dict["drupal"]["user"]["password"] = password.secure_password()

    # Install Drupal
    config.install_script += f"""
drush site-install demo_umami --db-url=mysql://{config.conf_dict["drupal"]["db"]["user"]}:{config.conf_dict["drupal"]["db"]["password"]}@localhost:3306/drupal \
    --account-name={config.conf_dict["drupal"]["user"]["name"]} --account-mail=admin@example.-com --account-pass={config.conf_dict["drupal"]["user"]["password"]} \
    --site-mail=admin@example.com --site-name=SUASploitable --no-interaction
    """

    # Run DB postinstall script
    config = webserver.database_postinstall(config)
else:
    # Application is WordPress

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
mv /tmp/wp_apache_tls.conf /etc/apache2/sites-available/wp-tls.conf
a2ensite wp-tls.conf
            """
        elif config.conf_dict["webserver"]["stack"] == "LEMP":
            config = webserver.tls(config)
            config.install_script += """
# Configure nginx
mv /tmp/wp_nginx_tls.conf /etc/nginx/sites-available/wp-tls
ln -s /etc/nginx/sites-available/wp-tls /etc/nginx/sites-enabled/wp-tls
          """
    else:
        config.conf_dict["web"]["tls"] = False
        config.flags.append("TLS")

    #  Enable non-TLS site
    if config.conf_dict["webserver"]["stack"] == "LAMP":
        config.install_script += """
mv /tmp/wp_apache.conf /etc/apache2/sites-available/wp.conf
a2ensite wp.conf
a2enmod rewrite
systemctl restart apache2
            """
    elif config.conf_dict["webserver"]["stack"] == "LEMP":
        config.install_script += """
mv /tmp/wp_nginx.conf /etc/nginx/sites-available/wp        
ln -s /etc/nginx/sites-available/wp /etc/nginx/sites-enabled/wp 
systemctl restart nginx
            """

    # Install Wordpress

    # Create installation directory and install dependencies
    config.install_script += """
apt-get install -y software-properties-common zip unzip
apt-get install -y php-curl php-gd php-mbstring php-xml php-zip php-xmlrpc
mkdir -p /srv/wp
wget -P /tmp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /tmp/wp-cli.phar
mv /tmp/wp-cli.phar /usr/bin/wp
    """

    # Add WP system user
    config.conf_dict["wp"]["sys_user"]["username"] = "wordpress"

    # Insecure password: 30%
    if config.gacha.pull(30):
        config.conf_dict["wp"]["sys_user"]["password"] = password.insecure_password()
        config.flags.append(config.conf_dict["wp"]["sys_user"]["password"])
    else:
        config.conf_dict["wp"]["sys_user"]["password"] = password.secure_password()

    config.install_script += f"""
useradd -m -p {config.conf_dict["wp"]["sys_user"]["password"]} -s /bin/bash {config.conf_dict["wp"]["sys_user"]["username"]}
chown {config.conf_dict["wp"]["sys_user"]["username"]}:{config.conf_dict["wp"]["sys_user"]["username"]} /srv/wp -R
    """

    # Wordpress version: latest, 6.5.0 or 6.4.2 (33% each)
    if config.gacha.pull(33):
        config.conf_dict["wp"]["version"] = "latest"
    elif config.gacha.pull(33):
        config.conf_dict["wp"]["version"] = "6.5"
    else:
        config.conf_dict["wp"]["version"] = "6.4.2"

    config.install_script += f"""
sudo -u {config.conf_dict["wp"]["sys_user"]["username"]} wp core download --path=/srv/wp --version={config.conf_dict["wp"]["version"]}
    """

    # Create database
    if config.conf_dict["database"]["application"] == "mysql":
            config.install_script += f"""
mysql -u root -p{config.conf_dict["database"]["root_password"]} -e "CREATE DATABASE wp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
            """
    else:
        config.install_script += """
mysql -u root -e "CREATE DATABASE wp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
        """

    config.conf_dict["wp"]["db"]["user"] = "wp"

    # Insecure password for database user
    if config.conf_dict["database"]["remote_connections_allowed"] \
        and not config.conf_dict["database"]["insecure_account"]["exists"] \
        and config.gacha.pull(30, True):
        config.conf_dict["wp"]["db"]["password"] = password.insecure_password()
    else:
        config.conf_dict["wp"]["db"]["password"] = password.secure_password()

    # Create database user with privileges on all DBs (60%)
    if config.gacha.pull(60):
        if config.conf_dict["database"]["application"] == "mysql":
            config.install_script += f"""
mysql -u root -p{config.conf_dict["database"]["root_password"]} -e "CREATE USER '{config.conf_dict["wp"]["db"]["user"]}'@'%' IDENTIFIED BY '{config.conf_dict["wp"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON *.* TO '{config.conf_dict["wp"]["db"]["user"]}'@'%'; FLUSH PRIVILEGES;"
            """
        else:
            config.install_script += f"""
mysql -u root -e "CREATE USER '{config.conf_dict["wp"]["db"]["user"]}'@'%' IDENTIFIED BY '{config.conf_dict["wp"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON *.* TO '{config.conf_dict["wp"]["db"]["user"]}'@'%'; FLUSH PRIVILEGES;"
            """

        config.conf_dict["wp"]["db"]["privileges_on_all_dbs"] = True
    else:
        if config.conf_dict["database"]["application"] == "mysql":
            config.install_script += f"""
mysql -u root -p{config.conf_dict["database"]["root_password"]} -e "CREATE USER '{config.conf_dict["wp"]["db"]["user"]}'@'%' IDENTIFIED BY '{config.conf_dict["wp"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON wp.* TO '{config.conf_dict["wp"]["db"]["user"]}'@'%'; FLUSH PRIVILEGES;"
            """
        else:
            config.install_script += f"""
mysql -u root -e "CREATE USER '{config.conf_dict["wp"]["db"]["user"]}'@'%' IDENTIFIED BY '{config.conf_dict["wp"]["db"]["password"]}'; GRANT ALL PRIVILEGES ON wp.* TO '{config.conf_dict["wp"]["db"]["user"]}'@'%'; FLUSH PRIVILEGES;"
            """

        config.conf_dict["wp"]["db"]["privileges_on_all_dbs"] = False

    # Create admin user, insecure password: 20%
    config.conf_dict["wp"]["user"] = "admin"

    if config.gacha.pull(20, True):
        config.conf_dict["wp"]["password"] = password.insecure_password()
    else:
        config.conf_dict["wp"]["password"] = password.secure_password()
    
    # Proceed with installation
    config.install_script += f"""
cd /srv/wp
sudo -u {config.conf_dict["wp"]["sys_user"]["username"]} wp config create --dbname=wp --dbuser={config.conf_dict["wp"]["db"]["user"]} --dbpass={config.conf_dict["wp"]["db"]["password"]}
sudo -u {config.conf_dict["wp"]["sys_user"]["username"]} wp db create
sudo -u {config.conf_dict["wp"]["sys_user"]["username"]} wp core install --url=suaseclab.de --title="WP SUASploitable" --admin_user={config.conf_dict["wp"]["user"]} --admin_password={config.conf_dict["wp"]["password"]} --admin_email=test@example.com
    """

    # Update plugins (60%)
    if config.gacha.pull(60):
        config.install_script += f"""
sudo -u {config.conf_dict["wp"]["sys_user"]["username"]} wp plugin update --all
        """
        config.conf_dict["wp"]["plugins"]["updated"] = True
    else:
        config.conf_dict["wp"]["plugins"]["updated"] = False
    
    # Fix access rights
    config.install_script += """
chown www-data:www-data /srv/wp -R
    """

    # Run DB postinstall script
    config = webserver.database_postinstall(config)

# Generate identities
config = identities.generate_identities(config)

# Setup email server
config.install_script += f"""
debconf-set-selections <<< "postfix postfix/mailname string suaseclab.de"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Localhost only'"
apt-get -y install postfix
apt-get -y install dovecot-pop3d dovecot-imapd
postconf -e 'myhostname = suaseclab.de'
systemctl reload postfix
"""

# Send mails
config = mail.send_mail(config)

# Allow everyone to see the mails (30%)
if config.gacha.pull(30):
    config.conf_dict["mail"]["777"] = True
    config.install_script += """
chmod 777 /var/mail
    """
else:
    config.conf_dict["mail"]["777"] = False

# Setup TLS 80%
if not config.gacha.pull(20, True):
    config.conf_dict["mail"]["TLS"] = True
    config.install_script += """
mkdir -p /etc/postfix/ssl
cp /tmp/suaseclab.de.2048.crt /etc/postfix/ssl/suaseclab.crt
cp /tmp/suaseclab.de.2048.key /etc/postfix/ssl/suaseclab.key
cp /tmp/suasploitable_ca.crt /etc/postfix/ssl/ca.crt

postconf -e 'smtpd_sasl_local_domain ='
postconf -e 'smtpd_sasl_auth_enable = yes'
postconf -e 'smtpd_sasl_security_options = noanonymous'
postconf -e 'broken_sasl_auth_clients = yes'
postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'
postconf -e 'inet_interfaces = all'
postconf -e 'smtp_tls_security_level = may'
postconf -e 'smtpd_tls_security_level = may'
postconf -e 'smtpd_tls_auth_only = no'
postconf -e 'smtp_tls_note_starttls_offer = yes'
postconf -e 'smtpd_tls_key_file = /etc/postfix/ssl/suaseclab.key'
postconf -e 'smtpd_tls_cert_file = /etc/postfix/ssl/suaseclab.crt'
postconf -e 'smtpd_tls_CAfile = /etc/postfix/ssl/ca.crt'
postconf -e 'smtpd_tls_loglevel = 1'
postconf -e 'smtpd_tls_received_header = yes'
postconf -e 'smtpd_tls_session_cache_timeout = 3600s'
postconf -e 'tls_random_source = dev:/dev/urandom'
postconf -e 'smtp_use_tls = yes' 

echo "pwcheck_method: saslauthd" >> /etc/postfix/sasl/smtpd.conf
echo "mech_list: plain login" >> /etc/postfix/sasl/smtpd.conf

apt-get install libsasl2-2 sasl2-bin libsasl2-modules

systemctl restart postfix saslauthd

mv /etc/default/saslauthd /etc/default/saslauthd.bak

cat >>/etc/default/saslauthd <<EOF
DESC="SASL Authentication Daemon"
NAME="saslauthd"
MECHANISMS="pam"
MECH_OPTIONS=""
THREADS=5
START=yes
PWDIR="/var/spool/postfix/var/run/saslauthd"
PARAMS="-m ${PWDIR}"
PIDFILE="${PWDIR}/saslauthd.pid"
OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"
EOF
 
ln -s /etc/default/saslauthd /etc/saslauthd
systemctl start saslauthd
"""
else:
    config.conf_dict["mail"]["TLS"] = False

# Enforce encryption (80%)
if config.conf_dict["mail"]["TLS"] == True and config.gacha.pull(80):
    config.conf_dict["mail"]["TLS_enforced"] = True
    config.install_script += """
postconf -e 'smtpd_tls_security_level = encrypt' 
postconf -e 'smtp_tls_security_level = encrypt' 
postconf -e 'smtpd_enforce_tls = yes'

sed -i 's|#submission inet n       -       y       -       -       smtpd|submission inet n       -       y       -       -       smtpd|g' /etc/postfix/master.cf
    """
else:
    config.conf_dict["mail"]["TLS_enforced"] = False

# Joker
config = password.joker(config)

# Write configuration
config.write_configuration()