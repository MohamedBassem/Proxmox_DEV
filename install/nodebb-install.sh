#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE
# Source: https://github.com/NodeBB/NodeBB

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y --no-install-recommends \
  build-essential \
  curl \
  unzip \
  sudo \
  git \
  make \
  gnupg \
  ca-certificates \
  mc
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js & MongoDB Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
$STD apt-get update
msg_ok "Set up Repositories"

msg_info "Installing Node.js"
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing MongoDB"
$STD sudo apt-get install -y mongodb-org
sudo systemctl start mongod
sleep 5 # MongoDB needs some secounds to start, if not sleep it collide with following mongosh
msg_ok "Installed MongoDB"   

msg_info "Configure MongoDB"
MONGO_ADMIN_USER="admin"
MONGO_ADMIN_PWD="$(openssl rand -base64 18 | cut -c1-13)"
NODEBB_USER="nodebb"
NODEBB_PWD="$(openssl rand -base64 18 | cut -c1-13)"
NODEBB_SECRET=$(uuidgen)
{
    echo "NodeBB-Credentials"
    echo "Mongo Database User: $MONGO_ADMIN_USER"
    echo "Mongo Database Password: $MONGO_ADMIN_PWD"
    echo "NodeBB User: $NODEBB_USER"
	echo "NodeBB Password: $NODEBB_PWD"
	echo "NodeBB Secret: $NODEBB_SECRET"
} >> ~/nodebb.creds

$STD mongosh <<EOF
use admin
db.createUser({
  user: "$MONGO_ADMIN_USER",
  pwd: "$MONGO_ADMIN_PWD",
  roles: [{ role: "root", db: "admin" }]
})

use nodebb
db.createUser({
  user: "$NODEBB_USER",
  pwd: "$NODEBB_PWD",
  roles: [
    { role: "readWrite", db: "nodebb" },
    { role: "clusterMonitor", db: "admin" }
  ]
})
quit()
EOF
sudo sed -i '/security:/d' /etc/mongod.conf
sudo bash -c 'echo -e "\nsecurity:\n  authorization: enabled" >> /etc/mongod.conf'
sudo systemctl restart mongod
msg_ok "MongoDB successfully configurated" 

msg_info "Install NodeBB" 
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/NodeBB/NodeBB/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/NodeBB/NodeBB/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
mv NodeBB-${RELEASE} /opt/nodebb
cd /opt/nodebb
NODEBB_USER=$(grep "NodeBB User" ~/nodebb.creds | awk -F: '{print $2}' | xargs)
NODEBB_PWD=$(grep "NodeBB Password" ~/nodebb.creds | awk -F: '{print $2}' | xargs)
NODEBB_SECRET=$(grep "NodeBB Secret" ~/nodebb.creds | awk -F: '{print $2}' | xargs)
cat <<EOF >/opt/nodebb/config.json
{
    "url": "http://localhost:4567",
    "secret": "$NODEBB_SECRET",
    "database": "mongo",
    "mongo": {
        "host": "127.0.0.1",
        "port": "27017",
        "username": "$NODEBB_USER",
        "password": "$NODEBB_PWD",
        "database": "nodebb",
        "uri": ""
    },
    "port": "4567"
}
EOF
#$STD ./nodebb setup
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed NodeBB"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/nodebb.service
[Unit]
Description=NodeBB
Documentation=https://docs.nodebb.org
After=system.slice multi-user.target mongod.service

[Service]
Type=forking
User=root

WorkingDirectory=/opt/nodebb/nodebb
PIDFile=/opt/nodebb/pidfile
ExecStart=/usr/bin/env node loader.js --no-silent
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now nodebb
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -R /opt/v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
