#!/bin/bash
cd /home/laboratory

# Unpack ant
tar -xzf /tmp/apache-ant-1.10.14-bin.tar.gz
mv apache-ant-1.10.14 /opt

export PATH="$PATH:/opt/apache-ant-1.10.14/bin"

# Persitently extend path
cat >>/home/laboratory/.bashrc <<EOF
export PATH="\$PATH:/opt/apache-ant-1.10.14/bin"
EOF

# Also add ant to /usr/bin
ln -s $(which ant) /usr/bin/ant