#/!bin/bash

# Allow kali user to run wireshark and metasploitable
cat >>/etc/sudoers.d/kali <<EOF
laboratory laboratory = (root) NOPASSWD: /usr/bin/wireshark
laboratory laboratory = (root) NOPASSWD: /usr/bin/msfdb
EOF

# Install lzop
apt-get install lzop -y

# Network
mv /tmp/network.sh /opt/network.sh
# Disable swap
(crontab -l 2>/dev/null; echo "* * * * * sudo bash /opt/network.sh") | crontab -