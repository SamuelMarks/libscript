#!/bin/sh
# ## Overview
# Runs native tests on the current host system across specified targets or categories
# without requiring Vagrant or virtual machines. Results and execution logs are captured
# into the tests_tmp directory.
#
# ## Usage
# ./tests/run_native_tests.sh [TARGETS...|all] [--category <category>] [--os <os_name>] [--dry-run] [--help]
# Examples:
#   ./tests/run_native_tests.sh sqlite curl
#   ./tests/run_native_tests.sh --category databases
#   ./tests/run_native_tests.sh all

set -e

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
THIS_DIR="${SCRIPT_DIR}"
: "${THIS_DIR}"
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

# ## show_help
# Displays usage instructions and supported CLI options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [TARGETS...|all] [--category <category>] [--os <os_name>] [--dry-run] [--help]"
  printf '%s
' ""
  printf '%s
' "Runs native tests on the current host across specified categories or components"
  printf '%s
' "to verify libscript installation and test commands directly."
  printf '%s
' ""
  printf '%s
' "Options:"
  printf '%s
' "  TARGETS...           One or more component names to test (e.g., sqlite redis)."
  printf '%s
' "  all                  Test all discovered components in _lib/."
  printf '%s
' "  --category <cat>     Test all components within a given category (e.g. databases)."
  printf '%s
' "  --os <os_name>       Manually specify target OS identifier (default: auto-detected)."
  printf '%s
' "  --dry-run            Simulate test execution without calling libscript install/test."
  printf '%s
' "  --help, -h, /?       Show this help message."
  printf '%s
' ""
  printf '%s
' "Outputs status files (*.success / *.failure) and logs into the tests_tmp/ directory."
}

# ## detect_host_os
# Determines the normalized OS identifier and log artifact tag.
detect_host_os() {
  _user_os="${1:-}"
  if [ -n "${_user_os}" ]; then
    case "${_user_os}" in
      'alpine'*|'apk') printf '%s %s
' "alpine" "linux.alpine" ;;
      'debian'*|'ubuntu'*|'deb') printf '%s %s
' "debian" "linux.debian" ;;
      'rhel'*|'centos'*|'fedora'*|'almalinux'*|'rpm'|'rocky'*) printf '%s %s\n' "rhel" "linux.rhel" ;;
      'freebsd'*|'bsd') printf '%s %s
' "freebsd" "freebsd" ;;
      'windows'*|'win') printf '%s %s
' "windows" "windows" ;;
      'darwin'*|'macos'*) printf '%s %s
' "darwin" "darwin" ;;
      'sunos'*|'solaris'*|'illumos'*|'omnios'*) printf '%s %s
' "sunos" "sunos" ;;
      *) printf '%s %s
' "${_user_os}" "${_user_os}" ;;
    esac
    return 0
  fi

  if [ -f "${REPO_ROOT}/_lib/_common/os_info.sh" ]; then
    # shellcheck disable=SC1090
    . "${REPO_ROOT}/_lib/_common/os_info.sh"
  fi

  _target="${TARGET_OS:-unknown}"
  case "${_target}" in
    'alpine') printf '%s %s
' "alpine" "linux.alpine" ;;
    'debian') printf '%s %s
' "debian" "linux.debian" ;;
    'rhel') printf '%s %s
' "rhel" "linux.rhel" ;;
    'freebsd') printf '%s %s
' "freebsd" "freebsd" ;;
    'windows'|'cygwin'|'mingw') printf '%s %s
' "windows" "windows" ;;
    'darwin'|'macOS'|'Mac OS X') printf '%s %s
' "darwin" "darwin" ;;
    'sunos'|'solaris'|'illumos'|'omnios') printf '%s %s
' "sunos" "sunos" ;;
    *)
      _raw_uname=$(uname -s 2>/dev/null || printf 'unknown')
      case "${_raw_uname}" in
        'FreeBSD') printf '%s %s
' "freebsd" "freebsd" ;;
        'Darwin') printf '%s %s
' "darwin" "darwin" ;;
        'SunOS') printf '%s %s
' "sunos" "sunos" ;;
        'Linux')
          if [ -f /etc/os-release ]; then
            # shellcheck disable=SC1091
            _dist_id=$(. /etc/os-release 2>/dev/null && printf '%s' "${ID:-linux}")
            case "${_dist_id}" in
              'alpine') printf '%s %s
' "alpine" "linux.alpine" ;;
              'debian'|'ubuntu') printf '%s %s
' "debian" "linux.debian" ;;
              'rhel'|'centos'|'fedora'|'almalinux'|'rocky'|'rockylinux') printf '%s %s\n' "rhel" "linux.rhel" ;;
              *) printf '%s %s
' "${_dist_id}" "linux.${_dist_id}" ;;
            esac
          else
            printf '%s %s
' "linux" "linux"
          fi
          ;;
        *) printf '%s %s
' "unknown" "unknown" ;;
      esac
      ;;
  esac
}

# ## check_manifest_support
# Validates whether a component supports the given OS using its manifest.json.
check_manifest_support() {
  _manifest_file="$1"
  _os_name="$2"

  if [ ! -f "${_manifest_file}" ]; then
    printf 'yes\n'
    return 0
  fi

  _os_family=""
  case "${_os_name}" in
    'alpine'|'debian'|'ubuntu'|'rhel'|'almalinux'|'centos'|'fedora'|'rocky'|'rockylinux'|'arch'|'gentoo'|'void'|'solus') _os_family="linux" ;;
    'freebsd'|'openbsd'|'netbsd') _os_family="bsd" ;;
    'windows') _os_family="windows" ;;
    'darwin') _os_family="darwin" ;;
    'sunos'|'solaris'|'illumos') _os_family="sunos" ;;
  esac

  awk -v os="${_os_name}" -v family="${_os_family}" '
    BEGIN { in_bl=0; in_wl=0; has_wl=0; wl_match=0; result="yes" }
    /"os_blacklist"\s*:/ {
      in_bl=1; in_wl=0
      if ($0 ~ "\"" os "\"" || (family != "" && $0 ~ "\"" family "\"")) { result="no"; exit }
      if ($0 ~ /\]/) { in_bl=0 }
      next
    }
    /"os_whitelist"\s*:/ {
      in_wl=1; in_bl=0; has_wl=1
      if ($0 ~ "\"" os "\"" || $0 ~ "\"all\"" || (family != "" && $0 ~ "\"" family "\"")) { wl_match=1 }
      if ($0 ~ /\]/) { in_wl=0 }
      next
    }
    in_bl {
      if ($0 ~ "\"" os "\"" || (family != "" && $0 ~ "\"" family "\"")) { result="no"; exit }
      if ($0 ~ /\]/) { in_bl=0 }
    }
    in_wl {
      if ($0 ~ "\"" os "\"" || $0 ~ "\"all\"" || (family != "" && $0 ~ "\"" family "\"")) { wl_match=1 }
      if ($0 ~ /\]/) { in_wl=0 }
    }
    END {
      if (result == "yes" && has_wl && !wl_match) {
        result="no"
      }
      print result
    }
  ' "${_manifest_file}"
}

# ## execute_test_target
# Runs the install and test lifecycle for a single target component and records output.
execute_test_target() {
  _target="$1"
  _os_id="$2"
  _os_tag="$3"
  _dry_run="$4"

  _manifest_path=$(find "${REPO_ROOT}/_lib" -maxdepth 2 -type d -name "${_target}" -exec echo "{}/manifest.json" \; 2>/dev/null | head -n 1)
  if [ -n "${_manifest_path}" ] && [ -f "${_manifest_path}" ]; then
    _is_supported=$(check_manifest_support "${_manifest_path}" "${_os_id}")
    if [ "${_is_supported}" = "no" ]; then
      printf 'Skipping %s (not supported on %s)
' "${_target}" "${_os_id}"
      return 0
    fi
  fi

  printf '============================================================
'
  printf 'Running native test for %s on %s (%s)...
' "${_target}" "${_os_id}" "${_os_tag}"
  printf '============================================================
'

  _stdout_file="${TESTS_TMP_DIR}/${_target}.${_os_tag}.stdout"
  _stderr_file="${TESTS_TMP_DIR}/${_target}.${_os_tag}.stderr"
  _success_file="${TESTS_TMP_DIR}/${_target}.${_os_tag}.success"
  _failure_file="${TESTS_TMP_DIR}/${_target}.${_os_tag}.failure"

  rm -f "${_success_file}" "${_failure_file}"

  if [ "${_dry_run}" = "1" ]; then
    printf 'Dry-run successful for %s on %s
' "${_target}" "${_os_id}" >"${_stdout_file}"
    : >"${_stderr_file}"
    printf 'Success
' >"${_success_file}"
    printf '[OK - DRY RUN] %s
' "${_target}"
    return 0
  fi

  _test_exit=0
  {
    export LIBSCRIPT_ROOT_DIR="${REPO_ROOT}"
    "${REPO_ROOT}/libscript.sh" install "${_target}"
    "${REPO_ROOT}/libscript.sh" test "${_target}"
  } >"${_stdout_file}" 2>"${_stderr_file}" || _test_exit=$?

  if [ "${_test_exit}" -eq 0 ]; then
    printf 'Success
' >"${_success_file}"
    printf '[OK] %s
' "${_target}"
  else
    printf 'Failure
' >"${_failure_file}"
    printf '[FAILED] %s (exit code %d)
' "${_target}" "${_test_exit}"
  fi
}

# ## main
# Coordinates CLI argument resolution, OS detection, execution loop, and reporting.
main() {
  _os_override=""
  _dry_run=0
  _targets=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h|/\?|-\?)
        show_help
        exit 0
        ;;
      --dry-run)
        _dry_run=1
        shift
        ;;
      --os)
        _os_override="$2"
        shift 2
        ;;
      --category)
        _cat="$2"
        if [ -d "${REPO_ROOT}/_lib/${_cat}" ]; then
          for _cdir in "${REPO_ROOT}/_lib/${_cat}"/*; do
            if [ -d "${_cdir}" ]; then
              _cname=$(basename "${_cdir}")
              case "${_cname}" in
                _*|"") ;;
                *) _targets="${_targets} ${_cname}" ;;
              esac
            fi
          done
        else
          printf 'Error: category "%s" not found under _lib/
' "${_cat}" >&2
          exit 1
        fi
        shift 2
        ;;
      all)
        for _cat_dir in "${REPO_ROOT}"/_lib/*; do
          if [ -d "${_cat_dir}" ]; then
            _cbase=$(basename "${_cat_dir}")
            case "${_cbase}" in
              _*|"") ;;
              *)
                for _comp_dir in "${_cat_dir}"/*; do
                  if [ -d "${_comp_dir}" ]; then
                    _comp_base=$(basename "${_comp_dir}")
                    case "${_comp_base}" in
                      _*|"") ;;
                      *) _targets="${_targets} ${_comp_base}" ;;
                    esac
                  fi
                done
                ;;
            esac
          fi
        done
        shift
        ;;
      *)
        _targets="${_targets} $1"
        shift
        ;;
    esac
  done

  TESTS_TMP_DIR="${REPO_ROOT}/tests_tmp"
  mkdir -p "${TESTS_TMP_DIR}"

  if [ -z "$(printf '%s' "${_targets}" | tr -d ' ')" ]; then
    _targets="databases languages toolchains"
  fi

  # Expand any category names given directly in targets
  _expanded_targets=""
  for _t in ${_targets}; do
    if [ -d "${REPO_ROOT}/_lib/${_t}" ]; then
      for _dir in "${REPO_ROOT}/_lib/${_t}"/*; do
        if [ -d "${_dir}" ]; then
          _b=$(basename "${_dir}")
          case "${_b}" in
            _*|"") ;;
            *) _expanded_targets="${_expanded_targets} ${_b}" ;;
          esac
        fi
      done
    else
      _expanded_targets="${_expanded_targets} ${_t}"
    fi
  done

  # Deduplicate targets
  _unique_targets=$(printf '%s
' ${_expanded_targets} | grep -v '^$' | sort -u)

  _os_info=$(detect_host_os "${_os_override}")
  _detected_os_id=$(printf '%s
' "${_os_info}" | awk '{print $1}')
  _detected_os_tag=$(printf '%s
' "${_os_info}" | awk '{print $2}')

  printf 'Target OS: %s (Tag: %s)
' "${_detected_os_id}" "${_detected_os_tag}"

  for _target in ${_unique_targets}; do
    execute_test_target "${_target}" "${_detected_os_id}" "${_detected_os_tag}" "${_dry_run}"
  done

  if [ -x "${THIS_DIR}/update_results.sh" ]; then
    "${THIS_DIR}/update_results.sh" "${REPO_ROOT}" || true
  fi

  printf 'All native tests complete. Results in %s
' "${TESTS_TMP_DIR}"
}

main "$@"
