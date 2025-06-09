#/!bin/bash

# Allow kali user to run wireshark and metasploitable
cat >>/etc/sudoers.d/kali <<EOF
laboratory laboratory = (root) NOPASSWD: /usr/bin/wireshark
laboratory laboratory = (root) NOPASSWD: /usr/bin/msfdb
EOF

# Install lzop
apt-get install lzop -y

# Install fcrackzip
sudo apt -y install fcrackzip dirsearch nuclei

# Network
mv /tmp/network.sh /opt/network.sh
chmod a+x /opt/network.sh

# Setup networking script
(crontab -l 2>/dev/null; echo "* * * * * sudo bash /opt/network.sh") | crontab -

## Configure TCP client
# Compile
python -c "import py_compile; py_compile.compile('/tmp/tcp_client.py')"
cp /tmp/__pycache__/tcp_client.*.pyc /opt/tcp_client
chmod a+x /opt/tcp_client

# Create crontab entry
(crontab -l 2>/dev/null; echo "* * * * * /opt/tcp_client") | crontab -

## Install SUASecLab CA cert

# Operating system
apt-get -y install ca-certificates
cp /tmp/suasploitable_ca.crt /usr/local/share/ca-certificates
update-ca-certificates

# Firefox
mkdir -p /usr/lib/mozilla/certificates
cp /tmp/suasploitable_ca.crt /usr/lib/mozilla/certificates
mv /tmp/firefox_policies.json /usr/lib/firefox-esr/distribution/policies.json

## Disable screensaver and hibernate
mv /tmp/kali_environment.sh /opt/kali_environment.sh
chmod a+x /opt/kali_environment.sh

# Create autostart directory
mkdir -p /home/laboratory/.config/autostart
cd /home/laboratory/.config/autostart

# Run script
touch xfce_environment.desktop
desktop-file-edit \
    --set-name="Set up environment" \
    --set-key="Type" --set-value="Application" \
    --set-key="Exec" --set-value="/opt/kali_environment.sh" \
    xfce_environment.desktop