#!/bin/bash

# Change port with probability of 30%
if [ $((0 + $RANDOM % 10)) -lt 3 ]; then
    NEW_PORT=$((2000 + $RANDOM % 1000))
    echo "Changing port to $NEW_PORT"
    sed -i "s|#Port 22|Port $NEW_PORT|g" /etc/ssh/sshd_config
fi

# Permit root login: 10% yes, 10% prohibit-password, 80% no
ROOT_LOGIN=$((0 + $RANDOM % 10))

if [ $ROOT_LOGIN -eq 0 ]; then
    echo "Allowing root login"
    sed -i "s|#PermitRootLogin prohibit-password|PermitRootLogin yes|g" /etc/ssh/sshd_config
elif [ $ROOT_LOGIN -eq 1 ]; then
    echo "Allowing root login but disallowing passwords"
    sed -i "s|#PermitRootLogin prohibit-password|PermitRootLogin prohibit-password|g" /etc/ssh/sshd_config
else
    echo "Disallowing root login"
    sed -i "s|#PermitRootLogin prohibit-password|PermitRootLogin no|g" /etc/ssh/sshd_config
fi

# Enable pubkey authentication: 30% no, 70% yes
if [ $((0 + $RANDOM % 10)) -lt 3 ]; then
    echo "Enabling pubkey authentication"
    sed -i "s|#PubkeyAuthentication yes|PubkeyAuthentication yes|g" /etc/ssh/sshd_config
else
    echo "Disabling pubkey authentication"
    sed -i "s|#PubkeyAuthentication yes|PubkeyAuthentication no|g" /etc/ssh/sshd_config
fi

# Enable password authentication: 80% no, 20% yes
if [ $((0 + $RANDOM % 10)) -lt 3 ]; then
    echo "Enabling password authentication"
    sed -i "s|#PasswordAuthentication yes|PasswordAuthentication no|g" /etc/ssh/sshd_config
else
    echo "Disabling password authentication"
    sed -i "s|#PasswordAuthentication yes|PasswordAuthentication yes|g" /etc/ssh/sshd_config
fi

# Install fail2ban, 50%
if [ $((0 + $RANDOM % 10)) -lt 5 ]; then
    NEW_PORT=$((2000 + $RANDOM % 1000))
    echo "Installing fail2ban"
    apt-get install -y fail2ban
fi