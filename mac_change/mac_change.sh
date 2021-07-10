#!/usr/bin/env bash
# ar18

# Prepare script environment
{
  # Script template version 2021-07-10_14:04:55
  # Get old shell option values to restore later
  if [ ! -v ar18_old_shopt_map ]; then
    declare -A -g ar18_old_shopt_map
  fi
  shopt -s inherit_errexit
  ar18_old_shopt_map["$(realpath "${BASH_SOURCE[0]}")"]="$(shopt -op)"
  set +x
  # Set shell options for this script
  set -o pipefail
  set -e
  # Make sure some modification to LD_PRELOAD will not alter the result or outcome in any way
  if [ ! -v ar18_old_ld_preload_map ]; then
    declare -A -g ar18_old_ld_preload_map
  fi
  if [ ! -v LD_PRELOAD ]; then
    LD_PRELOAD=""
  fi
  ar18_old_ld_preload_map["$(realpath "${BASH_SOURCE[0]}")"]="${LD_PRELOAD}"
  LD_PRELOAD=""
  # Save old script_dir variable
  if [ ! -v ar18_old_script_dir_map ]; then
    declare -A -g ar18_old_script_dir_map
  fi
  set +u
  if [ ! -v script_dir ]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  fi
  ar18_old_script_dir_map["$(realpath "${BASH_SOURCE[0]}")"]="${script_dir}"
  set -u
  # Save old script_path variable
  if [ ! -v ar18_old_script_path_map ]; then
    declare -A -g ar18_old_script_path_map
  fi
  set +u
  if [ ! -v script_path ]; then
    script_path="${script_dir}/$(basename "${0}")"
  fi
  ar18_old_script_path_map["$(realpath "${BASH_SOURCE[0]}")"]="${script_path}"
  set -u
  # Determine the full path of the directory this script is in
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
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
  if [ ! -v ar18_exit_map ]; then
    declare -A -g ar18_exit_map
  fi
  ar18_exit_map["${script_path}"]=0
  # Save PWD
  if [ ! -v ar18_pwd_map ]; then
    declare -A -g ar18_pwd_map
  fi
  ar18_pwd_map["$(realpath "${BASH_SOURCE[0]}")"]="${PWD}"
  if [ ! -v ar18_parent_process ]; then
    export ar18_parent_process="$$"
  fi
  # Get import module
  if [ ! -v ar18.script.import ]; then
    mkdir -p "/tmp/${ar18_parent_process}"
    cd "/tmp/${ar18_parent_process}"
    curl -O https://raw.githubusercontent.com/ar18-linux/ar18_lib_bash/master/ar18_lib_bash/script/import.sh > /dev/null 2>&1 && . "/tmp/${ar18_parent_process}/import.sh"
    cd "${ar18_pwd_map["${script_path}"]}"
  fi
}
#################################SCRIPT_START##################################

ar18.script.import ar18.script.obtain_sudo_password
ar18.script.import ar18.script.read_target
ar18.script.import ar18.script.execute_with_sudo

ar18.script.obtain_sudo_password

set +u
export ar18_deployment_target="$(ar18.script.read_target "${1}")"
set -u

source_or_execute_config "source" "mac_change" "${ar18_deployment_target}"
source_or_execute_config "source" "mac_change" "ip_to_mac"

ar18.script.execute_with_sudo systemctl stop NetworkManager

for idx in "${!ar18_interfaces[@]}"; do
  echo "key  : $idx"
  echo "value: ${ar18_interfaces[$idx]}"
  ar18_ip_address="${ar18_interfaces[$idx]}"
  ar18_mac_address="${ar18_ip_to_mac["${ar18_ip_address}"]}"
  ar18.script.execute_with_sudo ifconfig "${idx}" down
  ar18.script.execute_with_sudo macchanger --mac="${ar18_mac_address}" "${idx}"
  ar18.script.execute_with_sudo ifconfig "${idx}" up
done

ar18.script.execute_with_sudo systemctl start NetworkManager

##################################SCRIPT_END###################################
set +x
function clean_up(){
  rm -rf "/tmp/${ar18_parent_process}"
}
# Restore environment
{
  exit_script_path="${script_path}"
  # Restore script_dir and script_path
  script_dir="${ar18_old_script_dir_map["$(realpath "${BASH_SOURCE[0]}")"]}"
  script_path="${ar18_old_script_path_map["$(realpath "${BASH_SOURCE[0]}")"]}"
  # Restore LD_PRELOAD
  LD_PRELOAD=ar18_old_ld_preload_map["$(realpath "${BASH_SOURCE[0]}")"]
  # Restore PWD
  cd "${ar18_pwd_map["$(realpath "${BASH_SOURCE[0]}")"]}"
  # Restore old shell values
  IFS=$'\n' shell_options=(echo ${ar18_old_shopt_map["$(realpath "${BASH_SOURCE[0]}")"]})
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
}
# Return or exit depending on whether the script was sourced or not
{
  if [ "${ar18_sourced_map["${exit_script_path}"]}" = "1" ]; then
    return "${ar18_exit_map["${exit_script_path}"]}"
  else
    if [ "${ar18_parent_process}" = "$$" ]; then
      clean_up
    fi
    exit "${ar18_exit_map["${exit_script_path}"]}"
  fi
}

trap clean_up SIGINT
