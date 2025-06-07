#!/bin/bash

# Create user accounts
useradd -m -d /home/mnickel -s /bin/bash mnickel
echo 'mnickel:testing' | chpasswd
usermod -a -G sudo mnickel

useradd -m -d /home/ksaenger -s /bin/bash ksaenger
echo 'ksaenger:sZU9Q1u1Egijf36hcPB6' | chpasswd

useradd -m -d /home/kfaber -s /bin/bash kfaber
echo 'kfaber:nj0xZSp1IwAFXbaICcH9' | chpasswd

useradd -m -d /home/sdietrich -s /bin/bash sdietrich
echo 'sdietrich:Y2Xm1w3CZLagU9Pvg6gb' | chpasswd

useradd -m -d /home/kfurst -s /bin/bash kfurst
echo 'kfurst:123456' | chpasswd

useradd -m -d /home/jjager -s /bin/bash jjager
echo 'jjager:mountain' | chpasswd

useradd -m -d /home/cschmitz -s /bin/bash cschmitz
echo 'cschmitz:ryrbky8zjvmWML5tcckD' | chpasswd