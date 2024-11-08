#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/MickLesk/Proxmox_DEV/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ___                     __            ______                           __ 
   /   |  ____  ____ ______/ /_  ___     /_  __/___  ____ ___  _________ _/ /_
  / /| | / __ \/ __ `/ ___/ __ \/ _ \     / / / __ \/ __ `__ \/ ___/ __ `/ __/
 / ___ |/ /_/ / /_/ / /__/ / / /  __/    / / / /_/ / / / / / / /__/ /_/ / /_  
/_/  |_/ .___/\__,_/\___/_/ /_/\___/    /_/  \____/_/ /_/ /_/\___/\__,_/\__/  
      /_/                                                                     
EOF
}
header_info
echo -e "Loading..."
APP="Tomcat"
var_disk="5"
var_cpu="1"
var_ram="1024"
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
  VERB="yes"
  echo_default
}

function update_script() {
header_info
if [[ ! -d /opt/tomcat ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
if (( $(df /boot | awk 'NR==2{gsub("%","",$5); print $5}') > 80 )); then
  read -r -p "Warning: Storage is dangerously low, continue anyway? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] || exit
fi

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}/installer ${CL} \n"
