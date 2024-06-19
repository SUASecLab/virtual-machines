#!/bin/bash

echo "application::apache2-tls" >> /tmp/apps.txt

# Install TLS modules for apache
apt-get -y install libapache2-mod-security2
a2enmod rewrite ssl security2
systemctl restart apache2

# Enforce stronger encryption, 50%
if [ $((0 + $RANDOM % 10)) -lt 5 ]; then
    echo "configuration::apache2::ssl::honor-cipher-order::on" >> /tmp/configuration.txt
    sed -i 's|#SSLHonorCipherOrder on|SSLHonorCipherOrder on|g' /etc/apache2/mods-available/ssl.conf
fi

# only TLSv1.2+, 50%; only TLSv1.3, 20%
TLS_VERSIONS=$((0 + $RANDOM % 10))
if [ $TLS_VERSIONS -lt 5 ]; then
    echo "configuration::apache2::ssl::tlsv1.2,tlsv1.3::on" >> /tmp/configuration.txt
    sed -i 's|SSLProtocol all -SSLv3|SSLProtocol -all +TLSv1.2 +TLSv1.3|g' /etc/apache2/mods-available/ssl.conf
elif [ $TLS_VERSIONS -lt 7 ]; then
    echo "configuration::apache2::ssl::tlsv1.3::on" >> /tmp/configuration.txt
    sed -i 's|SSLProtocol all -SSLv3|SSLProtocol -all +TLSv1.3|g' /etc/apache2/mods-available/ssl.conf
fi

# Enable only specific cipher suites, 30%
if [ $((0 + $RANDOM % 10)) -lt 3 ]; then
    echo "configuration::apache2::ssl::honor-cipher-order::on" >> /tmp/configuration.txt
    echo "configuration::apache2::ssl::cipher-suite::enhanced" >> /tmp/configuration.txt
    sed -i 's|#SSLHonorCipherOrder on|SSLHonorCipherOrder on|g' /etc/apache2/mods-available/ssl.conf
    sed -i 's|SSLCipherSuite HIGH:!aNULL|SSLCipherSuite ECDH+AESGCM:ECDH+CHACHA20:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS:!AESCCM|g' /etc/apache2/mods-available/ssl.conf
fi

# Restart apache
systemctl restart apache2
