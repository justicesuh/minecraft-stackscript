#!/bin/bash

# <UDF name="fqdn" label="Fully Qualified Domain Name">
# <UDF name="password" label="Password for non-root user">
# <UDF name="pubkey" label="SSH key for non-root user">
# <UDF name="op" label="Minecraft OP username">>

exec > /root/stackscript.log 2>&1

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
chown -R minecraft:minecraft /home/minecraft/.ssh

# ssh settings
sed -i 's/#*Port.*/Port 22/g' /etc/ssh/sshd_config
sed -i 's/#*AddressFamily.*/AddressFamily inet/g' /etc/ssh/sshd_config
sed -i 's/#*PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/#*PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
systemctl restart sshd

# set up firewall
echo 'Set up firewall...'
apt-get install -y ufw
ufw default allow outgoing
ufw default deny incoming
ufw allow 22
ufw allow 25565
ufw --force enable

# install packages
echo 'Installing packages...'
apt-get install -y openjdk-8-jre-headless screen jq

# download minecraft
echo 'Downloading minecraft...'
cd /home/minecraft
wget https://launcher.mojang.com/v1/objects/808be3869e2ca6b62378f9f4b33c946621620019/server.jar -O minecraft_server.1.14.2.jar
echo eula=true > eula.txt

# add initial OP
echo 'Setting initial OP user...'
UUID=$(curl -s https://api.mojang.com/users/profiles/minecraft/$OP | jq '.id')
UUID=${UUID:0:9}-${UUID:9:4}-${UUID:13:4}-${UUID:17:4}-${UUID:21:13}
cat > ops.json <<EOF
[
  {
    "uuid": $UUID,
    "name": "$OP",
    "level": 4
  }
]
EOF

chown -R minecraft:minecraft /home/minecraft

# set up systemd service
echo 'Setting up systemd...'
cat > /etc/systemd/system/minecraft.service <<EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
WorkingDirectory=/home/minecraft
User=minecraft
Group=minecraft
ProtectSystem=true

ExecStart=/usr/bin/screen -DmS minecraft /usr/bin/java -Xms1024M -Xmx3584M -jar minecraft_server.1.14.2.jar nogui

ExecReload=/usr/bin/screen -p 0 -S minecraft -X eval 'stuff "reload"\\015"'

ExecStop=/usr/bin/screen -p 0 -S minecraft -X eval 'stuff "say Shutting Down Server.  Saving Map..."\\015'
ExecStop=/usr/bin/screen -p 0 -S minecraft -X eval 'stuff "save-all"\\015'
ExecStop=/usr/bin/screen -p 0 -S minecraft -X eval 'stuff "stop"\\015'
ExecStop=/bin/sleep 10

Restart=on-failure
RestartSec=120s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable minecraft
systemctl start minecraft
