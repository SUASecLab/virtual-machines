#!/bin/bash

# Change port with probability of 30%
if [ $((0 + $RANDOM % 10)) -lt 3 ]; then
    NEW_PORT=$((2000 + $RANDOM % 1000))
    echo "configuration::ssh::port::$NEW_PORT" >> /tmp/configuration.txt
    sed -i "s|#Port 22|Port $NEW_PORT|g" /etc/ssh/sshd_config
else
    echo "configuration::ssh::port::22" >> /tmp/configuration.txt
    echo "22" >> /tmp/flags.txt
fi

# Permit root login: 10% yes, 10% prohibit-password, 80% no
ROOT_LOGIN=$((0 + $RANDOM % 10))

if [ $ROOT_LOGIN -eq 0 ]; then
    echo "configuration::ssh::root-login::enabled" >> /tmp/configuration.txt
    echo "PermitRootLogin" >> /tmp/flags.txt
    sed -i "s|#PermitRootLogin prohibit-password|PermitRootLogin yes|g" /etc/ssh/sshd_config
elif [ $ROOT_LOGIN -eq 1 ]; then
    echo "configuration::ssh::root-login::prohibit-password" >> /tmp/configuration.txt
    echo "prohibit-password" >> /tmp/flags.txt
    sed -i "s|#PermitRootLogin prohibit-password|PermitRootLogin prohibit-password|g" /etc/ssh/sshd_config
else
    echo "configuration::ssh::root-login::disabled" >> /tmp/configuration.txt
    sed -i "s|#PermitRootLogin prohibit-password|PermitRootLogin no|g" /etc/ssh/sshd_config
fi

# Enable pubkey authentication: 30% no, 70% yes
if [ $((0 + $RANDOM % 10)) -lt 3 ]; then
    echo "configuration::ssh::pubkey-authentication::enabled" >> /tmp/configuration.txt
    sed -i "s|#PubkeyAuthentication yes|PubkeyAuthentication yes|g" /etc/ssh/sshd_config
else
    echo "configuration::ssh::pubkey-authentication::disabled" >> /tmp/configuration.txt
    sed -i "s|#PubkeyAuthentication yes|PubkeyAuthentication no|g" /etc/ssh/sshd_config
    echo "PubkeyAuthentication" >> /tmp/flags.txt
fi

# Enable password authentication: 80% no, 20% yes
if [ $((0 + $RANDOM % 10)) -lt 2 ]; then
    echo "configuration::ssh::password-authentication::enabled" >> /tmp/configuration.txt
    echo "PasswordAuthentication" >> /tmp/flags.txt
    sed -i "s|#PasswordAuthentication yes|PasswordAuthentication yes|g" /etc/ssh/sshd_config
else
    echo "configuration::ssh::password-authentication::disabled" >> /tmp/configuration.txt
    sed -i "s|#PasswordAuthentication yes|PasswordAuthentication no|g" /etc/ssh/sshd_config
fi

# Install fail2ban, 50%
if [ $((0 + $RANDOM % 10)) -lt 5 ]; then
    echo "application::fail2ban" >> /tmp/apps.txt
    apt-get install -y fail2ban
else
    echo "application::no-fail2ban" >> /tmp/apps.txt
    echo "ips" >> /tmp/flags.txt
fi