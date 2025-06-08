#!/bin/bash

# Create user accounts
useradd -m -d /home/mnickel -s /bin/bash mnickel
echo 'mnickel:testing' | chpasswd
usermod -a -G sudo mnickel

# Name of sudo user
echo "mnickel" >> /tmp/flags.txt

# System password
echo "testing" >> /tmp/flags.txt

useradd -m -d /home/ksaenger -s /bin/bash ksaenger
echo 'ksaenger:sZU9Q1u1Egijf36hcPB6' | chpasswd

useradd -m -d /home/kfaber -s /bin/bash kfaber
echo 'kfaber:nj0xZSp1IwAFXbaICcH9' | chpasswd

useradd -m -d /home/sdietrich -s /bin/bash sdietrich
echo 'sdietrich:Y2Xm1w3CZLagU9Pvg6gb' | chpasswd

useradd -m -d /home/kfurst -s /bin/bash kfurst
echo 'kfurst:fish' | chpasswd

# System password
echo "fish" >> /tmp/flags.txt

useradd -m -d /home/jjager -s /bin/bash jjager
echo 'jjager:mountain' | chpasswd

# System password
echo "mountain" >> /tmp/flags.txt

# Hide a flag here
echo 'flag:ug7Xo82i' >> /home/jjager/info.txt
chown jjager:jjager /home/jjager/info.txt
chmod 400 /home/jjager/info.txt

# Flag
echo "ug7Xo82i" >> /tmp/flags.txt

useradd -m -d /home/cschmitz -s /bin/bash cschmitz
echo 'cschmitz:ryrbky8zjvmWML5tcckD' | chpasswd

# Remove superuser from vagrant user (must be last)
chown vagrant /home/vagrant/ -R
rm /etc/sudoers.d/vagrant
gpasswd --delete vagrant sudo