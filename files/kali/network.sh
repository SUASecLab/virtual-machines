#!/bin/bash

# Get current network
MY_NET=$(hostname -I | awk '{print $1}' | awk -F'.' '{print $1"."$2"."$3".0/24"}')

# Get all hosts in net
NMAP_RESULT=$(nmap -F $MY_NET)

# Iterate over hosts: first argument: line from nmap scan, second argument: wished URL
convert_line() {
	IP=$(echo $1 | awk -F' ' '{print $6}')
	IP=$(echo $IP | sed "s|(||g")
	IP=$(echo $IP | sed "s|)||g")
	echo $IP $2
}

# Create IP <-> URL pairs: look for hostnames in nmap scan result
IP_URL_PAIRS=$(while IFS= read -r line
do
    if [[ $line == *"cloud."* ]]
    then
        convert_line "$line" "cloud.suaseclab.de"
    elif [[ $line == *"basic."* ]]
    then
    	convert_line "$line" "basic.suaseclab.de"
    elif [[ $line == *"dev."* ]]
    then
    	convert_line "$line" "dev.suaseclab.de"
    elif [[ $line == *"suaseclab."* ]]
    then
        convert_line "$line" "suaseclab.de"
    fi
done <<< "$NMAP_RESULT")

cat > /etc/hosts <<EOF
$IP_URL_PAIRS

127.0.0.1	localhost
127.0.1.1	laboratory

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
