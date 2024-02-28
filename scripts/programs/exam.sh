#!/bin/bash
mkdir -p /home/laboratory/bin
cd /home/laboratory/bin

# Add bin to path
export PATH="$PATH:/home/laboratory/bin"

# Also add  bin to bashrc
cat >>/home/laboratory/.bashrc <<EOF
export PATH="\$PATH:/home/laboratory/bin"
EOF

# Add smbclient
apt-get install smbclient -y

# Move file pushed in hcl file to correcty directory
mv /tmp/pushExam.sh /home/laboratory/bin/
chmod a+x /home/laboratory/bin/*.sh