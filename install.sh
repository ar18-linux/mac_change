#!/usr/bin/env bash
# ar18

# Prepare script environment
{
  # Script template version 2021-07-11_15:24:34
  script_dir_temp="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  script_path_temp="${script_dir_temp}/$(basename "${BASH_SOURCE[0]}")"
  # Get old shell option values to restore later
  if [ ! -v ar18_old_shopt_map ]; then
    declare -A -g ar18_old_shopt_map
  fi
  shopt -s inherit_errexit
  ar18_old_shopt_map["${script_path_temp}"]="$(shopt -op)"
  set +x
  # Set shell options for this script
  set -e
  set -E
  set -o pipefail
  set -o functrace
}

function restore_env(){
  echo restore_env
  # Restore PWD
  cd "${ar18_pwd_map["${script_path}"]}"
  exit_script_path="${script_path}"
  # Restore ar18_on_sourced_return
  eval "${ar18_sourced_return_map["${exit_script_path}"]}"
  # Restore script_dir and script_path
  script_dir="${ar18_old_script_dir_map["${exit_script_path}"]}"
  script_path="${ar18_old_script_path_map["${exit_script_path}"]}"
  # Restore LD_PRELOAD
  LD_PRELOAD="${ar18_old_ld_preload_map["${exit_script_path}"]}"
  # Restore old shell values
  IFS=$'\n' shell_options=(echo ${ar18_old_shopt_map["${exit_script_path}"]})
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
}

function ar18_return_or_exit(){
  set +x
  local path
  path="${1}"
  local ret
  set +u
  ret="${2}"
  set -u
  if [ "${ret}" = "" ]; then
    ret="${ar18_exit_map["${path}"]}"
  else
    ret="${ar18_exit_map["${path}"]}"
  fi
  if [ "${ar18_sourced_map["${path}"]}" = "1" ]; then
    export ar18_exit="return ${ret}"
  else
    export ar18_exit="exit ${ret}"
  fi
}

function clean_up() {
  echo "cleanup ${ar18_parent_process}"
  rm -rf "/tmp/${ar18_parent_process}"
}
trap clean_up SIGINT SIGHUP SIGQUIT SIGTERM EXIT

function err_report() {
  local path="${1}"
  local lineno="${2}"
  local msg="${3}"
  clean_up
  RED="\e[1m\e[31m"
  NC="\e[0m" # No Color
  printf "${RED}ERROR ${path}:${lineno}\n${msg}${NC}\n"
}
trap 'err_report "${BASH_SOURCE[0]}" ${LINENO} "${BASH_COMMAND}"' ERR

{
  # Make sure some modification to LD_PRELOAD will not alter the result or outcome in any way
  if [ ! -v ar18_old_ld_preload_map ]; then
    declare -A -g ar18_old_ld_preload_map
  fi
  if [ ! -v LD_PRELOAD ]; then
    LD_PRELOAD=""
  fi
  ar18_old_ld_preload_map["${script_path_temp}"]="${LD_PRELOAD}"
  LD_PRELOAD=""
  # Save old script_dir variable
  if [ ! -v ar18_old_script_dir_map ]; then
    declare -A -g ar18_old_script_dir_map
  fi
  set +u
  if [ ! -v script_dir ]; then
    script_dir="${script_dir_temp}"
  fi
  ar18_old_script_dir_map["${script_path_temp}"]="${script_dir}"
  set -u
  # Save old script_path variable
  if [ ! -v ar18_old_script_path_map ]; then
    declare -A -g ar18_old_script_path_map
  fi
  set +u
  if [ ! -v script_path ]; then
    script_path="${script_path_temp}"
  fi
  ar18_old_script_path_map["${script_path_temp}"]="${script_path}"
  set -u
  # Determine the full path of the directory this script is in
  script_dir="${script_dir_temp}"
  script_path="${script_path_temp}"
  #Set PS4 for easier debugging
  export PS4='\e[35m${BASH_SOURCE[0]}:${LINENO}: \e[39m'
  # Determine if this script was sourced or is the parent script
  if [ ! -v ar18_sourced_map ]; then
    declare -A -g ar18_sourced_map
  fi
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    ar18_sourced_map["${script_path_temp}"]=1
  else
    ar18_sourced_map["${script_path_temp}"]=0
  fi
  # Initialise exit code
  if [ ! -v ar18_exit_map ]; then
    declare -A -g ar18_exit_map
  fi
  ar18_exit_map["${script_path_temp}"]=0
  # Save PWD
  if [ ! -v ar18_pwd_map ]; then
    declare -A -g ar18_pwd_map
  fi
  ar18_pwd_map["${script_path_temp}"]="${PWD}"
  if [ ! -v ar18_parent_process ]; then
    unset import_map
    export ar18_parent_process="$$"
  fi
  # Local return trap for sourced scripts so that each sourced script 
  # can have their own return trap
  if [ ! -v ar18_sourced_return_map ]; then
    declare -A -g ar18_sourced_return_map
  fi
  if type ar18_on_sourced_return > /dev/null 2>&1 ; then
    ar18_on_sourced_return_temp="$(type ar18_on_sourced_return)"
    ar18_on_sourced_return_temp="$(echo "${ar18_on_sourced_return_temp}" | sed -E "s/^.+is a function\s*//")"
  else
    ar18_on_sourced_return_temp=""
  fi
  ar18_sourced_return_map["${script_path_temp}"]="${ar18_on_sourced_return_temp}"
  function local_return_trap(){
    if [ "${ar18_sourced_map["${script_path_temp}"]}" = "1" ] \
    && [ "${FUNCNAME[1]}" = "ar18_return_or_exit" ]; then
      if type ar18_on_sourced_return > /dev/null 2>&1; then
        ar18_on_sourced_return
      fi
      restore_env
    fi
  }
  trap local_return_trap RETURN
  # Get import module
  if [ ! -v ar18_script_import ]; then
    mkdir -p "/tmp/${ar18_parent_process}"
    cd "/tmp/${ar18_parent_process}"
    curl -O https://raw.githubusercontent.com/ar18-linux/ar18_lib_bash/master/ar18_lib_bash/script/import.sh >/dev/null 2>&1 && . "/tmp/${ar18_parent_process}/import.sh"
    export ar18_script_import
    cd "${ar18_pwd_map["${script_path_temp}"]}"
  fi
}
#################################SCRIPT_START##################################

ar18.script.import ar18.script.install
ar18.script.import ar18.pacman.install
ar18.script.import ar18.script.execute_with_sudo
ar18.script.import ar18.script.read_target

. "${script_dir}/vars"

ar18.script.install "${install_dir}" "${module_name}" "${script_dir}"

set +u
ar18_deployment_target="$(ar18.script.read_target "${1}")"
set -u

ar18.pacman.install macchanger

ar18_path="/etc/systemd/system/NetworkManager.service.d/"
#echo "${ar18_sudo_password}" | sudo -Sk mkdir -p "${ar18_path}"
#echo "${ar18_sudo_password}" | sudo -Sk cp -f "${script_dir}/${module_name}/NetworkManager_service_additions.conf" "${ar18_path}/pre_exec.conf"
#echo "${ar18_sudo_password}" | sudo -Sk sed -i "s~{{AR18_INSTALL_DIR}}~${install_dir}~g" "${ar18_path}/pre_exec.conf"

#echo "${ar18_sudo_password}" | sudo -Sk sed -i "s~{{ar18_deployment_target}}~${ar18_deployment_target}~g" "${install_dir}/${module_name}/mac_change_auto.sh"

ar18.script.execute_with_sudo systemctl daemon-reload

##################################SCRIPT_END###################################
set +x
ar18_return_or_exit "${script_path}" && eval "${ar18_exit}"
