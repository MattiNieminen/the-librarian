#!/usr/bin/env bash

msg() {
  echo >&2 -e "${1}"
}

die() {
  local error_message="${1}"
  local line_number="${2}"

  if [ -z "${line_number}" ]; then
    msg "${RED}ERROR: ${error_message}."
  else
    msg "${RED}ERROR: ${error_message} at line ${line_number}."
  fi

  exit 1
}

set_error_handling() {
  set -E
  trap 'die "$(echo ${BASH_COMMAND})" "${LINENO}"' ERR
}

set_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR}" ]] && [[ "${TERM}" != "dumb" ]]; then
    NOFORMAT='\033[0m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    ORANGE='\033[0;33m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    YELLOW='\033[1;33m'
  else
    NOFORMAT=''
    RED=''
    GREEN=''
    BLUE=''
    ORANGE=''
    PURPLE=''
    CYAN=''
    YELLOW=''
  fi
}

set_constants() {
  APP_NAME="${0##*/}"
  APP_DIR="$(dirname $(readlink -f ${0}))"
}

help() {
  cat <<EOF
Usage: ${APP_NAME} [-h] source_path target_path

Finds regular files and moves them to date-based directories under target path.
Uses 'last modified' timestamp and creates directories with pattern YYYY/MM/dd.

Available options:

-h, --help      Print this help and exit
EOF
}

parse_args() {
  for arg in "${@}"; do
    case "${arg}" in
    -h|--help)
      help
      exit 0
      ;;
    -*)
      die "unknown option: ${arg}"
      ;;
    *)
      if [ -z "${source_path}" ]; then
        source_path="${arg}"
      elif [ -z "${target_path}" ]; then
        target_path="${arg}"
      else
        die "too many arguments"
      fi
      ;;
    esac
  done

  if [ -z "${source_path}" ]; then
    die "source path is missing"
  fi

  if [ -z "${target_path}" ]; then
    die "target path is missing"
  fi

  if [ ! -d "${source_path}" ]; then
    die "source path is not a valid directory"
  fi

  if [ ! -d "${target_path}" ]; then
    die "target path is not a valid directory"
  fi
}

organize_files() {
  find "${source_path}" -type f -not -path "${target_path}/*" | while read -r file; do
    if [ "$(uname)" = "Darwin" ]; then
      last_modified=$(date -r "$(stat -f %m ${file})" +%Y-%m-%d)
    else
      last_modified=$(date -d "@$(stat -c %Y ${file})" +%Y-%m-%d)
    fi

    year=$(echo "${last_modified}" | cut -d '-' -f1)
    month=$(echo "${last_modified}" | cut -d '-' -f2)
    day=$(echo "${last_modified}" | cut -d '-' -f3)

    target_path_for_file="${target_path}/${year}/${month}/${day}/"

    mkdir -p "${target_path_for_file}"

    mv "${file}" "${target_path_for_file}"

    msg "Moved ${ORANGE}${file}${NOFORMAT} to ${CYAN}${target_path_for_file}${NOFORMAT}"
  done
}

set_error_handling
set_colors
set_constants
parse_args "${@}"
organize_files
