#!/bin/bash
# ar18

# Script template version 2021-06-12.03
# Make sure some modification to LD_PRELOAD will not alter the result or outcome in any way
LD_PRELOAD_old="${LD_PRELOAD}"
LD_PRELOAD=
# Determine the full path of the directory this script is in
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
script_path="${script_dir}/$(basename "${0}")"
#Set PS4 for easier debugging
export PS4='\e[35m${BASH_SOURCE[0]}:${LINENO}: \e[39m'
# Determine if this script was sourced or is the parent script
if [ ! -v ar18_sourced_map ]; then
  declare -A -g ar18_sourced_map
fi
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  ar18_sourced_map["${script_path}"]=1
else
  ar18_sourced_map["${script_path}"]=0
fi
# Initialise exit code
if [ -z "${ar18_exit_map+x}" ]; then
  declare -A -g ar18_exit_map
fi
ar18_exit_map["${script_path}"]=0
# Get old shell option values to restore later
shopt -s inherit_errexit
IFS=$'\n' shell_options=($(shopt -op))
# Set shell options for this script
set -o pipefail
set -eu
#################################SCRIPT_START##################################

#. /opt/ar18/helper_functions/helper_functions.sh

. "/opt/ar18/mac_change/config/{{ar18_deployment_target}}" "/opt/ar18/mac_change/config/ip_to_mac"

#echo "${ar18_sudo_password}" | sudo -Sk systemctl stop NetworkManager

for idx in "${!ar18_interfaces[@]}"; do
  echo "key  : $idx"
  echo "value: ${ar18_interfaces[$idx]}"
  ar18_ip_address="${ar18_interfaces[$idx]}"
  ar18_mac_address="${ar18_ip_to_mac["${ar18_ip_address}"]}"
  echo "${ar18_sudo_password}" | sudo -Sk ifconfig "${idx}" down
  echo "${ar18_sudo_password}" | sudo -Sk macchanger --mac="${ar18_mac_address}" "${idx}"
  echo "${ar18_sudo_password}" | sudo -Sk ifconfig "${idx}" up
done

#echo "${ar18_sudo_password}" | sudo -Sk systemctl start NetworkManager

##################################SCRIPT_END###################################
# Restore old shell values
set +x
for option in "${shell_options[@]}"; do
  eval "${option}"
done
# Restore LD_PRELOAD
LD_PRELOAD="${LD_PRELOAD_old}"
# Return or exit depending on whether the script was sourced or not
if [ "${ar18_sourced_map["${script_path}"]}" = "1" ]; then
  return "${ar18_exit_map["${script_path}"]}"
else
  exit "${ar18_exit_map["${script_path}"]}"
fi
