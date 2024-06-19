#!/bin/bash

# Enable unattended-upgrades with a probability of 60%
if [ $((0 + $RANDOM % 10)) -lt 6 ]; then
    echo "application::unattended-upgrades" >> /tmp/apps.txt
    apt-get install -y unattended-upgrades

cat >>/etc/apt/apt.conf.d/10periodic <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

fi