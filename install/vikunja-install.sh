#!/usr/bin/env bash

# Copyright (c) 2021-2024 communtiy-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
  curl \
  sudo \
  make \
  mc
msg_ok "Installed Dependencies"

msg_info "Setup Vikunja (Patience)"
cd /opt
RELEASE=$(curl -s https://dl.vikunja.io/vikunja/ | grep -oP 'href="/vikunja/\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n 1)
wget -q "https://dl.vikunja.io/vikunja/$RELEASE/vikunja-$RELEASE-amd64.deb"
$STD DEBIAN_FRONTEND=noninteractive dpkg -i vikunja-$RELEASE-amd64.deb
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Vikunja"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/vikunja-$RELEASE-amd64.deb
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"
