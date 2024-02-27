#!/bin/bash

# Add kernel modules
cat >>/etc/modules <<EOF
loop
virtio
9p
9pnet
9pnet_virtio
EOF

# Start modules
service kmod start

# Create mount point
mkdir -p /media/share

# Add to fstab
cat >>/etc/fstab <<EOF
share /media/share  9p  trans=virtio    0   0
EOF
