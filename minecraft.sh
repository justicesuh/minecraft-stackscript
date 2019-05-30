#!/bin/bash

# <UDF name="fqdn" label="Fully Qualified Domain Name">

# get ip address
IPADDR=$(ip addr show eth0 | awk '/inet / { print $2 }' | sed 's/\/[0-9]*//')

# update
apt-get update
apt-get upgrade -y

# set hostname
echo 'Setting hostname...'
echo minecraft > /etc/hostname
hostname -F /etc/hostname
echo $IPADDR $FQDN minecraft >> /etc/hosts

# create minecraft user
echo 'Create minecraft user...'
adduser --disabled-password --gecos '' minecraft
adduser minecraft sudo
echo -e "$PASSWORD\n$PASSWORD\n" | passwd minecraft

# ssh keys
echo 'Add SSH keys...'
mkdir /home/minecraft/.ssh
echo $PUBKEY > /home/minecraft/.ssh/authorized_keys
chmod -R 700 /home/minecraft/.ssh && chmod 600 /home/minecraft/.ssh/authorized_keys
chown -R mincraft:minecraft /home/minecraft/.ssh

# set up firewall
echo 'Set up firewall...'
apt-get install -y ufw
ufw default allow outgoing
ufw default deny incoming
ufw allow 22
ufw allow 25565
ufw --force enable
