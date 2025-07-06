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
wget -P /tmp https://repo.mysql.com/mysql-apt-config_0.8.33-1_all.deb
dpkg -i /tmp/mysql-apt-config*.deb
apt-get update
apt-get install -y mysql-server
        """
        conf.conf_dict["database"]["application"] = "mysql"
    
    # Run secure install script (80% mariadb, 100% mysql)
    if conf.conf_dict["database"]["application"] == "mysql" or conf.gacha.pull(80):
        # Secure database
        conf.conf_dict["database"]["secure_install"] = True

        # Generate DB root password (80% secure)
        if conf.gacha.pull(80):
            conf.conf_dict["database"]["secure_root_password"] = True
            conf.conf_dict["database"]["root_password"] = password.secure_password()
        else:
            conf.conf_dict["database"]["secure_root_password"] = False
            conf.conf_dict["database"]["root_password"] = password.insecure_password()

        # Install expect program we use to secure the installation
        conf.install_script += """
apt-get -y install expect
        """

        # Set passwords
        if conf.conf_dict["database"]["application"] == "mariadb":
            # MariaDB
            conf.install_script += f"""
cat > /tmp/sql_secure.sh <<EOF
#!/usr/bin/expect -f

set timeout 10
set password ""
set new_password "{conf.conf_dict["database"]["root_password"]}"

spawn mysql_secure_installation

expect "Enter current password for root (enter for none):"
send "\$password\r"

expect "Switch to unix_socket authentication"
send "y\r"

expect "Change the root password?"
send "y\r"

expect "New password:"
send "$new_password\r"

expect "Re-enter new password:"
send "$new_password\r"

expect "Remove anonymous users?"
send "y\r"

expect "Disallow root login remotely?"
send "y\r"

expect "Remove test database and access to it?"
send "y\r"

expect "Reload privilege tables now?"
send "y\r"
EOF


chmod a+x /tmp/sql_secure.sh
/tmp/sql_secure.sh
            """
        else:
            conf.install_script += f"""
cat > /etc/mysql/conf.d/enable-mysql-native-password.cnf <<EOF
[mysqld]
mysql_native_password=ON
EOF

systemctl restart mysql
mysql -u root -pvagrant -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '{conf.conf_dict["database"]["root_password"]}';"

cat > /tmp/sql_secure.sh <<EOF
#!/usr/bin/expect -f

set timeout 10
set password "{conf.conf_dict["database"]["root_password"]}"

spawn mysql_secure_installation

expect "Enter password for user root: "
send "\$password\r"

expect "Press y|Y for Yes, any other key for No:"
send "n\r"

expect "Change the password for root"
send "n\r"

expect "Remove anonymous users?"
send "y\r"

expect "Disallow root login remotely?"
send "y\r"

expect "Remove test database and access to it?"
send "y\r"

expect "Reload privilege tables now?"
send "y\r"
EOF

chmod a+x /tmp/sql_secure.sh
/tmp/sql_secure.sh
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
                
                if conf.conf_dict["database"]["application"] == "mysql":
                    conf.install_script += f"""
mysql -u root -p{conf.conf_dict["database"]["root_password"]} -e "CREATE USER '{conf.conf_dict["database"]["insecure_account"]["username"]}'@'%' IDENTIFIED BY '{conf.conf_dict["database"]["insecure_account"]["password"]}'; GRANT ALL PRIVILEGES ON *.* TO '{conf.conf_dict["database"]["insecure_account"]["username"]}'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
                    """
                else:
                    conf.install_script += f"""
mysql -u root -e "CREATE USER '{conf.conf_dict["database"]["insecure_account"]["username"]}'@'%' IDENTIFIED BY '{conf.conf_dict["database"]["insecure_account"]["password"]}'; GRANT ALL PRIVILEGES ON *.* TO '{conf.conf_dict["database"]["insecure_account"]["username"]}'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
                    """
            else:
                conf.conf_dict["database"]["insecure_account"]["granting_option"] = False

                if conf.conf_dict["database"]["application"] == "mysql":
                    conf.install_script += f"""
mysql -u root -p{conf.conf_dict["database"]["root_password"]} -e "CREATE USER '{conf.conf_dict["database"]["insecure_account"]["username"]}'@'%' IDENTIFIED BY '{conf.conf_dict["database"]["insecure_account"]["password"]}'; GRANT ALL PRIVILEGES ON *.* TO '{conf.conf_dict["database"]["insecure_account"]["username"]}'@'%'; FLUSH PRIVILEGES;"
                    """
                else:
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
sed -i "s|;extension=mysqli|extension=mysqli|g" /etc/php/*/*/php.ini
    """

    # Get path of the webserver installation
    conf.install_script += """
DB_WEB_TOOL_PATH="/var/www/html"

if [ -d "/var/www/nextcloud" ]; then
    DB_WEB_TOOL_PATH="/var/www/nextcloud"
elif [ -d "/srv/wp" ]; then
    DB_WEB_TOOL_PATH="/srv/wp"
elif [ -d "/srv/drupal" ]; then
    DB_WEB_TOOL_PATH="/srv/drupal/web"
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