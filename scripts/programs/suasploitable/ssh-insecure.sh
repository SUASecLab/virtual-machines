#!/bin/bash


# Permit root login

echo "configuration::ssh::root-login::enabled" >> /tmp/configuration.txt
sed -i "s|#PermitRootLogin prohibit-password|PermitRootLogin yes|g" /etc/ssh/sshd_config


# Disable pubkey auth
echo "configuration::ssh::pubkey-authentication::disabled" >> /tmp/configuration.txt
sed -i "s|#PubkeyAuthentication yes|PubkeyAuthentication no|g" /etc/ssh/sshd_config

# Enable password authentication
echo "configuration::ssh::password-authentication::enabled" >> /tmp/configuration.txt
sed -i "s|#PasswordAuthentication yes|PasswordAuthentication yes|g" /etc/ssh/sshd_config