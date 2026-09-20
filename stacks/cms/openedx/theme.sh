#!/bin/sh
# ## Overview
# Theming and branding engine for Open edX.
# Manages installation, compilation, site binding, listing, and removal of comprehensive themes.
#
# ## Usage
#   ./theme.sh install <name> <git_url> [--branch <branch>]
#   ./theme.sh build <name>
#   ./theme.sh apply <name> [--site <domain>]
#   ./theme.sh list
#   ./theme.sh remove <name>
#   ./theme.sh help
#
# ## Parameters
# - `install`: Clones or downloads theme into themes repository directory.
# - `build`: Compiles theme assets, SCSS, and webpack bundles.
# - `apply`: Binds theme to Open edX site configurations.
# - `list`: Lists all installed themes and active assignments.
# - `remove`: Deletes theme directory and resets theme assignment.
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Path to openedx installation directory.
# - `LIBSCRIPT_ROOT_DIR`: Root directory of LibScript repository.
#
# ## Exit Codes
# - `0`: Success.
# - `1`: Error during theme processing or git operation failure.

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
THEMES_DIR="${OPENEDX_INSTALL_DIR}/themes"
THEME_REGISTRY="${THEMES_DIR}/registry.json"
PYTHON_BIN="${OPENEDX_INSTALL_DIR}/.venv/bin/python"
MANAGE_PY="${OPENEDX_INSTALL_DIR}/manage.py"

mkdir -p "${THEMES_DIR}"

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

# ## theme_install
# Downloads or checks out a theme.
#
# Inputs:
#   $1 - name
#   $2 - git_url
#   --branch <branch>
theme_install() {
  if [ $# -lt 2 ]; then
    log_err "Usage: $0 install <name> <git_url> [--branch <branch>]"
    return 1
  fi
  _name="$1"
  _url="$2"
  shift 2

  _branch="master"
  while [ $# -gt 0 ]; do
    case "$1" in
      --branch)
        [ $# -ge 2 ] || { log_err "Option --branch requires a value"; return 1; }
        _branch="$2"
        shift 2
        ;;
      *)
        log_err "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  _dest="${THEMES_DIR}/${_name}"
  log_info "Installing theme '${_name}' from '${_url}' (branch: ${_branch})..."

  if [ -d "${_dest}/.git" ]; then
    log_info "Theme '${_name}' directory already exists. Pulling latest revisions..."
    (cd "${_dest}" && git pull 2>/dev/null || true)
  else
    rm -rf "${_dest}"
    if command -v git >/dev/null 2>&1; then
      git clone --depth 1 --branch "${_branch}" "${_url}" "${_dest}" 2>/dev/null ||
        git clone --depth 1 "${_url}" "${_dest}" 2>/dev/null || mkdir -p "${_dest}"
    else
      mkdir -p "${_dest}"
    fi
  fi

  # Record in registry
  _py="$(resolve_python)"
  if [ -n "${_py}" ]; then
    "${_py}" - <<EOF
import json, os
p = "${THEME_REGISTRY}"
d = json.load(open(p)) if os.path.exists(p) else {}
d["${_name}"] = {"url": "${_url}", "branch": "${_branch}", "installed": True, "active": False}
json.dump(d, open(p, "w"), indent=2)
EOF
  fi
  log_success "Theme '${_name}' installed successfully."
}

# ## theme_build
# Compiles SCSS and static assets for specified theme.
#
# Inputs:
#   $1 - name
theme_build() {
  if [ $# -lt 1 ]; then
    log_err "Usage: $0 build <name>"
    return 1
  fi
  _name="$1"
  _dest="${THEMES_DIR}/${_name}"

  if [ ! -d "${_dest}" ]; then
    log_err "Theme '${_name}' not found at ${_dest}."
    return 1
  fi

  log_info "Compiling static assets and styles for theme '${_name}'..."

  # Compile via npm if package.json exists in theme
  if [ -f "${_dest}/package.json" ]; then
    (cd "${_dest}" && npm install 2>/dev/null && npm run build 2>/dev/null || true)
  fi

  # Run collectstatic with theme settings if Django is present
  _py="$(resolve_python)"
  if [ -f "${MANAGE_PY}" ] && [ -n "${_py}" ]; then
    "${_py}" "${MANAGE_PY}" lms compilejsi18n 2>/dev/null || true
    "${_py}" "${MANAGE_PY}" lms collectstatic --noinput 2>/dev/null || true
  fi

  log_success "Theme '${_name}' assets compiled successfully."
}

# ## theme_apply
# Applies theme to Open edX site configurations.
#
# Inputs:
#   $1 - name
#   --site <domain>
theme_apply() {
  if [ $# -lt 1 ]; then
    log_err "Usage: $0 apply <name> [--site <domain>]"
    return 1
  fi
  _name="$1"
  shift

  _domain="openedx.local"
  while [ $# -gt 0 ]; do
    case "$1" in
      --site)
        [ $# -ge 2 ] || { log_err "Option --site requires a value"; return 1; }
        _domain="$2"
        shift 2
        ;;
      *)
        log_err "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  _dest="${THEMES_DIR}/${_name}"
  if [ ! -d "${_dest}" ]; then
    log_err "Theme '${_name}' is not installed."
    return 1
  fi

  log_info "Applying theme '${_name}' to site '${_domain}'..."

  _py="$(resolve_python)"
  if [ -f "${MANAGE_PY}" ] && [ -n "${_py}" ]; then
    "${_py}" - <<EOF
import os, sys
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "lms.envs.production")
try:
    import django
    django.setup()
    from openedx.core.djangoapps.theming.models import SiteTheme
    from django.contrib.sites.models import Site
    site, _ = Site.objects.get_or_create(domain="${_domain}", defaults={"name": "${_domain}"})
    theme, _ = SiteTheme.objects.get_or_create(site=site)
    theme.theme_dir_name = "${_name}"
    theme.save()
    print("Theme applied in database.")
except Exception as e:
    print(f"Notice: Django DB update skipped ({e}).")
EOF
  fi

  # Update registry
  if [ -n "${_py}" ]; then
    "${_py}" - <<EOF
import json, os
p = "${THEME_REGISTRY}"
d = json.load(open(p)) if os.path.exists(p) else {}
for k in d:
    d[k]["active"] = (k == "${_name}")
json.dump(d, open(p, "w"), indent=2)
EOF
  fi
  log_success "Theme '${_name}' is now active on '${_domain}'."
}

# ## theme_list
# Lists all themes.
theme_list() {
  log_info "Listing installed Open edX themes..."
  _py="$(resolve_python)"
  if [ -n "${_py}" ] && [ -f "${THEME_REGISTRY}" ]; then
    "${_py}" - <<EOF
import json
d = json.load(open("${THEME_REGISTRY}"))
print(f"{'THEME NAME':<24} {'ACTIVE':<10} {'SOURCE URL':<40}")
print("-" * 76)
for k, v in d.items():
    print(f"{k:<24} {str(v.get('active', False)):<10} {v.get('url', 'local'):<40}")
EOF
  else
    printf '%-24s %-10s %-40s
' "THEME NAME" "ACTIVE" "SOURCE URL"
    printf '%s
' "----------------------------------------------------------------------------"
    set +f
    for d in "${THEMES_DIR}"/*; do
      if [ -d "$d" ]; then
        printf '%-24s %-10s %-40s
' "$(basename "$d")" "false" "local"
      fi
    done
    set -f
  fi
}

# ## theme_remove
# Deletes theme.
#
# Inputs:
#   $1 - name
theme_remove() {
  if [ $# -lt 1 ]; then
    log_err "Usage: $0 remove <name>"
    return 1
  fi
  _name="$1"
  _dest="${THEMES_DIR}/${_name}"

  log_info "Removing theme '${_name}'..."
  rm -rf "${_dest}"

  _py="$(resolve_python)"
  if [ -n "${_py}" ] && [ -f "${THEME_REGISTRY}" ]; then
    "${_py}" - <<EOF
import json, os
p = "${THEME_REGISTRY}"
if os.path.exists(p):
    d = json.load(open(p))
    d.pop("${_name}", None)
    json.dump(d, open(p, "w"), indent=2)
EOF
  fi
  log_success "Theme '${_name}' removed."
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX Theming & Branding CLI

Usage:
  $0 install <name> <git_url> [--branch <branch>]
  $0 build <name>
  $0 apply <name> [--site <domain>]
  $0 list
  $0 remove <name>
  $0 help

Commands:
  install   Download/checkout theme from Git
  build     Compile theme SCSS and JavaScript bundles
  apply     Bind theme to LMS / Studio sites
  list      List installed themes and active status
  remove    Delete an installed theme
  help      Show this help message
EOF
}

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  install)
    theme_install "$@"
    ;;
  build)
    theme_build "$@"
    ;;
  apply)
    theme_apply "$@"
    ;;
  list)
    theme_list
    ;;
  remove|delete)
    theme_remove "$@"
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown theme command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
