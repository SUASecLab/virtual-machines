from configuration import Configuration
import password

def composer(conf: Configuration) -> Configuration:
    conf.install_script += """
php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
php -r "if (hash_file('sha384', '/tmp/composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php /tmp/composer-setup.php
php -r "unlink('/tmp/composer-setup.php');"
mv composer.phar /usr/local/bin/composer
    """
    return conf

def apache(conf: Configuration) -> Configuration:
    conf.install_script += """
apt-get install -y apache2
rm /etc/apache2/sites-enabled/000-default.conf
apt-get -y install libapache2-mod-security2
a2enmod rewrite ssl security2
systemctl restart apache2
apt-get install -y php libapache2-mod-php php-mysql
    """
    conf.conf_dict["webserver"]["application"] = "apache2"
    return composer(conf)

def nginx(conf: Configuration) -> Configuration:
    conf.install_script += """
apt-get install -y nginx
unlink /etc/nginx/sites-enabled/default
apt-get install -y php-fpm php-mysql
    """
    conf.conf_dict["webserver"]["application"] = "nginx"
    return composer(conf)

def database(conf: Configuration) -> Configuration:
    if conf.gacha.pull(50):
        conf.install_script += """
apt-get install -y mariadb-server
        """
        conf.conf_dict["database"]["application"] = "mariadb"
    else:
        conf.install_script += """
wget -P /tmp https://repo.mysql.com//mysql-apt-config_0.8.30-1_all.deb
dpkg -i /tmp/mysql-apt-config*.deb
apt-get update
apt-get install -y mysql-server
        """
        conf.conf_dict["database"]["application"] = "mysql"
    
    # Run secure install script (80%)
    if conf.gacha.pull(80):
        # Secure database
        conf.conf_dict["database"]["secure_install"] = True

        # Generate DB root password (80% secure)
        if conf.gacha.pull(80):
            conf.conf_dict["database"]["secure_root_password"] = True
            conf.conf_dict["database"]["root_password"] = password.secure_password()
        else:
            conf.conf_dict["database"]["secure_root_password"] = False
            conf.conf_dict["database"]["root_password"] = password.insecure_password()

        # Set passwords
        conf.install_script += f"""
mysql --user=root <<_EOF_
UPDATE mysql.user SET Password=PASSWORD('{conf.conf_dict["database"]["root_password"]}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_
        """

    else:
        # Insecure database
        conf.conf_dict["database"]["secure_install"] = False
    
    # Enable remote connections (70% no)
    if conf.gacha.pull(30):
        # Remote connections allowed
        conf.conf_dict["database"]["remote_connections_allowed"] = True

        if conf.conf_dict["database"]["application"] == "mariadb":
            conf.install_script += """
sed -i "s|127.0.0.1|0.0.0.0|g" /etc/mysql/mariadb.conf.d/50-server.cnf
            """
        elif conf.conf_dict["database"]["application"] == "mysql":
            conf.install_script += """
echo "bind-address = 0.0.0.0" >> /etc/mysql/mysql.conf.d/mysqld.cnf
            """

        # Add an insecure account that can be accessed (30%)
        if conf.gacha.pull(30, True):
            conf.conf_dict["database"]["insecure_account"]["exists"] = True
            conf.conf_dict["database"]["insecure_account"]["username"] = "admin"
            conf.conf_dict["database"]["insecure_account"]["password"] = password.insecure_password()

            if conf.gacha.pull(25, True): # With permission granting option
                conf.conf_dict["database"]["insecure_account"]["granting_option"] = True
                conf.install_script += f"""
mysql -u root -e "CREATE USER '{conf.conf_dict["database"]["insecure_account"]["username"]}'@'%' IDENTIFIED BY '{conf.conf_dict["database"]["insecure_account"]["password"]}'; GRANT ALL PRIVILEGES ON *.* TO '{conf.conf_dict["database"]["insecure_account"]["username"]}'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
                """
            else:
                conf.conf_dict["database"]["insecure_account"]["granting_option"] = False
                conf.install_script += f"""
mysql -u root -e "CREATE USER '{conf.conf_dict["database"]["insecure_account"]["username"]}'@'%' IDENTIFIED BY '{conf.conf_dict["database"]["insecure_account"]["password"]}'; GRANT ALL PRIVILEGES ON *.* TO '{conf.conf_dict["database"]["insecure_account"]["username"]}'@'%'; FLUSH PRIVILEGES;"
                """
        else:
            conf.conf_dict["database"]["insecure_account"]["exists"] = False

    else:
        # Remote connections disallowed
        conf.conf_dict["database"]["remote_connections_allowed"] = False
    return conf

def database_postinstall(conf: Configuration) -> Configuration:
    # Install a web DB administration tool (60%)
    if conf.gacha.pull(40):
        return conf
    
    # Install dependencies and enable mysql
    conf.install_script += """
apt-get install -y php-{mysql,cgi,curl,intl,json,mbstring,common,,mysqli,phpseclib}
sed -i "s|;extension=mysqli|extension=mysqli|g" /etc/php/*/apache2/php.ini
    """

    # Get path of the webserver installation
    conf.install_script += """
DB_WEB_TOOL_PATH="/var/www/html"

if [ -d "/var/www/nextcloud" ]; then
    DB_WEB_TOOL_PATH="/var/www/nextcloud"
elif [ -d "/srv/wp" ]; then
    DB_WEB_TOOL_PATH="/srv/wp"
elif [ -d "/srv/drupal" ]; then
    DB_WEB_TOOL_PATH="/srv/drupal"
fi
    """

    # Install phpMyAdmin (70%) or adminer (30%)
    if conf.gacha.pull(70):
        conf.conf_dict["database"]["web_tool"] = "phpmyadmin"
        conf.install_script += """
wget -P /tmp https://files.phpmyadmin.net/phpMyAdmin/4.9.11/phpMyAdmin-4.9.11-all-languages.tar.gz
mkdir -p $DB_WEB_TOOL_PATH/phpmyadmin
tar xvf /tmp/phpMyAdmin-4.9.11-all-languages.tar.gz --strip-components=1 -C $DB_WEB_TOOL_PATH/phpmyadmin
cp $DB_WEB_TOOL_PATH/phpmyadmin/config.sample.inc.php $DB_WEB_TOOL_PATH/phpmyadmin/config.inc.php
chown www-data:www-data $DB_WEB_TOOL_PATH/phpmyadmin -R
        """
    else:
        conf.conf_dict["database"]["web_tool"] = "adminer"
        conf.install_script += """
echo "configuration::adminer" >> /tmp/configuration.txt
wget -P /tmp https://github.com/vrana/adminer/releases/download/v5.3.0/adminer-5.3.0.php
mv /tmp/adminer-5.3.0.php $DB_WEB_TOOL_PATH/adminer.php
chown www-data:www-data $DB_WEB_TOOL_PATH/adminer.php
        """
    return conf

def lamp(conf: Configuration) -> Configuration:
    conf.conf_dict["webserver"]["stack"] = "LAMP"
    conf = apache(conf)
    return database(conf)

def lemp(conf: Configuration) -> Configuration:
    conf.conf_dict["webserver"]["stack"] = "LEMP"
    conf = nginx(conf)
    return database(conf)