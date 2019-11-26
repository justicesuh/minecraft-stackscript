#!/bin/bash

# <UDF name="password" label="Password for non-root user">
# <UDF name="pubkey" label="SSH key for non-root user">

exec > /root/stackscript.log 2>&1

apt-get update
apt-get upgrade -y

echo 'Setting hostname...'
echo odm > /etc/hostname
hostname -F /etc/hostname

echo 'Creating odm user...'
adduser --disabled-password --gecos '' odm
adduser odm sudo
echo -e "$PASSWORD\n$PASSWORD\n" | passwd odm

echo 'Adding SSH key...'
mkdir /home/odm/.ssh
echo $PUBKEY > /home/odm/.ssh/authorized_keys
chmod -R 700 /home/odm/.ssh && chmod 600 /home/odm/.ssh/authorized_keys
chown -R odm:odm /home/odm/.ssh

echo 'Configuring SSH...'
sed -i 's/#*Port.*/Port 22/g' /etc/ssh/sshd_config
sed -i 's/#*AddressFamily.*/AddressFamily inet/g' /etc/ssh/sshd_config
sed -i 's/#*PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/#*PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
systemctl restart sshd

echo 'Setting up firewall...'
apt-get install -y ufw
ufw default allow outgoing
ufw default deny incoming
ufw allow 22
ufw --force enable

echo 'Installing Docker...'
apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce
adduser odm docker

echo 'Installing Screen...'
apt-get install -y screen
