#!/bin/bash

# <UDF name="fqdn" label="Fully Qualified Domain Name">

# get ip address
IPADDR=$(ip addr show eth0 | awk '/inet / { print $2 }' | sed 's/\/[0-9]*//')

# set hostname
HOSTNAME=minecraft
echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname
echo $IPADDR $FQDN $HOSTNAME >> /etc/hosts
