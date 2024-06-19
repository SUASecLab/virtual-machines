#!/bin/bash

# Create certificates directory
mkdir -p /srv/certs

# Select certificate:  2048 Bit: 40%, 4096 Bit: 60%
HTTPS_CERT=$((0 + $RANDOM % 10))
if [ $HTTPS_CERT -lt 4 ]; then
    echo "configuration::ssl::certs::2048" >> /tmp/configuration.txt
    mv /tmp/suaseclab.de.2048.crt /srv/certs/cert.pem
    mv /tmp/suaseclab.de.2048.key /srv/certs/key.pem
else
    echo "configuration::ssl::certs::4096" >> /tmp/configuration.txt
    mv /tmp/suaseclab.de.4096.crt /srv/certs/cert.pem
    mv /tmp/suaseclab.de.4096.key /srv/certs/key.pem
fi