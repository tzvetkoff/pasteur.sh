#!/bin/bash

set -e

#
# Join array
#

join_arr() {
  local IFS="${1}"
  shift
  echo "${@}"
}

#
# Help
#

do_help() {
  case "${1}" in
    config)
      echo 'Usage:'
      echo "  ${0} config [options]"
      echo
      echo 'Options'
      echo '  -s SERVER, --server=SERVER            Server to submit pastes to (e.g. https://127.0.0.1:1337)'
      ;;
    browse)
      echo 'Usage:'
      echo "  ${0} browse [options] [filetype]"
      echo
      echo 'Options:'
      echo '  -t FILETYPE, --filetype=FILETYPE      Browse pastes by filetype'
      echo '  -p PAGE, --page=PAGE                  Page number'
      echo '  -P PER, --per=PER                     Page size'
      ;;
    paste)
      echo 'Usage:'
      echo "  ${0} paste [options] [file]"
      echo
      echo 'Options:'
      echo '  -f FILENAME, --filename=FILENAME              Paste filename'
      echo '  -t FILETYPE, --filetype=FILETYPE              Paste filetype'
      echo '  -i INDENT_STYLE, --indent-style=INDENT_STYLE  Set indent style'
      echo '  -I INDENT_SIZE, --indent-size=INDENT_SIZE     Set indent size'
      echo '  -p, --private                         Set visibility to private'
      ;;
    *)
      echo 'Usage:'
      echo "  ${0} [options] [command] [args]"
      echo
      echo 'Commands:'
      echo '  config [options]                      Configure the script'
      echo '  browse [options] [filetype]           Browse pastes (alias: ls)'
      echo '  paste [options] [file]                Paste code'
      ;;
  esac

  exit "${2}"
}

#
# Config
#

do_config() {
  local parse='true'
  local args=()

  while [[ -n "${1}" ]]; do
    if $parse; then
      case "${1}" in
        -h|--help) do_help 'config' 0;;

        -s|--server) SERVER="${2}"; shift;;
        --server=*)  SERVER="${1:9}";;
        -s*)         SERVER="${1:2}";;

        --) parse='false';;
        -*) echo "${0} config: invalid option: ${1}" >&2; echo >&2; do_help 'config' 1 >&2;;
        *)  args+=("${1}");;
      esac
    else
      args+=("${1}")
    fi

    shift
  done

  mkdir -p "${HOME}/.config/pasteur.sh"
  echo "SERVER=${SERVER}" >"${HOME}/.config/pasteur.sh/config"
}

#
# Browse
#

do_browse() {
  local parse='true'
  local args=()

  local query=()
  local query_string=

  while [[ -n "${1}" ]]; do
    if $parse; then
      case "${1}" in
        -h|--help) do_help 'browse' 0;;

        -s|--server) SERVER="${2}"; shift;;
        --server=*)  SERVER="${1:9}";;
        -s*)         SERVER="${1:2}";;

        -t|--filetype) query+=("filetype=${2}"); shift;;
        --filetype=*)  query+=("filetype=${1:11}");;
        -t*)           query+=("filetype=${1:2}");;

        -p|--page) query+=("page=${2}"); shift;;
        --page=*)  query+=("page=${1:7}");;
        -p*)       query+=("page=${1:2}");;

        -P|--per) query+=("per=${2}"); shift;;
        --per=*)  query+=("per=${1:11}");;
        -P*)      query+=("per=${1:2}");;

        --) parse='false';;
        -*) echo "${0} browse: invalid option: ${1}" >&2; echo >&2; do_help 'config' 1 >&2;;
        *)  args+=("${1}");;
      esac
    else
      args+=("${1}")
    fi

    shift
  done

  if [[ -n "${args[0]}" ]]; then
    query+=("filetype=${args[0]}")
  fi

  if [[ "${#query[@]}" -gt 0 ]]; then
    query_string="?$(join_arr , "${query[@]}")"
  else
    query_string=''
  fi

  curl -sSL "${SERVER}/browse${query_string}"
}

#
# Paste
#

do_paste() {
  local parse='true'
  local args=()

  local curl_args=()

  while [[ -n "${1}" ]]; do
    if $parse; then
      case "${1}" in
        -h|--help) do_help 'paste' 0;;

        -s|--server) SERVER="${2}"; shift;;
        --server=*)  SERVER="${1:9}";;
        -s*)         SERVER="${1:2}";;

        -f|--filename) curl_args+=('--form' "filename=${2}"); shift;;
        --filename=*)  curl_args+=('--form' "filename=${1:11}");;
        -f*)           curl_args+=('--form' "filename=${1:2}");;

        -t|--filetype) curl_args+=('--form' "filetype=${2}"); shift;;
        --filetype=*)  curl_args+=('--form' "filetype=${1:11}");;
        -t*)           curl_args+=('--form' "filetype=${1:2}");;

        -i|--indent-style) curl_args+=('--form' "indent-style=${2}"); shift;;
        --indent-style=*)  curl_args+=('--form' "indent-style=${1:15}");;
        -i*)               curl_args+=('--form' "indent-style=${1:2}");;

        -I|--indent-size) curl_args+=('--form' "indent-size=${2}"); shift;;
        --indent-size=*)  curl_args+=('--form' "indent-size=${1:14}");;
        -I*)              curl_args+=('--form' "indent-size=${1:2}");;

        -p|--private) curl_args+=('--form' 'private=1');;

        --) parse='false';;
        -*) echo "${0} paste: invalid option: ${1}" >&2; echo >&2; do_help 'config' 1 >&2;;
        *)  args+=("${1}");;
      esac
    else
      args+=("${1}")
    fi

    shift
  done

  if [[ -n "${args[0]}" ]]; then
    curl_args+=('--form' "f=@${args[0]}")
  else
    curl_args+=('--form' "content=$(</dev/stdin)")
  fi

  curl -sSLX 'POST' "${curl_args[@]}" "${SERVER}"
}

#
# Global variables
#

SERVER="${SERVER:-127.0.0.1:1337}"

#
# Load config
#

# shellcheck disable=SC1091
[[ -f "${HOME}/.config/pasteur.sh/config" ]] && source "${HOME}/.config/pasteur.sh/config"

#
# Go
#

case "${1}" in
  config)    do_config "${@:2}";;
  browse|ls) do_browse "${@:2}";;
  paste)     do_paste "${@:2}";;
  -h|--help) do_help 'default' 0;;
  *)         do_paste "${@}";;
esac
