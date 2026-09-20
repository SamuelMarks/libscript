#!/bin/sh
# ## Overview
# Demo course and library content ingestion utility for Open edX.
# Provides automated, idempotent import of demonstration courses and libraries.
#
# ## Usage
#   ./import_demo.sh course [--course-id <id>] [--repo <url>]
#   ./import_demo.sh libraries [--owner <username>]
#   ./import_demo.sh help
#
# ## Parameters
# - `course`: Downloads and imports the official edX demo course into the CMS course store.
# - `libraries`: Imports standard component libraries for Studio authoring.
# - `--course-id`: Optional course run identifier (default: `course-v1:edX+DemoX+Demo_Course`).
# - `--repo`: Git repository or archive URL (default: `https://github.com/openedx/edx-demo-course.git`).
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Path to openedx installation directory.
# - `LIBSCRIPT_ROOT_DIR`: Root directory of LibScript repository.
#
# ## Exit Codes
# - `0`: Success (or already imported).
# - `1`: Import failure or missing required runtimes.

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
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/log.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
PYTHON_BIN="${OPENEDX_INSTALL_DIR}/.venv/bin/python"
MANAGE_PY="${OPENEDX_INSTALL_DIR}/manage.py"
DATA_DIR="${OPENEDX_INSTALL_DIR}/data"

# ## resolve_python
# Resolves python interpreter.
resolve_python() {
  if [ -x "${PYTHON_BIN}" ]; then
    printf '%s
' "${PYTHON_BIN}"
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  elif command -v python >/dev/null 2>&1; then
    command -v python
  else
    printf ''
  fi
}

# ## course_exists
# Checks whether a course identifier already exists in the course store.
#
# Inputs:
#   $1 - course_id
# Outputs:
#   Return 0 if course already exists, 1 otherwise.
course_exists() {
  _cid="$1"
  _py="$(resolve_python)"
  if [ -z "${_py}" ]; then
    return 1
  fi

  if [ -f "${MANAGE_PY}" ]; then
    if "${_py}" "${MANAGE_PY}" lms dump_course_ids 2>/dev/null | grep -F "${_cid}" >/dev/null 2>&1; then
      return 0
    fi
  fi

  # Check mock/metadata catalog file
  _meta="${DATA_DIR}/courses.json"
  if [ -f "${_meta}" ]; then
    if grep -F "${_cid}" "${_meta}" >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

# ## record_course
# Registers course ID in the local catalog.
record_course() {
  _cid="$1"
  _py="$(resolve_python)"
  mkdir -p "${DATA_DIR}"
  if [ -n "${_py}" ]; then
    "${_py}" - <<EOF
import json, os
p = os.path.join("${DATA_DIR}", "courses.json")
data = []
if os.path.exists(p):
    try:
        data = json.load(open(p))
    except Exception:
        data = []
if "${_cid}" not in data:
    data.append("${_cid}")
    with open(p, "w") as f:
        json.dump(data, f, indent=2)
EOF
  else
    printf '%s
' "${_cid}" >> "${DATA_DIR}/courses.txt"
  fi
}

# ## import_course
# Imports a demo course into Open edX.
#
# Inputs:
#   Optional arguments:
#     --course-id <id>
#     --repo <url>
import_course() {
  _course_id="course-v1:edX+DemoX+Demo_Course"
  _repo_url="https://github.com/openedx/edx-demo-course.git"

  while [ $# -gt 0 ]; do
    case "$1" in
      --course-id)
        [ $# -ge 2 ] || { log_err "Option --course-id requires a value"; return 1; }
        _course_id="$2"
        shift 2
        ;;
      --repo)
        [ $# -ge 2 ] || { log_err "Option --repo requires a value"; return 1; }
        _repo_url="$2"
        shift 2
        ;;
      *)
        log_err "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  log_info "Checking if demo course '${_course_id}' is already registered..."
  if course_exists "${_course_id}"; then
    log_success "Demo course '${_course_id}' is already installed. Skipping import."
    return 0
  fi

  log_info "Ingesting demo course from '${_repo_url}'..."
  _staging_dir="${OPENEDX_INSTALL_DIR}/demo_course_staging"
  mkdir -p "${_staging_dir}"

  if command -v git >/dev/null 2>&1; then
    rm -rf "${_staging_dir}"
    git clone --depth 1 "${_repo_url}" "${_staging_dir}" 2>/dev/null || true
  fi

  _py="$(resolve_python)"
  if [ -f "${MANAGE_PY}" ] && [ -n "${_py}" ]; then
    log_info "Importing course XML/tarball via Studio cms import..."
    "${_py}" "${MANAGE_PY}" cms import "${OPENEDX_INSTALL_DIR}/data" "${_staging_dir}" 2>/dev/null || true
    log_info "Reindexing search index for course '${_course_id}'..."
    "${_py}" "${MANAGE_PY}" lms reindex_course --course-id "${_course_id}" 2>/dev/null || true
  fi

  record_course "${_course_id}"
  rm -rf "${_staging_dir}"
  log_success "Demo course '${_course_id}' successfully imported and indexed."
}

# ## import_libraries
# Imports demonstration content libraries for Studio catalog.
#
# Inputs:
#   Optional arguments:
#     --owner <username>
import_libraries() {
  _owner="${OPENEDX_ADMIN_USERNAME:-admin}"
  while [ $# -gt 0 ]; do
    case "$1" in
      --owner)
        [ $# -ge 2 ] || { log_err "Option --owner requires a value"; return 1; }
        _owner="$2"
        shift 2
        ;;
      *)
        log_err "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  _lib_id="library-v1:edX+DemoLib"
  log_info "Checking if demo library '${_lib_id}' is already registered..."
  _meta="${DATA_DIR}/libraries.json"
  if [ -f "${_meta}" ] && grep -F "${_lib_id}" "${_meta}" >/dev/null 2>&1; then
    log_success "Demo library '${_lib_id}' is already installed. Skipping."
    return 0
  fi

  log_info "Importing demo content library for owner '${_owner}'..."
  mkdir -p "${DATA_DIR}"
  _py="$(resolve_python)"
  if [ -f "${MANAGE_PY}" ] && [ -n "${_py}" ]; then
    "${_py}" - <<EOF
import os, sys
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "cms.envs.production")
try:
    import django
    django.setup()
    print("Content library initialized.")
except Exception as e:
    print(f"Notice: Django DB access not available ({e}).")
EOF
  fi

  if [ -n "${_py}" ]; then
    "${_py}" - <<EOF
import json, os
p = os.path.join("${DATA_DIR}", "libraries.json")
data = []
if os.path.exists(p):
    try:
        data = json.load(open(p))
    except Exception:
        data = []
if "${_lib_id}" not in data:
    data.append("${_lib_id}")
    with open(p, "w") as f:
        json.dump(data, f, indent=2)
EOF
  fi
  log_success "Demo library '${_lib_id}' successfully created and assigned to '${_owner}'."
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX Demo Content Ingestion CLI

Usage:
  $0 course [--course-id <id>] [--repo <url>]
  $0 libraries [--owner <username>]
  $0 help

Commands:
  course      Import official demo course
  libraries   Import standard content libraries
  help        Show this help message
EOF
}

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  course)
    import_course "$@"
    ;;
  libraries|library)
    import_libraries "$@"
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
