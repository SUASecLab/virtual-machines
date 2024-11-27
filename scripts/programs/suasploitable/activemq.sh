#!/bin/bash

# Unpack ActiveMQ
tar -xzf /tmp/apache-activemq-5.18.0-bin.tar.gz
mv apache-activemq-5.18.0 /srv

# Automatically start
(crontab -l 2>/dev/null; echo "@reboot sudo /srv/apache-activemq-5.18.0/bin/activemq start") | crontab -

echo "CVE-2023-46604" >> /tmp/flags.txt