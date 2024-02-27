#!/bin/bash
cd /home/laboratory

# Unpack OpenJDK
tar -xzf /tmp/openjdk-17+35_linux-x64_bin.tar.gz
mv jdk-17 /opt

# Set new environment variables directly
export JAVA_HOME="/opt/jdk-17"
export PATH="$PATH:$JAVA_HOME/bin"

# Also add new variables to bashrc
cat >>/home/laboratory/.bashrc <<EOF
export JAVA_HOME="/opt/jdk-17"
export PATH="\$PATH:\$JAVA_HOME/bin"
EOF

# Also add java and javac to /usr/bin
ln -s $(which java) /usr/bin/java
ln -s $(which javac) /usr/bin/javac