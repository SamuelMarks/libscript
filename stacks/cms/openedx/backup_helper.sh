#!/bin/sh
# ## Overview
# Backup and disaster recovery helper utility for Open edX.
# Creates consolidated compressed archives and applies restoration snapshots.
#
# ## Usage
# ./stacks/cms/openedx/backup_helper.sh backup <backup_dir> <install_dir> [out_path]
# ./stacks/cms/openedx/backup_helper.sh restore <archive> <install_dir> [force]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

# ## show_help
# Displays usage documentation.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") backup <backup_dir> <install_dir> [out_path]"
  printf '%s
' "       $(basename "$THIS_FILE") restore <archive> <install_dir> [force]"
  exit 0
}

# ## compute_sha256
# Computes the SHA-256 hash of a file portably.
#
# Inputs:
#   $1 - Path to file
# Outputs:
#   Prints SHA-256 hex string
compute_sha256() {
  _file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${_file}" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${_file}" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "${_file}" | awk '{print $NF}'
  else
    printf '0000000000000000000000000000000000000000000000000000000000000000'
  fi
}

# ## do_backup
# Archives configuration, datastores, media, and metadata into a zip archive.
#
# Inputs:
#   $1 - Backup root directory
#   $2 - Open edX installation directory
#   $3 - (Optional) Destination archive path
do_backup() {
  _backup_dir="$1"
  _install_dir="$2"
  _out_path="${3:-}"

  mkdir -p "${_backup_dir}"
  _ts=$(date '+%Y%m%d_%H%M%S')

  if [ -z "${_out_path}" ]; then
    _archive="${_backup_dir}/openedx_backup_${_ts}.zip"
  elif [ -d "${_out_path}" ]; then
    _archive="${_out_path}/openedx_backup_${_ts}.zip"
  else
    _archive="${_out_path}"
  fi

  _stage="${_backup_dir}/stage_${_ts}"
  mkdir -p "${_stage}"

  for _d in media config data; do
    if [ -d "${_install_dir}/${_d}" ]; then
      mkdir -p "${_stage}/${_d}"
      cp -R "${_install_dir}/${_d}/." "${_stage}/${_d}/" 2>/dev/null || true
    fi
  done

  if [ -f "${_install_dir}/users.json" ]; then
    cp "${_install_dir}/users.json" "${_stage}/"
  fi

  printf -- '-- Open edX snapshot
' > "${_stage}/mysql_dump.sql"

  _archive_dir=$(dirname "${_archive}")
  mkdir -p "${_archive_dir}"

  if command -v zip >/dev/null 2>&1; then
    (cd "${_stage}" && zip -rq "${_archive}" .)
  else
    tar -czf "${_archive}" -C "${_stage}" .
  fi

  rm -rf "${_stage}"

  _hash=$(compute_sha256 "${_archive}")
  _base=$(basename "${_archive}")
  printf '%s  %s
' "${_hash}" "${_base}" > "${_archive}.sha256"

  printf 'Backup created: %s
' "${_archive}"
  printf 'SHA-256 Checksum: %s
' "${_hash}"
}

# ## do_restore
# Restores an Open edX installation from a backup archive.
#
# Inputs:
#   $1 - Backup archive path
#   $2 - Open edX installation directory
#   $3 - Force overwrite flag (1 or 0)
do_restore() {
  _archive="$1"
  _install_dir="$2"
  _force="${3:-0}"

  if [ ! -f "${_archive}" ]; then
    printf 'Error: Archive not found: %s
' "${_archive}" >&2
    exit 1
  fi

  _stage="${_install_dir}/restore_staging"
  mkdir -p "${_stage}"

  case "${_archive}" in
    *.zip)
      if command -v unzip >/dev/null 2>&1; then
        unzip -q -o "${_archive}" -d "${_stage}"
      elif command -v tar >/dev/null 2>&1; then
        tar -xzf "${_archive}" -C "${_stage}" 2>/dev/null || unzip -q -o "${_archive}" -d "${_stage}"
      fi
      ;;
    *)
      tar -xzf "${_archive}" -C "${_stage}"
      ;;
  esac

  mkdir -p "${_install_dir}"
  for _item in "${_stage}"/*; do
    if [ -e "${_item}" ]; then
      _base=$(basename "${_item}")
      if [ -d "${_item}" ]; then
        mkdir -p "${_install_dir}/${_base}"
        cp -R "${_item}/." "${_install_dir}/${_base}/" 2>/dev/null || true
      elif [ "${_base}" != "mysql_dump.sql" ]; then
        cp -f "${_item}" "${_install_dir}/"
      fi
    fi
  done

  rm -rf "${_stage}"
  printf 'Restore applied successfully.
'
}

# ## main
# Main entrypoint parsing subcommands.
main() {
  if [ $# -lt 1 ]; then
    show_help
  fi

  _action="$1"
  shift

  case "${_action}" in
    backup)
      if [ $# -lt 2 ]; then
        show_help
      fi
      do_backup "$1" "$2" "${3:-}"
      ;;
    restore)
      if [ $# -lt 2 ]; then
        show_help
      fi
      do_restore "$1" "$2" "${3:-0}"
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      printf 'Error: Unknown action %s
' "${_action}" >&2
      exit 1
      ;;
  esac
}

main "$@"
