#/!bin/bash

# Allow kali user to run wireshark and metasploitable
cat >>/etc/sudoers.d/kali <<EOF
laboratory laboratory = (root) NOPASSWD: /usr/bin/wireshark
laboratory laboratory = (root) NOPASSWD: /usr/bin/msfdb
EOF