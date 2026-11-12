#!/bin/sh
# ## Overview
# Interactive prompter and non-interactive JSON generator for creating new
# Tier 1 LibScript component-package-managers under `_lib/<category>/<component>/`.
#
# ## Usage
# ./libscript.sh scaffold [--interactive | --from-json=<file>] [--export-json=<file>] [--force] [--dry-run]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# ## show_scaffold_help
# Displays usage instructions and supported CLI flags for the component scaffolder.
show_scaffold_help() {
  printf '%s\n' 'LibScript Component-Package-Manager Scaffolder'
  printf '%s\n' '=============================================='
  printf '\n'
  printf '%s\n' 'Usage:'
  printf '%s\n' '  ./libscript.sh scaffold [OPTIONS]'
  printf '%s\n' '  ./libscript.sh new-component [OPTIONS]'
  printf '\n'
  printf '%s\n' 'Modes:'
  printf '%s\n' '  --interactive, -i          Run interactive prompter to configure component (default)'
  printf '%s\n' '  --from-json=<file>         Non-interactively generate component from JSON spec file'
  printf '%s\n' '  --non-interactive          Run non-interactively using CLI flags'
  printf '\n'
  printf '%s\n' 'Options:'
  printf '%s\n' '  --export-json=<file>       Export normalized component specification to a JSON file'
  printf '%s\n' '  --force, -f                Overwrite existing component files (default: idempotent skip)'
  printf '%s\n' '  --dry-run, -n              Print planned files without writing to disk'
  printf '%s\n' '  --name=<name>              Component identifier (e.g., ripgrep, fd)'
  printf '%s\n' '  --title=<title>            Human-readable title'
  printf '%s\n' '  --category=<category>      Target category under _lib/ (e.g., utilities, databases)'
  printf '%s\n' '  --description=<text>       Concise component description'
  printf '%s\n' '  --binary-name=<bin>        Executable binary name in bin/ (defaults to <name>)'
  printf '%s\n' '  --install-method=<method>  Default install method (libscript_native, system, from-source)'
  printf '%s\n' '  --version-scheme=<scheme>  Version scheme (github-release, semver, git-tags, custom-url, system-only)'
  printf '%s\n' '  --github-repo=<owner/repo> GitHub owner/repo for release tag resolution'
  printf '%s\n' '  --tag-prefix=<prefix>      Release tag prefix to strip (default: v)'
  printf '%s\n' '  --url=<url>                Default Unix download URL or template'
  printf '%s\n' '  --win-url=<url>            Default Windows download URL or template'
  printf '%s\n' '  --releases-url=<url>       Upstream releases URL for ls-remote'
  printf '%s\n' '  --os=<csv>                 Comma-separated OS whitelist (default: all)'
  printf '%s\n' '  --os-blacklist=<csv>       Comma-separated OS blacklist (default: none)'
  printf '%s\n' '  --arch=<csv>               Comma-separated Arch whitelist (default: all)'
  printf '%s\n' '  --service                  Mark component as a background service/daemon'
  printf '%s\n' '  --ports=<csv>              Comma-separated default listening ports (e.g., 8080,8443)'
  printf '%s\n' '  --hooks                    Generate lifecycle hook scripts under hooks/'
  printf '%s\n' '  --multitenant              Generate logical multi-tenant hooks under hooks/'
  printf '%s\n' '  --os-scripts=<csv>         Generate setup_<os>.{sh,cmd} stubs (e.g., debian,alpine)'
  printf '%s\n' '  --test-cmd=<cmd>           Smoke test command (default: <binary_name> --version)'
  printf '%s\n' '  --help, -h, /?, -?         Show this help message'
}

# Default state variables
SCAF_MODE='interactive'
SCAF_FROM_JSON=''
SCAF_EXPORT_JSON=''
SCAF_FORCE=0
SCAF_DRY_RUN=0

SCAF_NAME=''
SCAF_TITLE=''
SCAF_CATEGORY=''
SCAF_DESCRIPTION=''
SCAF_PROVIDES=''
SCAF_CONFLICTS=''
SCAF_BINARY_NAME=''
SCAF_INSTALL_METHOD='libscript_native'
SCAF_VERSION_SCHEME='github-release'
SCAF_DEFAULT_VERSION='latest'
SCAF_VERSION_ALIASES='latest,lts'
SCAF_REPOSITORY=''
SCAF_GITHUB_REPO=''
SCAF_TAG_PREFIX='v'
SCAF_URL_UNIX=''
SCAF_URL_WINDOWS=''
SCAF_RELEASES_URL=''
SCAF_ARCHIVE_UNIX='auto'
SCAF_ARCHIVE_WINDOWS='auto'
SCAF_STRIP_COMPONENTS='1'
SCAF_SRC_LANG='c'
SCAF_SRC_BUILD_SYS='autotools'
SCAF_SRC_FALLBACK_VER='1.0.0'
SCAF_SRC_URL_TPL=''
SCAF_OS_WHITELIST='all'
SCAF_OS_BLACKLIST=''
SCAF_ARCH_WHITELIST='all'
SCAF_ARCH_BLACKLIST=''
SCAF_OS_SCRIPTS=''
SCAF_IS_SERVICE='false'
SCAF_PORTS=''
SCAF_ENABLE_HOOKS='false'
SCAF_MULTITENANT='false'
SCAF_TEST_CMD=''
SCAF_CUSTOM_VARS_JSON='[]'
SCAF_PKG_APT=''
SCAF_PKG_APK=''
SCAF_PKG_DNF=''
SCAF_PKG_PACMAN=''
SCAF_PKG_BREW=''
SCAF_PKG_WINGET=''
SCAF_PKG_CHOCO=''
SCAF_PKG_SCOOP=''
SCAF_PKG_FREEBSD=''

# ## compute_comp_prefix
# Computes the canonical uppercase environment variable prefix for a component name.
compute_comp_prefix() {
  _raw_name="$1"
  _up=$(printf '%s' "$_raw_name" | tr '[:lower:]-.' '[:upper:]__')
  case "$_up" in
    0*) _up="ZERO${_up#0}" ;;
    1*) _up="ONE${_up#1}" ;;
    2*) _up="TWO${_up#2}" ;;
    3*) _up="THREE${_up#3}" ;;
    4*) _up="FOUR${_up#4}" ;;
    5*) _up="FIVE${_up#5}" ;;
    6*) _up="SIX${_up#6}" ;;
    7*) _up="SEVEN${_up#7}" ;;
    8*) _up="EIGHT${_up#8}" ;;
    9*) _up="NINE${_up#9}" ;;
  esac
  printf '%s\n' "$_up"
}

# ## validate_os_list
# Validates a comma-separated list of OS identifiers against the canonical LibScript OS enum.
validate_os_list() {
  _csv="$1"
  [ -z "$_csv" ] && return 0
  _oifs="$IFS"
  IFS=','
  for _os_item in $_csv; do
    _os_trim=$(printf '%s' "$_os_item" | tr -d '[:space:]')
    [ -z "$_os_trim" ] && continue
    case "$_os_trim" in
      all|linux|macos|darwin|mac|windows|freebsd|openbsd|netbsd|dragonfly|bsd|sunos|illumos|solaris|alpine|debian|ubuntu|rhel|fedora|centos|rocky|almalinux|arch|artix|manjaro|gentoo|void|suse|opensuse|solus|clearlinux|nixos)
        ;;
      *)
        IFS="$_oifs"
        printf '[ERROR] Invalid OS identifier "%s".\n' "$_os_trim" >&2
        return 1
        ;;
    esac
  done
  IFS="$_oifs"
  return 0
}

# ## validate_category_name
# Checks whether the given category is a valid _lib/<category> directory name.
validate_category_name() {
  _cat="$1"
  case "$_cat" in
    ai-serving|app-servers|audio|base-system|bootloaders|caches|cloud|cloud-providers|databases|desktops|display-managers|display-servers|freebsd|git-servers|graphics|illumos|init-systems|kernel|languages|logging|message-brokers|ml-training|networking|orchestration|package-managers|runtimes|search|security|storage|storage-layers|toolchains|utilities|virtualization|web-apps|web-servers)
      return 0
      ;;
    *)
      if [ -d "${LIBSCRIPT_ROOT_DIR}/_lib/${_cat}" ] && [ "$_cat" != "_common" ]; then
        return 0
      fi
      printf '[ERROR] Invalid category "%s".\n' "$_cat" >&2
      return 1
      ;;
  esac
}

# ## validate_component_name
# Ensures the component name is lowercase alphanumeric with hyphens or underscores.
validate_component_name() {
  _cname="$1"
  if [ -z "$_cname" ]; then
    printf '%s\n' '[ERROR] Component name cannot be empty.' >&2
    return 1
  fi
  if printf '%s\n' "$_cname" | grep -Eq '^[a-z0-9][a-z0-9_-]*$'; then
    return 0
  fi
  printf '[ERROR] Invalid component name "%s" (must match ^[a-z0-9][a-z0-9_-]*$).\n' "$_cname" >&2
  return 1
}

# ## json_extract_scalar
# Extracts a top-level string, number, or boolean field from a JSON file using jq or awk fallback.
json_extract_scalar() {
  _jfile="$1"
  _jkey="$2"
  _jdef="${3:-}"
  if command -v jq >/dev/null 2>&1; then
    _has_k=$(jq -r "if has(\"${_jkey}\") and .[\"${_jkey}\"] != null then \"yes\" else \"no\" end" "$_jfile" 2>/dev/null || true)
    if [ "$_has_k" = 'yes' ]; then
      jq -r ".[\"${_jkey}\"] | tostring" "$_jfile" 2>/dev/null || true
    else
      printf '%s\n' "$_jdef"
    fi
    return 0
  fi
  _val=$(awk -v k="\"${_jkey}\"" '
    index($0, k) > 0 {
      line = $0
      sub(/^.*:[[:space:]]*/, "", line)
      sub(/,[[:space:]]*$/, "", line)
      sub(/^[[:space:]]*"/, "", line)
      sub(/"[[:space:]]*$/, "", line)
      print line
      exit
    }
  ' "$_jfile" 2>/dev/null || true)
  if [ -n "$_val" ]; then
    printf '%s\n' "$_val"
  else
    printf '%s\n' "$_jdef"
  fi
}

# ## json_extract_csv
# Extracts an array field from a JSON file as a comma-separated string.
json_extract_csv() {
  _jfile="$1"
  _jkey="$2"
  _jdef="${3:-}"
  if command -v jq >/dev/null 2>&1; then
    _has=$(jq -r "if has(\"${_jkey}\") and (.[\"${_jkey}\"] | type) == \"array\" then \"yes\" else \"no\" end" "$_jfile" 2>/dev/null || true)
    if [ "$_has" = 'yes' ]; then
      jq -r ".[\"${_jkey}\"] | map(tostring) | join(\",\")" "$_jfile" 2>/dev/null || true
      return 0
    fi
  fi
  printf '%s\n' "$_jdef"
}

# ## parse_json_spec
# Parses a component scaffold JSON file and populates SCAF_* variables.
parse_json_spec() {
  _spec_file="$1"
  if [ ! -f "$_spec_file" ]; then
    printf '[ERROR] JSON specification file not found: %s\n' "$_spec_file" >&2
    exit 1
  fi
  if command -v jq >/dev/null 2>&1; then
    if ! jq empty "$_spec_file" >/dev/null 2>&1; then
      printf '[ERROR] Invalid JSON syntax in specification file: %s\n' "$_spec_file" >&2
      exit 1
    fi
  fi

  SCAF_NAME=$(json_extract_scalar "$_spec_file" 'name' "$SCAF_NAME")
  SCAF_TITLE=$(json_extract_scalar "$_spec_file" 'title' "$SCAF_TITLE")
  SCAF_CATEGORY=$(json_extract_scalar "$_spec_file" 'category' "$SCAF_CATEGORY")
  SCAF_DESCRIPTION=$(json_extract_scalar "$_spec_file" 'description' "$SCAF_DESCRIPTION")
  SCAF_PROVIDES=$(json_extract_csv "$_spec_file" 'provides' "$SCAF_PROVIDES")
  SCAF_CONFLICTS=$(json_extract_csv "$_spec_file" 'conflicts' "$SCAF_CONFLICTS")
  SCAF_BINARY_NAME=$(json_extract_scalar "$_spec_file" 'binary_name' "$SCAF_BINARY_NAME")
  SCAF_INSTALL_METHOD=$(json_extract_scalar "$_spec_file" 'default_install_method' "$SCAF_INSTALL_METHOD")
  SCAF_VERSION_SCHEME=$(json_extract_scalar "$_spec_file" 'version_scheme' "$SCAF_VERSION_SCHEME")
  SCAF_DEFAULT_VERSION=$(json_extract_scalar "$_spec_file" 'default_version' "$SCAF_DEFAULT_VERSION")
  SCAF_VERSION_ALIASES=$(json_extract_csv "$_spec_file" 'version_aliases' "$SCAF_VERSION_ALIASES")
  SCAF_REPOSITORY=$(json_extract_scalar "$_spec_file" 'repository' "$SCAF_REPOSITORY")
  SCAF_GITHUB_REPO=$(json_extract_scalar "$_spec_file" 'github_repo' "$SCAF_GITHUB_REPO")
  SCAF_TAG_PREFIX=$(json_extract_scalar "$_spec_file" 'tag_prefix' "$SCAF_TAG_PREFIX")
  SCAF_URL_UNIX=$(json_extract_scalar "$_spec_file" 'download_url_template_unix' "$SCAF_URL_UNIX")
  SCAF_URL_WINDOWS=$(json_extract_scalar "$_spec_file" 'download_url_template_windows' "$SCAF_URL_WINDOWS")
  SCAF_RELEASES_URL=$(json_extract_scalar "$_spec_file" 'releases_url' "$SCAF_RELEASES_URL")
  SCAF_ARCHIVE_UNIX=$(json_extract_scalar "$_spec_file" 'archive_format_unix' "$SCAF_ARCHIVE_UNIX")
  SCAF_ARCHIVE_WINDOWS=$(json_extract_scalar "$_spec_file" 'archive_format_windows' "$SCAF_ARCHIVE_WINDOWS")
  SCAF_STRIP_COMPONENTS=$(json_extract_scalar "$_spec_file" 'strip_components' "$SCAF_STRIP_COMPONENTS")
  SCAF_OS_WHITELIST=$(json_extract_csv "$_spec_file" 'os_whitelist' "$SCAF_OS_WHITELIST")
  SCAF_OS_BLACKLIST=$(json_extract_csv "$_spec_file" 'os_blacklist' "$SCAF_OS_BLACKLIST")
  SCAF_ARCH_WHITELIST=$(json_extract_csv "$_spec_file" 'arch_whitelist' "$SCAF_ARCH_WHITELIST")
  SCAF_ARCH_BLACKLIST=$(json_extract_csv "$_spec_file" 'arch_blacklist' "$SCAF_ARCH_BLACKLIST")
  SCAF_OS_SCRIPTS=$(json_extract_csv "$_spec_file" 'os_specific_scripts' "$SCAF_OS_SCRIPTS")
  SCAF_IS_SERVICE=$(json_extract_scalar "$_spec_file" 'is_service' "$SCAF_IS_SERVICE")
  SCAF_PORTS=$(json_extract_csv "$_spec_file" 'ports' "$SCAF_PORTS")
  SCAF_ENABLE_HOOKS=$(json_extract_scalar "$_spec_file" 'enable_hooks' "$SCAF_ENABLE_HOOKS")
  SCAF_MULTITENANT=$(json_extract_scalar "$_spec_file" 'multitenant' "$SCAF_MULTITENANT")
  SCAF_TEST_CMD=$(json_extract_scalar "$_spec_file" 'test_command' "$SCAF_TEST_CMD")

  if command -v jq >/dev/null 2>&1; then
    _slang=$(jq -r '.source_build.language // empty' "$_spec_file" 2>/dev/null || true)
    [ -n "$_slang" ] && SCAF_SRC_LANG="$_slang"
    _ssys=$(jq -r '.source_build.build_system // empty' "$_spec_file" 2>/dev/null || true)
    [ -n "$_ssys" ] && SCAF_SRC_BUILD_SYS="$_ssys"
    _sfver=$(jq -r '.source_build.fallback_version // empty' "$_spec_file" 2>/dev/null || true)
    [ -n "$_sfver" ] && SCAF_SRC_FALLBACK_VER="$_sfver"
    _surl=$(jq -r '.source_build.source_url_template // empty' "$_spec_file" 2>/dev/null || true)
    [ -n "$_surl" ] && SCAF_SRC_URL_TPL="$_surl"
    _cvars=$(jq -c '.custom_vars // []' "$_spec_file" 2>/dev/null || true)
    [ -n "$_cvars" ] && SCAF_CUSTOM_VARS_JSON="$_cvars"
    SCAF_PKG_APT=$(jq -r '.pkg_mappings["apt-get"] // empty' "$_spec_file" 2>/dev/null || true)
    SCAF_PKG_APK=$(jq -r '.pkg_mappings["apk"] // empty' "$_spec_file" 2>/dev/null || true)
    SCAF_PKG_DNF=$(jq -r '.pkg_mappings["dnf"] // empty' "$_spec_file" 2>/dev/null || true)
    SCAF_PKG_PACMAN=$(jq -r '.pkg_mappings["pacman"] // empty' "$_spec_file" 2>/dev/null || true)
    SCAF_PKG_BREW=$(jq -r '.pkg_mappings["brew"] // empty' "$_spec_file" 2>/dev/null || true)
    SCAF_PKG_WINGET=$(jq -r '.pkg_mappings["winget"] // empty' "$_spec_file" 2>/dev/null || true)
    SCAF_PKG_CHOCO=$(jq -r '.pkg_mappings["choco"] // empty' "$_spec_file" 2>/dev/null || true)
    SCAF_PKG_SCOOP=$(jq -r '.pkg_mappings["scoop"] // empty' "$_spec_file" 2>/dev/null || true)
    SCAF_PKG_FREEBSD=$(jq -r '.pkg_mappings["pkg"] // empty' "$_spec_file" 2>/dev/null || true)
  fi
}

# ## prompt_line
# Prompts the user on stderr and reads a line from stdin with default fallback.
prompt_line() {
  _p_label="$1"
  _p_default="${2:-}"
  if [ -n "$_p_default" ]; then
    printf '%s [%s]: ' "$_p_label" "$_p_default" >&2
  else
    printf '%s: ' "$_p_label" >&2
  fi
  _p_ans=''
  if ! IFS= read -r _p_ans; then
    _p_ans=''
  fi
  if [ -z "$_p_ans" ]; then
    printf '%s\n' "$_p_default"
  else
    printf '%s\n' "$_p_ans"
  fi
}

# ## run_interactive_prompter
# Guides a human maintainer interactively through defining a new component-package-manager.
run_interactive_prompter() {
  printf '\n' >&2
  printf '%s\n' '+--------------------------------------------------------------------+' >&2
  printf '%s\n' '|       LibScript Component-Package-Manager Interactive Wizard       |' >&2
  printf '%s\n' '+--------------------------------------------------------------------+' >&2
  printf '\n' >&2

  # Step 1: Component Name
  while :; do
    SCAF_NAME=$(prompt_line '1. Component name (lowercase, e.g., fd, zoxide, ripgrep)' "${SCAF_NAME}")
    if validate_component_name "$SCAF_NAME"; then
      break
    fi
  done

  # Step 2: Category Selection
  printf '\n' >&2
  printf '%s\n' 'Available categories under _lib/:' >&2
  printf '%s\n' '  utilities, languages, databases, web-servers, app-servers, caches,' >&2
  printf '%s\n' '  toolchains, runtimes, search, security, networking, storage, logging,' >&2
  printf '%s\n' '  message-brokers, orchestration, package-managers, virtualization, web-apps' >&2
  while :; do
    SCAF_CATEGORY=$(prompt_line '2. Component category' "${SCAF_CATEGORY:-utilities}")
    if validate_category_name "$SCAF_CATEGORY"; then
      break
    fi
  done

  # Step 3: Title & Description
  SCAF_TITLE=$(prompt_line '3. Human-readable title' "${SCAF_TITLE:-$SCAF_NAME}")
  while :; do
    SCAF_DESCRIPTION=$(prompt_line '4. Concise description (1-2 sentences)' "${SCAF_DESCRIPTION:-Installs and manages ${SCAF_TITLE} across supported platforms.}")
    if [ -n "$SCAF_DESCRIPTION" ]; then
      break
    fi
  done

  # Step 4: Default Installation Method
  SCAF_INSTALL_METHOD=$(prompt_line '5. Default install method (libscript_native / system / from-source)' "${SCAF_INSTALL_METHOD:-libscript_native}")

  # Step 5: Version Scheme & Upstream URLs
  SCAF_VERSION_SCHEME=$(prompt_line '6. Version scheme (github-release / semver / git-tags / custom-url / system-only)' "${SCAF_VERSION_SCHEME:-github-release}")
  if [ "$SCAF_VERSION_SCHEME" = 'github-release' ]; then
    SCAF_GITHUB_REPO=$(prompt_line '   GitHub owner/repo (e.g., BurntSushi/ripgrep, or leave blank)' "${SCAF_GITHUB_REPO}")
    SCAF_TAG_PREFIX=$(prompt_line '   Release tag prefix to strip' "${SCAF_TAG_PREFIX:-v}")
    if [ -n "$SCAF_GITHUB_REPO" ]; then
      [ -z "$SCAF_REPOSITORY" ] && SCAF_REPOSITORY="https://github.com/${SCAF_GITHUB_REPO}"
      [ -z "$SCAF_RELEASES_URL" ] && SCAF_RELEASES_URL="https://api.github.com/repos/${SCAF_GITHUB_REPO}/releases/latest"
      [ -z "$SCAF_URL_UNIX" ] && SCAF_URL_UNIX="https://github.com/${SCAF_GITHUB_REPO}/releases/download/${SCAF_TAG_PREFIX}{VERSION}/${SCAF_NAME}-{VERSION}-{ARCH}-{OS}.tar.gz"
      [ -z "$SCAF_URL_WINDOWS" ] && SCAF_URL_WINDOWS="https://github.com/${SCAF_GITHUB_REPO}/releases/download/${SCAF_TAG_PREFIX}{VERSION}/${SCAF_NAME}-{VERSION}-x86_64-pc-windows-msvc.zip"
    fi
  fi
  _def_u="${SCAF_URL_UNIX}"
  [ -z "$_def_u" ] && _def_u="https://example.com/releases/${SCAF_NAME}-{VERSION}.tar.gz"
  SCAF_URL_UNIX=$(prompt_line '7. Default Unix download URL or template' "$_def_u")
  _def_w="${SCAF_URL_WINDOWS}"
  [ -z "$_def_w" ] && _def_w="https://example.com/releases/${SCAF_NAME}-{VERSION}-windows.zip"
  SCAF_URL_WINDOWS=$(prompt_line '8. Default Windows download URL or template' "$_def_w")
  SCAF_RELEASES_URL=$(prompt_line '9. Upstream releases URL (for ls-remote)' "${SCAF_RELEASES_URL:-https://example.com/releases}")
  SCAF_VERSION_ALIASES=$(prompt_line '10. Supported version aliases (comma-separated)' "${SCAF_VERSION_ALIASES:-latest,lts}")

  # Step 6: Archive & Binary Layout
  SCAF_BINARY_NAME=$(prompt_line '11. Primary executable binary name in bin/' "${SCAF_BINARY_NAME:-$SCAF_NAME}")
  SCAF_ARCHIVE_UNIX=$(prompt_line '12. Unix archive format (auto / tar.gz / tar.xz / zip / binary)' "${SCAF_ARCHIVE_UNIX:-auto}")
  SCAF_ARCHIVE_WINDOWS=$(prompt_line '13. Windows archive format (auto / zip / exe / msi)' "${SCAF_ARCHIVE_WINDOWS:-auto}")

  # Step 7: OS & Architecture Support
  while :; do
    SCAF_OS_WHITELIST=$(prompt_line '14. OS whitelist (comma-separated, e.g., all or linux,macos,windows)' "${SCAF_OS_WHITELIST:-all}")
    if validate_os_list "$SCAF_OS_WHITELIST"; then
      break
    fi
  done
  while :; do
    SCAF_OS_BLACKLIST=$(prompt_line '15. OS blacklist (comma-separated, or leave blank)' "${SCAF_OS_BLACKLIST}")
    if validate_os_list "$SCAF_OS_BLACKLIST"; then
      break
    fi
  done
  SCAF_ARCH_WHITELIST=$(prompt_line '16. Architecture whitelist (comma-separated)' "${SCAF_ARCH_WHITELIST:-all}")

  # Step 8: Service / Daemon & Hooks Options
  _svc_ans=$(prompt_line '17. Does this component run as a background service/daemon? (y/N)' 'n')
  case "$_svc_ans" in
    [Yy]*)
      SCAF_IS_SERVICE='true'
      SCAF_PORTS=$(prompt_line '    Default listening port(s) (comma-separated, e.g., 8080)' "${SCAF_PORTS}")
      _hk_ans=$(prompt_line '    Generate physical instance lifecycle hooks in hooks/? (Y/n)' 'y')
      case "$_hk_ans" in
        [Nn]*) SCAF_ENABLE_HOOKS='false' ;;
        *) SCAF_ENABLE_HOOKS='true' ;;
      esac
      _mt_ans=$(prompt_line '    Generate logical multi-tenant hooks (provision_tenant, etc.)? (y/N)' 'n')
      case "$_mt_ans" in
        [Yy]*) SCAF_MULTITENANT='true' ;;
        *) SCAF_MULTITENANT='false' ;;
      esac
      ;;
    *)
      SCAF_IS_SERVICE='false'
      ;;
  esac

  # Step 9: Summary & Optional JSON Export
  printf '\n' >&2
  printf '%s\n' '+--------------------------------------------------------------------+' >&2
  printf '| %-22s | %-41s |\n' 'Property' 'Value' >&2
  printf '%s\n' '+------------------------+-------------------------------------------+' >&2
  printf '| %-22s | %-41s |\n' 'Target Directory' "_lib/${SCAF_CATEGORY}/${SCAF_NAME}" >&2
  printf '| %-22s | %-41s |\n' 'Title' "${SCAF_TITLE}" >&2
  printf '| %-22s | %-41s |\n' 'Install Method' "${SCAF_INSTALL_METHOD}" >&2
  printf '| %-22s | %-41s |\n' 'Version Scheme' "${SCAF_VERSION_SCHEME}" >&2
  printf '| %-22s | %-41s |\n' 'Binary Name' "${SCAF_BINARY_NAME}" >&2
  printf '| %-22s | %-41s |\n' 'OS Whitelist' "${SCAF_OS_WHITELIST}" >&2
  printf '| %-22s | %-41s |\n' 'Service / Hooks' "${SCAF_IS_SERVICE} / ${SCAF_ENABLE_HOOKS}" >&2
  printf '%s\n' '+--------------------------------------------------------------------+' >&2

  if [ -z "$SCAF_EXPORT_JSON" ]; then
    _exp_ans=$(prompt_line '18. Optional path to export answers as JSON spec (or press ENTER to skip)' '')
    if [ -n "$_exp_ans" ]; then
      SCAF_EXPORT_JSON="$_exp_ans"
    fi
  fi

  _confirm=$(prompt_line '19. Proceed with generating component files? (Y/n)' 'y')
  case "$_confirm" in
    [Nn]*)
      printf '%s\n' '[INFO] Aborted by user.' >&2
      exit 0
      ;;
  esac
}

# ## csv_to_json_string_array
# Converts a comma-separated string into a JSON string array representation.
csv_to_json_string_array() {
  _in_csv="$1"
  if [ -z "$_in_csv" ]; then
    printf '%s' '[]'
    return 0
  fi
  _out='['
  _first=1
  _oifs="$IFS"
  IFS=','
  for _elem in $_in_csv; do
    _trimmed=$(printf '%s' "$_elem" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$_trimmed" ] && continue
    if [ "$_first" -eq 1 ]; then
      _out="${_out}\"${_trimmed}\""
      _first=0
    else
      _out="${_out}, \"${_trimmed}\""
    fi
  done
  IFS="$_oifs"
  _out="${_out}]"
  printf '%s' "$_out"
}

# ## csv_to_json_int_array
# Converts a comma-separated list of integers into a JSON integer array.
csv_to_json_int_array() {
  _in_csv="$1"
  if [ -z "$_in_csv" ]; then
    printf '%s' '[]'
    return 0
  fi
  _out='['
  _first=1
  _oifs="$IFS"
  IFS=','
  for _elem in $_in_csv; do
    _trimmed=$(printf '%s' "$_elem" | tr -cd '0-9')
    [ -z "$_trimmed" ] && continue
    if [ "$_first" -eq 1 ]; then
      _out="${_out}${_trimmed}"
      _first=0
    else
      _out="${_out}, ${_trimmed}"
    fi
  done
  IFS="$_oifs"
  _out="${_out}]"
  printf '%s' "$_out"
}

# ## export_spec_to_json
# Writes the current normalized SCAF_* state to a JSON specification file.
export_spec_to_json() {
  _dest_json="$1"
  _prov_arr=$(csv_to_json_string_array "${SCAF_PROVIDES:-$SCAF_NAME}")
  _conf_arr=$(csv_to_json_string_array "${SCAF_CONFLICTS}")
  _alias_arr=$(csv_to_json_string_array "${SCAF_VERSION_ALIASES:-latest,lts}")
  _os_w_arr=$(csv_to_json_string_array "${SCAF_OS_WHITELIST:-all}")
  _os_b_arr=$(csv_to_json_string_array "${SCAF_OS_BLACKLIST}")
  _arch_w_arr=$(csv_to_json_string_array "${SCAF_ARCH_WHITELIST:-all}")
  _arch_b_arr=$(csv_to_json_string_array "${SCAF_ARCH_BLACKLIST}")
  _os_scr_arr=$(csv_to_json_string_array "${SCAF_OS_SCRIPTS}")
  _ports_arr=$(csv_to_json_int_array "${SCAF_PORTS}")

  if [ "$SCAF_DRY_RUN" -eq 1 ]; then
    printf '[DRY-RUN] Would export JSON specification to %s\n' "$_dest_json"
    return 0
  fi

  _dest_dir=$(dirname "$_dest_json")
  mkdir -p "$_dest_dir"
  cat << EOF > "$_dest_json"
{
  "\$schema": "./component-scaffold.schema.json",
  "name": "${SCAF_NAME}",
  "title": "${SCAF_TITLE}",
  "category": "${SCAF_CATEGORY}",
  "description": "${SCAF_DESCRIPTION}",
  "provides": ${_prov_arr},
  "conflicts": ${_conf_arr},
  "binary_name": "${SCAF_BINARY_NAME}",
  "default_install_method": "${SCAF_INSTALL_METHOD}",
  "version_scheme": "${SCAF_VERSION_SCHEME}",
  "default_version": "${SCAF_DEFAULT_VERSION}",
  "version_aliases": ${_alias_arr},
  "repository": "${SCAF_REPOSITORY}",
  "github_repo": "${SCAF_GITHUB_REPO}",
  "tag_prefix": "${SCAF_TAG_PREFIX}",
  "download_url_template_unix": "${SCAF_URL_UNIX}",
  "download_url_template_windows": "${SCAF_URL_WINDOWS}",
  "releases_url": "${SCAF_RELEASES_URL}",
  "archive_format_unix": "${SCAF_ARCHIVE_UNIX}",
  "archive_format_windows": "${SCAF_ARCHIVE_WINDOWS}",
  "strip_components": ${SCAF_STRIP_COMPONENTS:-1},
  "source_build": {
    "language": "${SCAF_SRC_LANG}",
    "build_system": "${SCAF_SRC_BUILD_SYS}",
    "fallback_version": "${SCAF_SRC_FALLBACK_VER}",
    "source_url_template": "${SCAF_SRC_URL_TPL}"
  },
  "os_whitelist": ${_os_w_arr},
  "os_blacklist": ${_os_b_arr},
  "arch_whitelist": ${_arch_w_arr},
  "arch_blacklist": ${_arch_b_arr},
  "os_specific_scripts": ${_os_scr_arr},
  "is_service": ${SCAF_IS_SERVICE:-false},
  "ports": ${_ports_arr},
  "enable_hooks": ${SCAF_ENABLE_HOOKS:-false},
  "multitenant": ${SCAF_MULTITENANT:-false},
  "test_command": "${SCAF_TEST_CMD}"
}
EOF
  printf '[OK] Exported component scaffold JSON spec to %s\n' "$_dest_json"
}

# ## render_template
# Substitutes __SCAF_*__ tokens from stdin without interpreting shell backslashes or dollar signs.
render_template() {
  _extra_tok="${1:-}"
  _extra_val="${2:-}"
  awk \
    -v name="$SCAF_NAME" \
    -v title="$SCAF_TITLE" \
    -v cat="$SCAF_CATEGORY" \
    -v desc="$SCAF_DESCRIPTION" \
    -v bin="$SCAF_BINARY_NAME" \
    -v prefix="$COMP_PREFIX" \
    -v method="$SCAF_INSTALL_METHOD" \
    -v defver="$SCAF_DEFAULT_VERSION" \
    -v url_unix="$SCAF_URL_UNIX" \
    -v url_win="$SCAF_URL_WINDOWS" \
    -v src_url="${SCAF_SRC_URL_TPL:-$SCAF_URL_UNIX}" \
    -v rel_url="$SCAF_RELEASES_URL" \
    -v strip_c="${SCAF_STRIP_COMPONENTS:-1}" \
    -v src_sys="$SCAF_SRC_BUILD_SYS" \
    -v src_lang="$SCAF_SRC_LANG" \
    -v src_fver="$SCAF_SRC_FALLBACK_VER" \
    -v gh_repo="$SCAF_GITHUB_REPO" \
    -v tag_pfx="$SCAF_TAG_PREFIX" \
    -v vscheme="$SCAF_VERSION_SCHEME" \
    -v smoke_cmd="${SCAF_TEST_CMD:-${SCAF_BINARY_NAME} --version}" \
    -v aliases="$SCAF_VERSION_ALIASES" \
    -v etok="$_extra_tok" \
    -v eval_str="$_extra_val" '
    function rep(str, tok, val,    idx, out) {
      if (tok == "") return str
      out = ""
      while ((idx = index(str, tok)) > 0) {
        out = out substr(str, 1, idx - 1) val
        str = substr(str, idx + length(tok))
      }
      return out str
    }
    {
      line = $0
      if (etok != "") line = rep(line, etok, eval_str)
      line = rep(line, "__SCAF_NAME__", name)
      line = rep(line, "__SCAF_TITLE__", title)
      line = rep(line, "__SCAF_CATEGORY__", cat)
      line = rep(line, "__SCAF_DESCRIPTION__", desc)
      line = rep(line, "__SCAF_BINARY_NAME__", bin)
      line = rep(line, "__COMP_PREFIX__", prefix)
      line = rep(line, "__SCAF_INSTALL_METHOD__", method)
      line = rep(line, "__SCAF_DEFAULT_VERSION__", defver)
      line = rep(line, "__SCAF_URL_UNIX__", url_unix)
      line = rep(line, "__SCAF_URL_WINDOWS__", url_win)
      line = rep(line, "__SCAF_SRC_URL__", src_url)
      line = rep(line, "__SCAF_RELEASES_URL__", rel_url)
      line = rep(line, "__SCAF_STRIP_COMPONENTS__", strip_c)
      line = rep(line, "__SCAF_SRC_BUILD_SYS__", src_sys)
      line = rep(line, "__SCAF_SRC_LANG__", src_lang)
      line = rep(line, "__SCAF_SRC_FALLBACK_VER__", src_fver)
      line = rep(line, "__SCAF_GITHUB_REPO__", gh_repo)
      line = rep(line, "__SCAF_TAG_PREFIX__", tag_pfx)
      line = rep(line, "__SCAF_VERSION_SCHEME__", vscheme)
      line = rep(line, "__SCAF_SMOKE_CMD__", smoke_cmd)
      line = rep(line, "__SCAF_VERSION_ALIASES__", aliases)
      print line
    }
  '
}

# ## write_component_file
# Writes content from stdin to a target file idempotently, respecting --force and --dry-run.
write_component_file() {
  _target_path="$1"
  _is_exec="${2:-0}"
  _is_crlf="${3:-0}"
  _extra_tok="${4:-}"
  _extra_val="${5:-}"

  if [ "$SCAF_DRY_RUN" -eq 1 ]; then
    cat >/dev/null
    printf '[DRY-RUN] Would create %s\n' "$_target_path"
    return 0
  fi

  if [ -f "$_target_path" ] && [ "$SCAF_FORCE" -eq 0 ]; then
    cat >/dev/null
    printf '[SKIP] %s already exists (idempotent skip; use --force to overwrite).\n' "$_target_path"
    return 0
  fi

  mkdir -p "$(dirname "$_target_path")"
  if [ "$_is_crlf" -eq 1 ]; then
    render_template "$_extra_tok" "$_extra_val" | awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' > "$_target_path"
  else
    render_template "$_extra_tok" "$_extra_val" | awk '{ sub(/\r$/, ""); printf "%s\n", $0 }' > "$_target_path"
  fi

  if [ "$_is_exec" -eq 1 ]; then
    chmod +x "$_target_path"
  fi
  printf '[CREATE] %s\n' "$_target_path"
}

# ## map_category_manifest_type
# Maps a _lib/<category> directory name to the singular category string used in manifest.json.
map_category_manifest_type() {
  _c="$1"
  case "$_c" in
    utilities) printf '%s\n' 'utility' ;;
    databases) printf '%s\n' 'database' ;;
    languages) printf '%s\n' 'language' ;;
    web-servers) printf '%s\n' 'web-server' ;;
    app-servers) printf '%s\n' 'app-server' ;;
    caches) printf '%s\n' 'cache' ;;
    toolchains) printf '%s\n' 'toolchain' ;;
    runtimes) printf '%s\n' 'runtime' ;;
    message-brokers) printf '%s\n' 'message-broker' ;;
    package-managers) printf '%s\n' 'package-manager' ;;
    web-apps) printf '%s\n' 'web-app' ;;
    *) printf '%s\n' "$_c" ;;
  esac
}

# ## synthesize_manifest_json
# Generates _lib/<category>/<component>/manifest.json.
synthesize_manifest_json() {
  _comp_dir="$1"
  _m_cat=$(map_category_manifest_type "$SCAF_CATEGORY")
  _prov_arr=$(csv_to_json_string_array "${SCAF_PROVIDES:-$SCAF_NAME}")
  _os_w_arr=$(csv_to_json_string_array "${SCAF_OS_WHITELIST:-all}")
  _extra_fields=''

  if [ -n "$SCAF_CONFLICTS" ]; then
    _conf_arr=$(csv_to_json_string_array "$SCAF_CONFLICTS")
    _extra_fields="${_extra_fields},
  \"conflicts\": ${_conf_arr}"
  fi
  if [ -n "$SCAF_OS_BLACKLIST" ]; then
    _os_b_arr=$(csv_to_json_string_array "$SCAF_OS_BLACKLIST")
    _extra_fields="${_extra_fields},
  \"os_blacklist\": ${_os_b_arr}"
  fi
  if [ -n "$SCAF_ARCH_WHITELIST" ] && [ "$SCAF_ARCH_WHITELIST" != 'all' ]; then
    _arch_w_arr=$(csv_to_json_string_array "$SCAF_ARCH_WHITELIST")
    _extra_fields="${_extra_fields},
  \"arch_whitelist\": ${_arch_w_arr}"
  fi
  if [ -n "$SCAF_ARCH_BLACKLIST" ]; then
    _arch_b_arr=$(csv_to_json_string_array "$SCAF_ARCH_BLACKLIST")
    _extra_fields="${_extra_fields},
  \"arch_blacklist\": ${_arch_b_arr}"
  fi
  if [ -n "$SCAF_PORTS" ]; then
    _ports_arr=$(csv_to_json_int_array "$SCAF_PORTS")
    _extra_fields="${_extra_fields},
  \"ports\": ${_ports_arr}"
  fi
  if [ "$SCAF_IS_SERVICE" = 'true' ]; then
    case "$SCAF_CATEGORY" in
      databases|caches|search|message-brokers|storage-layers|git-servers)
        _extra_fields="${_extra_fields},
  \"stateful\": true"
        ;;
    esac
  fi
  if [ "$SCAF_MULTITENANT" = 'true' ]; then
    _extra_fields="${_extra_fields},
  \"multitenant\": true"
  fi
  if [ -n "$SCAF_REPOSITORY" ]; then
    _extra_fields="${_extra_fields},
  \"repository\": \"${SCAF_REPOSITORY}\""
  fi
  if [ "$SCAF_ENABLE_HOOKS" = 'true' ] || [ "$SCAF_MULTITENANT" = 'true' ]; then
    _logical_hooks='[]'
    if [ "$SCAF_MULTITENANT" = 'true' ]; then
      _logical_hooks='["provision_tenant", "deprovision_tenant", "backup_tenant", "restore_tenant"]'
    fi
    _extra_fields="${_extra_fields},
  \"hooks\": {
    \"physical\": [
      \"configure\",
      \"probe\",
      \"announce\",
      \"log_stream\",
      \"metrics\",
      \"backup\",
      \"restore\",
      \"upgrade\",
      \"rollback\",
      \"maintenance\"
    ],
    \"logical\": ${_logical_hooks},
    \"probe_timeout_seconds\": 30,
    \"metrics_scrape_path\": \"/metrics\"
  }"
  fi

  write_component_file "${_comp_dir}/manifest.json" 0 0 << EOF
{
  "\$schema": "../../_common/manifest.schema.json",
  "name": "${SCAF_NAME}",
  "title": "${SCAF_TITLE}",
  "description": "${SCAF_DESCRIPTION}",
  "category": "${_m_cat}",
  "provides": ${_prov_arr},
  "os_whitelist": ${_os_w_arr}${_extra_fields}
}
EOF
}

# ## synthesize_vars_schema_json
# Generates _lib/<category>/<component>/vars.schema.json with 100% property description coverage.
synthesize_vars_schema_json() {
  _comp_dir="$1"
  _prefix="$2"
  _alias_arr=$(csv_to_json_string_array "${SCAF_VERSION_ALIASES:-latest,lts}")
  _extra_props=''

  if [ "$SCAF_IS_SERVICE" = 'true' ] || [ -n "$SCAF_PORTS" ]; then
    _def_port=$(printf '%s' "${SCAF_PORTS:-8080}" | cut -d',' -f1 | tr -cd '0-9')
    [ -z "$_def_port" ] && _def_port='8080'
    _extra_props="${_extra_props},
    \"${_prefix}_LISTEN_PORT\": {
      \"type\": \"integer\",
      \"description\": \"TCP port on which the ${SCAF_NAME} service listens.\",
      \"default\": ${_def_port}
    }"
  fi

  if [ "$SCAF_CUSTOM_VARS_JSON" != '[]' ] && command -v jq >/dev/null 2>&1; then
    _custom_entries=$(printf '%s' "$SCAF_CUSTOM_VARS_JSON" | jq -r '
      map(
        "    \"" + .name + "\": {\n" +
        "      \"type\": \"" + (.type // "string") + "\",\n" +
        "      \"description\": \"" + (.description // "Custom configuration variable.") + "\"" +
        (if has("default") and .default != null then ",\n      \"default\": " + (.default | tojson) else "" end) +
        "\n    }"
      ) | join(",\n")
    ' 2>/dev/null || true)
    if [ -n "$_custom_entries" ]; then
      _extra_props="${_extra_props},
${_custom_entries}"
    fi
  fi

  write_component_file "${_comp_dir}/vars.schema.json" 0 0 << EOF
{
  "\$schema": "https://json-schema.org/draft/2020-12/schema",
  "\$id": "/_lib/${SCAF_CATEGORY}/${SCAF_NAME}/vars.schema.json",
  "title": "${SCAF_NAME} variables",
  "description": "Configuration variables for ${SCAF_NAME}",
  "type": "object",
  "properties": {
    "${_prefix}_INSTALL_METHOD": {
      "type": "string",
      "description": "How to install ${SCAF_NAME}. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source.",
      "enum": ["libscript_native", "system", "from-source"],
      "default": "${SCAF_INSTALL_METHOD}"
    },
    "${_prefix}_VERSION": {
      "description": "Specific version of ${SCAF_NAME} to install.",
      "type": "string",
      "default": "${SCAF_DEFAULT_VERSION}",
      "version_aliases": ${_alias_arr}
    },
    "${_prefix}_DOWNLOAD_URL": {
      "type": "string",
      "description": "Override URL for downloading ${SCAF_NAME} binary or archive artifacts."
    },
    "${_prefix}_RELEASES_URL": {
      "type": "string",
      "description": "Override URL for querying ${SCAF_NAME} available remote releases."
    }${_extra_props}
  }
}
EOF
}

# ## synthesize_cli_scripts
# Generates cli.sh and cli.cmd for the component.
synthesize_cli_scripts() {
  _comp_dir="$1"
  write_component_file "${_comp_dir}/cli.sh" 1 0 << 'EOF'
#!/bin/sh
# ## Overview
# Command-line interface entrypoint for the __SCAF_NAME__ component.
# It initializes the lifecycle, resolves the package name, and delegates execution
# to the shared component_core.sh script.
#
# ## Usage
# Execute this script with standard component actions (e.g., install, status, start, stop).

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

export PACKAGE_NAME='__SCAF_NAME__'
SCRIPT_NAME="${SCRIPT_DIR}/../../_common/component_core.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
EOF

  write_component_file "${_comp_dir}/cli.cmd" 0 1 << 'EOF'
@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entrypoint for the __SCAF_NAME__ component on Windows.
:: It initializes the lifecycle and delegates execution to the shared batch components.
::
:: ## Usage
:: Execute this script with standard component actions (e.g., install, status, start, stop).

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

set "PACKAGE_NAME=__SCAF_NAME__"
call "%~dp0\..\..\_common\component_core.cmd" %*
EOF
}

# ## synthesize_setup_scripts
# Generates setup.sh, setup.cmd, setup_generic.sh, and setup_generic.cmd for the component.
synthesize_setup_scripts() {
  _comp_dir="$1"

  write_component_file "${_comp_dir}/setup.sh" 1 0 << 'EOF'
#!/bin/sh
# ## Overview
# Installation and configuration script for the __SCAF_NAME__ component.
# It uses the shared setup_base.sh logic to handle downloading, verifying,
# and installing the component on the host system.
#
# ## Usage
# Execute this script directly or via the global CLI to install the component.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SCRIPT_NAME="${SCRIPT_DIR}/../../_common/setup_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
EOF

  write_component_file "${_comp_dir}/setup.cmd" 0 1 << 'EOF'
@echo off
:: # setup.cmd
::
:: ## Overview
:: Installation and configuration script for the __SCAF_NAME__ component on Windows.
:: It handles downloading, verifying, and installing the component on the host system.
::
:: ## Usage
:: Execute this script directly or via the global CLI to install the component.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

call "%~dp0\..\..\_common\setup_base.cmd" %*
EOF

  write_component_file "${_comp_dir}/setup_generic.sh" 1 0 << 'EOF'
#!/bin/sh
# ## Overview
# Generic setup script for the __SCAF_NAME__ component implementing the Version Manager Contract.
#
# ## Usage
# This script is typically called internally by the component lifecycle.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/versioning.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/source_builder.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

__COMP_PREFIX___INSTALL_METHOD="${__COMP_PREFIX___INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-__SCAF_INSTALL_METHOD__}}"
ACTION="${ACTION:-install}"
VERSION="${__COMP_PREFIX___VERSION:-__SCAF_DEFAULT_VERSION__}"

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='__SCAF_GITHUB_REPO__'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/__SCAF_GITHUB_REPO__/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^__SCAF_TAG_PREFIX__//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='__SCAF_SRC_FALLBACK_VER__'
      fi
    else
      EXACT_VERSION='__SCAF_SRC_FALLBACK_VER__'
    fi
  else
    EXACT_VERSION="${VERSION}"
  fi
}

# ## resolve_artifact_url
# Substitutes version, OS, and CPU architecture tokens into an artifact URL template.
resolve_artifact_url() {
  _tpl="$1"
  _os_tok="${UNAME_LOWER:-linux}"
  _os_title='Linux'
  case "$_os_tok" in
    darwin*) _os_tok='darwin'; _os_title='Darwin' ;;
    freebsd*) _os_tok='freebsd'; _os_title='FreeBSD' ;;
    sunos*) _os_tok='sunos'; _os_title='SunOS' ;;
    *) _os_tok='linux'; _os_title='Linux' ;;
  esac
  _arch_raw="${ARCH:-x86_64}"
  _arch_x86='x86_64'
  _arch_go='amd64'
  case "$_arch_raw" in
    aarch64|arm64) _arch_x86='aarch64'; _arch_go='arm64' ;;
    x86_64|amd64) _arch_x86='x86_64'; _arch_go='amd64' ;;
    *) _arch_x86="$_arch_raw"; _arch_go="$_arch_raw" ;;
  esac
  _rust_target="${_arch_x86}-unknown-linux-musl"
  case "${_os_tok}:${_arch_x86}" in
    linux:aarch64) _rust_target='aarch64-unknown-linux-gnu' ;;
    linux:*) _rust_target="${_arch_x86}-unknown-linux-musl" ;;
    darwin:*) _rust_target="${_arch_x86}-apple-darwin" ;;
    freebsd:*) _rust_target="${_arch_x86}-unknown-freebsd" ;;
  esac
  printf '%s\n' "$_tpl" | sed \
    -e "s/{VERSION}/${EXACT_VERSION}/g" \
    -e "s/{OS}/${_os_tok}/g" \
    -e "s/{OS_TITLE}/${_os_title}/g" \
    -e "s/{ARCH}/${_arch_x86}/g" \
    -e "s/{ARCH_GO}/${_arch_go}/g" \
    -e "s/{RUST_TARGET}/${_rust_target}/g"
}

case "$ACTION" in
  ls)
    if [ "${__COMP_PREFIX___INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/__SCAF_NAME__" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/__SCAF_NAME__"
    else
      if command -v '__SCAF_BINARY_NAME__' >/dev/null 2>&1; then
        '__SCAF_BINARY_NAME__' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${__COMP_PREFIX___RELEASES_URL:-__SCAF_RELEASES_URL__}"
    printf '[ls-remote] Fetching available __SCAF_NAME__ versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/__SCAF_NAME__/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias '__SCAF_NAME__' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias '__SCAF_NAME__' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    _def_dl_url='__SCAF_URL_UNIX__'
    URL="${__COMP_PREFIX___DOWNLOAD_URL:-${_def_dl_url}}"
    URL=$(resolve_artifact_url "$URL")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/__SCAF_NAME__"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading __SCAF_NAME__ %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${__COMP_PREFIX___INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/__SCAF_NAME__/${EXACT_VERSION}"
      _def_src_url='__SCAF_SRC_URL__'
      SRC_URL="${__COMP_PREFIX___DOWNLOAD_URL:-${_def_src_url}}"
      SRC_URL=$(resolve_artifact_url "$SRC_URL")
      libscript_build_component_from_source '__SCAF_NAME__' "$EXACT_VERSION" '__SCAF_BINARY_NAME__' '__SCAF_SRC_LANG__' '__SCAF_SRC_BUILD_SYS__' "$SRC_URL"
      libscript_symlink_alias '__SCAF_NAME__' "${VERSION}" "${EXACT_VERSION}"
      exit 0
    elif [ "${__COMP_PREFIX___INSTALL_METHOD}" = "system" ]; then
      libscript_depends '__SCAF_NAME__'
    elif [ "${__COMP_PREFIX___INSTALL_METHOD}" = "nix" ] || [ "${__COMP_PREFIX___INSTALL_METHOD}" = "guix" ] || [ "${__COMP_PREFIX___INSTALL_METHOD}" = "spack" ] || [ "${__COMP_PREFIX___INSTALL_METHOD}" = "brew" ] || [ "${__COMP_PREFIX___INSTALL_METHOD}" = "winget" ] || [ "${__COMP_PREFIX___INSTALL_METHOD}" = "choco" ] || [ "${__COMP_PREFIX___INSTALL_METHOD}" = "scoop" ]; then
      libscript_depends_via "${__COMP_PREFIX___INSTALL_METHOD}" '__SCAF_NAME__'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/__SCAF_NAME__/${EXACT_VERSION}"
      if [ -x "${TARGET_DIR}/bin/__SCAF_BINARY_NAME__" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] %s %s is already installed at %s.\n' '__SCAF_NAME__' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias '__SCAF_NAME__' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias '__SCAF_NAME__' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      _def_url='__SCAF_URL_UNIX__'
      URL="${__COMP_PREFIX___DOWNLOAD_URL:-${_def_url}}"
      URL=$(resolve_artifact_url "$URL")
      if [ -z "$URL" ]; then
        libscript_depends '__SCAF_NAME__'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/__SCAF_NAME__/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/__SCAF_NAME__-$$.archive"
        PACKAGE_NAME='__SCAF_NAME__' libscript_download "$URL" "$TMP_FILE"
      fi
      case "$URL" in
        *.tar.gz|*.tgz)
          tar -xzf "$TMP_FILE" -C "$TARGET_DIR" --strip-components=__SCAF_STRIP_COMPONENTS__ 2>/dev/null || tar -xzf "$TMP_FILE" -C "$TARGET_DIR"
          ;;
        *.tar.xz|*.txz)
          tar -xJf "$TMP_FILE" -C "$TARGET_DIR" --strip-components=__SCAF_STRIP_COMPONENTS__ 2>/dev/null || tar -xJf "$TMP_FILE" -C "$TARGET_DIR"
          ;;
        *.tar.bz2|*.tbz2)
          tar -xjf "$TMP_FILE" -C "$TARGET_DIR" --strip-components=__SCAF_STRIP_COMPONENTS__ 2>/dev/null || tar -xjf "$TMP_FILE" -C "$TARGET_DIR"
          ;;
        *.zip)
          unzip -q -o "$TMP_FILE" -d "$TARGET_DIR"
          ;;
        *)
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/__SCAF_BINARY_NAME__"
          chmod +x "$TARGET_DIR/bin/__SCAF_BINARY_NAME__"
          ;;
      esac
      if [ ! -x "$TARGET_DIR/bin/__SCAF_BINARY_NAME__" ]; then
        _sub_dirs=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
        for _sub in $_sub_dirs; do
          [ "$_sub" = "$TARGET_DIR/bin" ] && continue
          if [ -f "$_sub/bin/__SCAF_BINARY_NAME__" ] || [ -f "$_sub/bin/__SCAF_BINARY_NAME__.sh" ] || [ -f "$_sub/sbin/__SCAF_BINARY_NAME__" ] || [ -f "$_sub/__SCAF_BINARY_NAME__" ]; then
            _flat_tmp="${TARGET_DIR}.flat.$$"
            rm -rf "$_flat_tmp"
            mv "$_sub" "$_flat_tmp"
            cp -Rf "$_flat_tmp"/. "$TARGET_DIR"/
            rm -rf "$_flat_tmp"
            break
          fi
        done
      fi
      if [ ! -x "$TARGET_DIR/bin/__SCAF_BINARY_NAME__" ] && [ -f "$TARGET_DIR/bin/__SCAF_BINARY_NAME__.sh" ]; then
        chmod +x "$TARGET_DIR/bin/__SCAF_BINARY_NAME__.sh"
        ln -sf "__SCAF_BINARY_NAME__.sh" "$TARGET_DIR/bin/__SCAF_BINARY_NAME__"
      fi
      if [ ! -x "$TARGET_DIR/bin/__SCAF_BINARY_NAME__" ] && [ -f "$TARGET_DIR/sbin/__SCAF_BINARY_NAME__" ]; then
        chmod +x "$TARGET_DIR/sbin/__SCAF_BINARY_NAME__"
        ln -sf "../sbin/__SCAF_BINARY_NAME__" "$TARGET_DIR/bin/__SCAF_BINARY_NAME__"
      fi
      if [ ! -x "$TARGET_DIR/bin/__SCAF_BINARY_NAME__" ] && [ -f "$TARGET_DIR/__SCAF_BINARY_NAME__" ]; then
        chmod +x "$TARGET_DIR/__SCAF_BINARY_NAME__"
        ln -sf "../__SCAF_BINARY_NAME__" "$TARGET_DIR/bin/__SCAF_BINARY_NAME__"
      fi
      if [ ! -x "$TARGET_DIR/bin/__SCAF_BINARY_NAME__" ]; then
        for _entry in $(ls -1 "$TARGET_DIR" 2>/dev/null || true); do
          case "$_entry" in
            __SCAF_BINARY_NAME__-*|__SCAF_BINARY_NAME___*)
              if [ -f "$TARGET_DIR/$_entry" ]; then
                chmod +x "$TARGET_DIR/$_entry"
                ln -sf "../$_entry" "$TARGET_DIR/bin/__SCAF_BINARY_NAME__"
                break
              fi
              ;;
          esac
        done
      fi
      if [ -f "$TARGET_DIR/bin/__SCAF_BINARY_NAME__" ]; then
        chmod +x "$TARGET_DIR/bin/__SCAF_BINARY_NAME__"
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias '__SCAF_NAME__' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias '__SCAF_NAME__' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action '__SCAF_NAME__' "$ACTION" "$VERSION" "${__COMP_PREFIX___INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
EOF

  write_component_file "${_comp_dir}/setup_generic.cmd" 0 1 << 'EOF'
@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for __SCAF_NAME__ implementing the Version Manager Contract.
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%__COMP_PREFIX___INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "__COMP_PREFIX___INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "__COMP_PREFIX___INSTALL_METHOD=__SCAF_INSTALL_METHOD__"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%__COMP_PREFIX___VERSION%"=="" set "__COMP_PREFIX___VERSION=__SCAF_DEFAULT_VERSION__"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of __SCAF_NAME__.
:action_ls
if "%__COMP_PREFIX___INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\__SCAF_NAME__" dir /b "%LIBSCRIPT_HOME%\__SCAF_NAME__"
) else (
    where __SCAF_BINARY_NAME__ >nul 2>&1 && __SCAF_BINARY_NAME__ --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of __SCAF_NAME__.
:action_ls_remote
set "RELEASES_URL=%__COMP_PREFIX___RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=__SCAF_RELEASES_URL__"
echo [ls-remote] Fetching available __SCAF_NAME__ versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of __SCAF_NAME__ and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\__SCAF_NAME__\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    call "%~f0"
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "__SCAF_NAME__" "%__COMP_PREFIX___VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "__SCAF_NAME__" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the __SCAF_NAME__ release artifact to the local cache directory.
:action_download
call :resolve_version
set "URL=%__COMP_PREFIX___DOWNLOAD_URL%"
if "!URL!"=="" set "URL=__SCAF_URL_WINDOWS__"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\__SCAF_NAME__"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading __SCAF_NAME__ %__COMP_PREFIX___VERSION% from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs __SCAF_NAME__ via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%__COMP_PREFIX___INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "TARGET_DIR=%LIBSCRIPT_HOME%\__SCAF_NAME__\!EXACT_VERSION!"
    set "SRC_URL=%__COMP_PREFIX___DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=__SCAF_SRC_URL__"
    call set "SRC_URL=%%SRC_URL:{VERSION}=!EXACT_VERSION!%%"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "__SCAF_NAME__" "!EXACT_VERSION!" "__SCAF_BINARY_NAME__" "__SCAF_SRC_LANG__" "__SCAF_SRC_BUILD_SYS__" "!SRC_URL!"
    exit /b !errorlevel!
)
if "%__COMP_PREFIX___INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends __SCAF_NAME__
    exit /b !errorlevel!
)
if /i "%__COMP_PREFIX___INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via winget __SCAF_NAME__
    exit /b !errorlevel!
)
if /i "%__COMP_PREFIX___INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via choco __SCAF_NAME__
    exit /b !errorlevel!
)
if /i "%__COMP_PREFIX___INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via scoop __SCAF_NAME__
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\__SCAF_NAME__\!EXACT_VERSION!"
set "_BIN_FOUND=0"
if exist "!TARGET_DIR!\bin\__SCAF_BINARY_NAME__.exe" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\__SCAF_BINARY_NAME__.cmd" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\__SCAF_BINARY_NAME__.bat" set "_BIN_FOUND=1"
if "!_BIN_FOUND!"=="1" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] __SCAF_NAME__ !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "__SCAF_NAME__" "%__COMP_PREFIX___VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "__SCAF_NAME__" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
set "URL=%__COMP_PREFIX___DOWNLOAD_URL%"
if "!URL!"=="" set "URL=__SCAF_URL_WINDOWS__"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
if "!URL!"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends __SCAF_NAME__
    exit /b !errorlevel!
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\__SCAF_NAME__\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\__SCAF_NAME__-!RANDOM!.archive"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
    if errorlevel 1 exit /b 1
)
set "_IS_ARCHIVE=0"
if /i "!URL:~-4!"==".zip" set "_IS_ARCHIVE=zip"
if /i "!URL:~-7!"==".tar.gz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-4!"==".tgz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-7!"==".tar.xz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-4!"==".txz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-8!"==".tar.bz2" set "_IS_ARCHIVE=tar"
if /i "!URL:~-5!"==".tbz2" set "_IS_ARCHIVE=tar"
if not "!_IS_ARCHIVE!"=="0" (
    if "!_IS_ARCHIVE!"=="zip" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '!TMP_FILE!' -DestinationPath '!TARGET_DIR!' -Force"
    ) else (
        tar -xf "!TMP_FILE!" -C "!TARGET_DIR!" --strip-components=__SCAF_STRIP_COMPONENTS__ 2>nul || tar -xf "!TMP_FILE!" -C "!TARGET_DIR!"
    )
    for /d %%D in ("!TARGET_DIR!\*") do (
        if /i not "%%~nxD"=="bin" (
            set "_DO_FLAT=0"
            if exist "%%~fD\bin\__SCAF_BINARY_NAME__.exe" set "_DO_FLAT=1"
            if exist "%%~fD\bin\__SCAF_BINARY_NAME__.bat" set "_DO_FLAT=1"
            if exist "%%~fD\bin\__SCAF_BINARY_NAME__.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\__SCAF_BINARY_NAME__.exe" set "_DO_FLAT=1"
            if exist "%%~fD\__SCAF_BINARY_NAME__.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\__SCAF_BINARY_NAME__.bat" set "_DO_FLAT=1"
            if "!_DO_FLAT!"=="1" (
                move /y "%%~fD" "!TARGET_DIR!_flat" >nul
                xcopy /E /I /Y "!TARGET_DIR!_flat\*" "!TARGET_DIR!\" >nul
                rmdir /s /q "!TARGET_DIR!_flat"
            )
        )
    )
    if not exist "!TARGET_DIR!\bin\__SCAF_BINARY_NAME__.exe" (
        if exist "!TARGET_DIR!\__SCAF_BINARY_NAME__.exe" (
            copy /y "!TARGET_DIR!\__SCAF_BINARY_NAME__.exe" "!TARGET_DIR!\bin\__SCAF_BINARY_NAME__.exe" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\__SCAF_BINARY_NAME__.cmd" (
        if exist "!TARGET_DIR!\__SCAF_BINARY_NAME__.cmd" (
            copy /y "!TARGET_DIR!\__SCAF_BINARY_NAME__.cmd" "!TARGET_DIR!\bin\__SCAF_BINARY_NAME__.cmd" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\__SCAF_BINARY_NAME__.bat" (
        if exist "!TARGET_DIR!\__SCAF_BINARY_NAME__.bat" (
            copy /y "!TARGET_DIR!\__SCAF_BINARY_NAME__.bat" "!TARGET_DIR!\bin\__SCAF_BINARY_NAME__.bat" >nul
        )
    )
) else (
    copy /y "!TMP_FILE!" "!TARGET_DIR!\bin\__SCAF_BINARY_NAME__.exe" >nul
)
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "__SCAF_NAME__" "%__COMP_PREFIX___VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "__SCAF_NAME__" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%__COMP_PREFIX___VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%__COMP_PREFIX___VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%__COMP_PREFIX___VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%__COMP_PREFIX___VERSION%"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries GitHub Releases API for the latest tag with offline fallback.
:resolve_remote_gh_tag
set "EXACT_VERSION="
if not "__SCAF_GITHUB_REPO__" == "" (
    for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_resolve_github_tag "https://api.github.com/repos/__SCAF_GITHUB_REPO__/releases/latest"') do (
        set "EXACT_VERSION=%%T"
    )
)
if not "__SCAF_TAG_PREFIX__" == "" (
    if not "!EXACT_VERSION!"=="" set "EXACT_VERSION=!EXACT_VERSION:__SCAF_TAG_PREFIX__=!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=__SCAF_SRC_FALLBACK_VER__"
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "__SCAF_NAME__" "%ACTION%" "%__COMP_PREFIX___VERSION%" "%__COMP_PREFIX___INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\__SCAF_NAME__\%__COMP_PREFIX___VERSION%\\bin\\__SCAF_BINARY_NAME__.exe\"" "%LIBSCRIPT_HOME%\__SCAF_NAME__\%__COMP_PREFIX___VERSION%"
exit /b !errorlevel!
EOF
}

# ## synthesize_env_scripts
# Generates env.sh and env.cmd for the component.
synthesize_env_scripts() {
  _comp_dir="$1"

  write_component_file "${_comp_dir}/env.sh" 1 0 << 'EOF'
#!/bin/sh
# ## Overview
# Environment configuration script for __SCAF_NAME__.
#
# ## Usage
# Source this script to prepend the isolated __SCAF_NAME__ bin directory to PATH.
set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
_EB_CALLER_THIS="${THIS_FILE}"
_EB_CALLER_DIR="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

__COMP_PREFIX___VERSION="${__COMP_PREFIX___VERSION:-__SCAF_DEFAULT_VERSION__}"
if [ "${__COMP_PREFIX___VERSION}" = "latest" ]; then
  EXACT_VERSION='latest'
else
  EXACT_VERSION="${__COMP_PREFIX___VERSION}"
fi

libscript_path_prepend "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/__SCAF_NAME__/${EXACT_VERSION}/bin"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
EOF

  write_component_file "${_comp_dir}/env.cmd" 0 1 << 'EOF'
@echo off
:: # env.cmd
::
:: ## Overview
:: Windows environment configuration and PATH setup for __SCAF_NAME__.
::
:: ## Usage
:: call _lib\__SCAF_CATEGORY__\__SCAF_NAME__\env.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%__COMP_PREFIX___VERSION%"=="" (
    set "__COMP_PREFIX___VERSION=__SCAF_DEFAULT_VERSION__"
)

set "_CAND_P=%LIBSCRIPT_HOME%\__SCAF_NAME__\%__COMP_PREFIX___VERSION%\bin"
echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "__SCAF_NAME__" "%__COMP_PREFIX___VERSION%"

endlocal & (
    set "__COMP_PREFIX___VERSION=%__COMP_PREFIX___VERSION%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "PATH=%PATH%"
)
exit /b 0
EOF
}

# ## synthesize_lifecycle_scripts
# Generates service, status, logs, uninstall, uninstall_generic, and test scripts (.sh and .cmd).
synthesize_lifecycle_scripts() {
  _comp_dir="$1"

  write_component_file "${_comp_dir}/service.sh" 1 0 << 'EOF'
#!/bin/sh
# ## Overview
# Manages background service lifecycle operations (start, stop, status) for the __SCAF_NAME__ component.
#
# ## Usage
# ./service.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

exit 0
EOF

  write_component_file "${_comp_dir}/service.cmd" 0 1 << 'EOF'
@echo off
:: # service.cmd
::
:: ## Overview
:: Manages background service lifecycle operations (start, stop, status) for the __SCAF_NAME__ component.
::
:: ## Usage
:: service.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

exit /b 0
EOF

  write_component_file "${_comp_dir}/status.sh" 1 0 << 'EOF'
#!/bin/sh
# ## Overview
# Status check for __SCAF_CATEGORY__/__SCAF_NAME__.
#
# ## Usage
# ./status.sh

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

if [ -f "${SCRIPT_DIR}/test.sh" ]; then
  exec "${SCRIPT_DIR}/test.sh" "$@"
fi
exit 0
EOF

  write_component_file "${_comp_dir}/status.cmd" 0 1 << 'EOF'
@echo off
:: # status.cmd
::
:: ## Overview
:: Status check for __SCAF_CATEGORY__/__SCAF_NAME__.
::
:: ## Usage
:: status.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

if exist "!SCRIPT_DIR!\test.cmd" (
  call "!SCRIPT_DIR!\test.cmd" %*
)
exit /b !ERRORLEVEL!
EOF

  write_component_file "${_comp_dir}/logs.sh" 1 0 << 'EOF'
#!/bin/sh
# ## Overview
# Logs reader for __SCAF_CATEGORY__/__SCAF_NAME__.
#
# ## Usage
# ./logs.sh [tail|-f]

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

echo 'No logging implemented for this component.'
exit 0
EOF

  write_component_file "${_comp_dir}/logs.cmd" 0 1 << 'EOF'
@echo off
:: # logs.cmd
::
:: ## Overview
:: Logs reader for __SCAF_CATEGORY__/__SCAF_NAME__.
::
:: ## Usage
:: logs.cmd [tail|-f]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

echo No logging implemented for this component.
exit /b 0
EOF

  write_component_file "${_comp_dir}/uninstall.sh" 1 0 << 'EOF'
#!/bin/sh
# ## Overview
# Uninstallation script for the __SCAF_NAME__ component.
# It uses the shared uninstall_base.sh logic to safely remove the component
# and its associated files from the host system.
#
# ## Usage
# Execute this script to remove the component.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SCRIPT_NAME="${SCRIPT_DIR}/../../_common/uninstall_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
EOF

  write_component_file "${_comp_dir}/uninstall.cmd" 0 1 << 'EOF'
@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation script for the __SCAF_NAME__ component on Windows.
:: It safely removes the component and its associated files from the host system.
::
:: ## Usage
:: Execute this script to remove the component.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

call "%~dp0\..\..\_common\uninstall_base.cmd" %*
EOF

  write_component_file "${_comp_dir}/uninstall_generic.sh" 1 0 << 'EOF'
#!/bin/sh
# ## Overview
# Generic uninstallation script for the __SCAF_NAME__ component.
# It provides fallback uninstallation logic and cross-platform removal steps
# when a more specific OS/distribution uninstall script is not available.
#
# ## Usage
# This script is typically called internally by the component lifecycle.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/uninstall_generic.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
EOF

  write_component_file "${_comp_dir}/uninstall_generic.cmd" 0 1 << 'EOF'
@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Generic uninstall script for __SCAF_NAME__ on Windows.
::
:: ## Usage
:: Routes to generic uninstallation via _common\uninstall_generic.cmd.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

if exist "%~dp0\..\..\_common\uninstall_generic.cmd" (
    call "%~dp0\..\..\_common\uninstall_generic.cmd" %*
)
EOF

  write_component_file "${_comp_dir}/test.sh" 1 0 << 'EOF'
#!/bin/sh
# ## Overview
# Test suite for the __SCAF_NAME__ component.
#
# ## Usage
# Execute this script to perform a component-specific smoke test.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

__SCAF_SMOKE_CMD__
EOF

  write_component_file "${_comp_dir}/test.cmd" 0 1 << 'EOF'
@echo off
:: # test.cmd
:: ## Overview
:: Test suite for the __SCAF_NAME__ component on Windows.
::
:: ## Usage
:: Execute this script to perform a component-specific smoke test.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

call "!SCRIPT_DIR!\env.cmd"
__SCAF_SMOKE_CMD__
EOF
}

# ## synthesize_readme
# Generates README.md with BEGIN_VARS and BEGIN_PLATFORMS markers for doc_coverage.sh.
synthesize_readme() {
  _comp_dir="$1"
  write_component_file "${_comp_dir}/README.md" 0 0 << 'EOF'
# __SCAF_NAME__

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `__SCAF_NAME__` component (part of `___SCAF_CATEGORY__`) within the LibScript ecosystem. __SCAF_DESCRIPTION__

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **__SCAF_TITLE__**. It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install __SCAF_NAME__
libscript uninstall __SCAF_NAME__
```

**Start / Stop (if configured as a background service):**

```sh
libscript start __SCAF_NAME__
libscript stop __SCAF_NAME__
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker __SCAF_NAME__
```

_Note: On Unix environments, you can also use `./cli.sh install __SCAF_NAME__`. On Windows, use `libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

<!-- BEGIN_VARS -->
| Variable | Description | Default | Aliases/Examples |
|---|---|---|---|
| `__COMP_PREFIX___INSTALL_METHOD` | How to install __SCAF_NAME__. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `__SCAF_INSTALL_METHOD__` | |
| `__COMP_PREFIX___VERSION` | Specific version of __SCAF_NAME__ to install. | `__SCAF_DEFAULT_VERSION__` | __SCAF_VERSION_ALIASES__ |
| `__COMP_PREFIX___DOWNLOAD_URL` | Override URL for downloading __SCAF_NAME__ binary or archive artifacts. | `none` | |
| `__COMP_PREFIX___RELEASES_URL` | Override URL for querying __SCAF_NAME__ available remote releases. | `none` | |
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic and native version manager operations.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->
EOF
}

# ## synthesize_optional_os_scripts
# Generates optional setup_<os>.sh and setup_<os>.cmd scripts when os_specific_scripts is provided.
synthesize_optional_os_scripts() {
  _comp_dir="$1"
  [ -z "$SCAF_OS_SCRIPTS" ] && return 0
  _oifs="$IFS"
  IFS=','
  for _os_target in $SCAF_OS_SCRIPTS; do
    _os_clean=$(printf '%s' "$_os_target" | tr -d '[:space:]')
    [ -z "$_os_clean" ] && continue
    write_component_file "${_comp_dir}/setup_${_os_clean}.sh" 1 0 '__OS_TARGET__' "$_os_clean" << 'EOF'
#!/bin/sh
# ## Overview
# OS-specific installation script (__OS_TARGET__) for the __SCAF_NAME__ component.
#
# ## Usage
# Called automatically by setup_base.sh on __OS_TARGET__ hosts.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SCRIPT_NAME="${SCRIPT_DIR}/setup_generic.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
EOF

    write_component_file "${_comp_dir}/setup_${_os_clean}.cmd" 0 1 '__OS_TARGET__' "$_os_clean" << 'EOF'
@echo off
:: # setup___OS_TARGET__.cmd
::
:: ## Overview
:: OS-specific setup script (__OS_TARGET__) for __SCAF_NAME__ on Windows.
::
:: ## Usage
:: Delegates to setup_generic.cmd on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

call "!SCRIPT_DIR!\setup_generic.cmd" %*
exit /b !errorlevel!
EOF
  done
  IFS="$_oifs"
}

# ## synthesize_optional_hooks
# Generates physical instance and logical multi-tenant hooks under hooks/ when requested.
synthesize_optional_hooks() {
  _comp_dir="$1"
  if [ "$SCAF_ENABLE_HOOKS" != 'true' ] && [ "$SCAF_MULTITENANT" != 'true' ]; then
    return 0
  fi

  _hook_list='configure probe announce log_stream metrics backup restore upgrade rollback maintenance'
  if [ "$SCAF_MULTITENANT" = 'true' ]; then
    _hook_list="${_hook_list} provision_tenant deprovision_tenant backup_tenant restore_tenant"
  fi

  for _hk in $_hook_list; do
    write_component_file "${_comp_dir}/hooks/${_hk}.sh" 1 0 '__HOOK_NAME__' "$_hk" << 'EOF'
#!/bin/sh
# ## Overview
# Lifecycle hook '__HOOK_NAME__' for the __SCAF_NAME__ component.
#
# ## Usage
# ./_lib/__SCAF_CATEGORY__/__SCAF_NAME__/hooks/__HOOK_NAME__.sh [args...]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/component_hook_impl.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

libscript_run_component_hook '__SCAF_NAME__' '__HOOK_NAME__' "$@"
EOF

    write_component_file "${_comp_dir}/hooks/${_hk}.cmd" 0 1 '__HOOK_NAME__' "$_hk" << 'EOF'
@echo off
:: # __HOOK_NAME__.cmd
::
:: ## Overview
:: Lifecycle hook '__HOOK_NAME__' for the __SCAF_NAME__ component on Windows.
::
:: ## Usage
:: hooks\__HOOK_NAME__.cmd [args...]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\component_hook_impl.cmd" "__SCAF_NAME__" "__HOOK_NAME__" %*
exit /b %errorlevel%
EOF
  done
}

# ## register_pkg_mappings
# Idempotently checks or logs native OS package mappings in _lib/_common/pkg_mapper.{sh,cmd}.
register_pkg_mappings() {
  if [ -z "$SCAF_PKG_APT" ] && [ -z "$SCAF_PKG_APK" ] && [ -z "$SCAF_PKG_DNF" ] && [ -z "$SCAF_PKG_PACMAN" ] && [ -z "$SCAF_PKG_BREW" ] && [ -z "$SCAF_PKG_WINGET" ] && [ -z "$SCAF_PKG_CHOCO" ] && [ -z "$SCAF_PKG_SCOOP" ] && [ -z "$SCAF_PKG_FREEBSD" ]; then
    return 0
  fi
  _mapper_sh="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mapper.sh"
  if [ -f "$_mapper_sh" ]; then
    if grep -Eq "^[[:space:]]*'${SCAF_NAME}'\)" "$_mapper_sh" 2>/dev/null; then
      printf '[SKIP] Package mapping for %s already present in _lib/_common/pkg_mapper.sh.\n' "$SCAF_NAME"
    else
      printf '[INFO] Custom pkg_mappings specified for %s (ready for _lib/_common/pkg_mapper.{sh,cmd}).\n' "$SCAF_NAME"
    fi
  fi
}

# Argument parsing
while [ $# -gt 0 ]; do
  case "$1" in
    scaffold|new-component)
      shift
      ;;
    --help|-h|/\?|-\?)
      show_scaffold_help
      exit 0
      ;;
    --interactive|-i)
      SCAF_MODE='interactive'
      shift
      ;;
    --non-interactive)
      SCAF_MODE='non-interactive'
      shift
      ;;
    --from-json=*)
      SCAF_FROM_JSON="${1#*=}"
      SCAF_MODE='json'
      shift
      ;;
    --from-json)
      shift
      SCAF_FROM_JSON="${1:-}"
      SCAF_MODE='json'
      shift
      ;;
    --export-json=*)
      SCAF_EXPORT_JSON="${1#*=}"
      shift
      ;;
    --export-json)
      shift
      SCAF_EXPORT_JSON="${1:-}"
      shift
      ;;
    --force|-f)
      SCAF_FORCE=1
      shift
      ;;
    --dry-run|-n)
      SCAF_DRY_RUN=1
      shift
      ;;
    --name=*)
      SCAF_NAME="${1#*=}"
      shift
      ;;
    --title=*)
      SCAF_TITLE="${1#*=}"
      shift
      ;;
    --category=*)
      SCAF_CATEGORY="${1#*=}"
      shift
      ;;
    --description=*)
      SCAF_DESCRIPTION="${1#*=}"
      shift
      ;;
    --binary-name=*)
      SCAF_BINARY_NAME="${1#*=}"
      shift
      ;;
    --install-method=*)
      SCAF_INSTALL_METHOD="${1#*=}"
      shift
      ;;
    --version-scheme=*)
      SCAF_VERSION_SCHEME="${1#*=}"
      shift
      ;;
    --github-repo=*)
      SCAF_GITHUB_REPO="${1#*=}"
      shift
      ;;
    --tag-prefix=*)
      SCAF_TAG_PREFIX="${1#*=}"
      shift
      ;;
    --url=*)
      SCAF_URL_UNIX="${1#*=}"
      shift
      ;;
    --win-url=*)
      SCAF_URL_WINDOWS="${1#*=}"
      shift
      ;;
    --releases-url=*)
      SCAF_RELEASES_URL="${1#*=}"
      shift
      ;;
    --os=*)
      SCAF_OS_WHITELIST="${1#*=}"
      shift
      ;;
    --os-blacklist=*)
      SCAF_OS_BLACKLIST="${1#*=}"
      shift
      ;;
    --arch=*)
      SCAF_ARCH_WHITELIST="${1#*=}"
      shift
      ;;
    --service)
      SCAF_IS_SERVICE='true'
      shift
      ;;
    --ports=*)
      SCAF_PORTS="${1#*=}"
      shift
      ;;
    --hooks)
      SCAF_ENABLE_HOOKS='true'
      shift
      ;;
    --multitenant)
      SCAF_MULTITENANT='true'
      shift
      ;;
    --os-scripts=*)
      SCAF_OS_SCRIPTS="${1#*=}"
      shift
      ;;
    --test-cmd=*)
      SCAF_TEST_CMD="${1#*=}"
      shift
      ;;
    *)
      printf '[ERROR] Unknown argument: %s\n' "$1" >&2
      show_scaffold_help >&2
      exit 1
      ;;
  esac
done

if [ "$SCAF_MODE" = 'json' ]; then
  parse_json_spec "$SCAF_FROM_JSON"
elif [ "$SCAF_MODE" = 'interactive' ]; then
  run_interactive_prompter
fi

# Validate and normalize defaults
validate_component_name "$SCAF_NAME"
validate_category_name "$SCAF_CATEGORY"
validate_os_list "$SCAF_OS_WHITELIST"
validate_os_list "$SCAF_OS_BLACKLIST"

[ -z "$SCAF_TITLE" ] && SCAF_TITLE="$SCAF_NAME"
[ -z "$SCAF_DESCRIPTION" ] && SCAF_DESCRIPTION="Installs and manages ${SCAF_TITLE} across supported platforms."
[ -z "$SCAF_PROVIDES" ] && SCAF_PROVIDES="$SCAF_NAME"
[ -z "$SCAF_BINARY_NAME" ] && SCAF_BINARY_NAME="$SCAF_NAME"
if [ -n "$SCAF_GITHUB_REPO" ]; then
  [ -z "$SCAF_REPOSITORY" ] && SCAF_REPOSITORY="https://github.com/${SCAF_GITHUB_REPO}"
  [ -z "$SCAF_RELEASES_URL" ] && SCAF_RELEASES_URL="https://api.github.com/repos/${SCAF_GITHUB_REPO}/releases/latest"
  [ -z "$SCAF_URL_UNIX" ] && SCAF_URL_UNIX="https://github.com/${SCAF_GITHUB_REPO}/releases/download/${SCAF_TAG_PREFIX}{VERSION}/${SCAF_NAME}-{VERSION}.tar.gz"
  [ -z "$SCAF_URL_WINDOWS" ] && SCAF_URL_WINDOWS="https://github.com/${SCAF_GITHUB_REPO}/releases/download/${SCAF_TAG_PREFIX}{VERSION}/${SCAF_NAME}-{VERSION}-windows.zip"
fi
[ -z "$SCAF_URL_UNIX" ] && SCAF_URL_UNIX="https://example.com/releases/${SCAF_NAME}-{VERSION}.tar.gz"
[ -z "$SCAF_URL_WINDOWS" ] && SCAF_URL_WINDOWS="https://example.com/releases/${SCAF_NAME}-{VERSION}-windows.zip"
[ -z "$SCAF_RELEASES_URL" ] && SCAF_RELEASES_URL="https://example.com/releases"
[ -z "$SCAF_TEST_CMD" ] && SCAF_TEST_CMD="${SCAF_BINARY_NAME} --version"

if [ -n "$SCAF_EXPORT_JSON" ]; then
  export_spec_to_json "$SCAF_EXPORT_JSON"
fi

COMP_TARGET_DIR="${LIBSCRIPT_ROOT_DIR}/_lib/${SCAF_CATEGORY}/${SCAF_NAME}"
COMP_PREFIX=$(compute_comp_prefix "$SCAF_NAME")

if [ "$SCAF_DRY_RUN" -eq 0 ]; then
  mkdir -p "$COMP_TARGET_DIR"
fi

synthesize_manifest_json "$COMP_TARGET_DIR"
synthesize_vars_schema_json "$COMP_TARGET_DIR" "$COMP_PREFIX"
synthesize_cli_scripts "$COMP_TARGET_DIR"
synthesize_setup_scripts "$COMP_TARGET_DIR"
synthesize_env_scripts "$COMP_TARGET_DIR"
synthesize_lifecycle_scripts "$COMP_TARGET_DIR"
synthesize_readme "$COMP_TARGET_DIR"
synthesize_optional_os_scripts "$COMP_TARGET_DIR"
synthesize_optional_hooks "$COMP_TARGET_DIR"
register_pkg_mappings

printf '[SUCCESS] Component %s/%s scaffolded at %s\n' "$SCAF_CATEGORY" "$SCAF_NAME" "$COMP_TARGET_DIR"
exit 0
