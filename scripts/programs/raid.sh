#!/bin/bash

# Install mdadm, parted
apt-get install -y mdadm parted

# Allow every user to create new partitions
cat >>/etc/sudoers.d/heaven <<EOF
laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/mdadm
laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/parted

laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/mkfs
laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/mkfs.bfs
laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/mkfs.cramfs
laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/mkfs.exfat
laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/mkfs.ext2
laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/mkfs.ext3
laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/mkfs.ext4
laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/mkfs.fat
laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/mkfs.minix
laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/mkfs.msdos
laboratory $HOSTNAME = (root) NOPASSWD: /usr/sbin/mkfs.vfat
EOF
