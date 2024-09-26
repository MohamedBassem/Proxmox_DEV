#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/MickLesk/Proxmox_DEV/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/MickLesk/Proxmox_DEV/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____                    _      __  
   /  _/___ ___  ____ ___  (_)____/ /_ 
   / // __ `__ \/ __ `__ \/ / ___/ __ \
 _/ // / / / / / / / / / / / /__/ / / /
/___/_/ /_/ /_/_/ /_/ /_/_/\___/_/ /_/ 
                                       
EOF
}
header_info
echo -e "Loading..."
APP="Immich"
var_disk="50"
var_cpu="4"
var_ram="4096"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
header_info
INSTALL_DIR_app=/home/immich/app
if [[ ! -d $INSTALL_DIR_app ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
if (( $(df /boot | awk 'NR==2{gsub("%","",$5); print $5}') > 80 )); then
  read -r -p "Warning: Storage is dangerously low, continue anyway? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] || exit
fi
rm -rf $INSTALL_DIR_app

su immich -c "git clone https://github.com/loeeeee/immich-in-lxc.git /tmp"

msg_info "Stopping immich"
systemctl stop immich-microservices.service
systemctl stop immich-ml.service
systemctl stop immich-web.service
msg_ok "Stopped immich"

cd /tmp/immich-in-lxc
#su immich -c "/tmp/install.sh" # creates env file
# Replace password in runtime.env file
#sed -i 's/A_SEHR_SAFE_PASSWORD/YUaaWZAvtL@JpNgpi3z6uL4MmDMR_w/g' runtime.env

msg_info "Updating immich"

su immich -c "/tmp/install.sh" # runs rest of script

msg_ok "Updated immich"

msg_info "Starting immich"
systemctl stop immich-microservices.service
systemctl stop immich-ml.service
systemctl stop immich-web.service
msg_ok "Started immich"

msg_info "Cleaning Up"
rm -rf /tmp/immich-in-lxc
msg_ok "Cleaned"
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:3001${CL} \n"