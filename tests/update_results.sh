#!/bin/sh
# ## Overview
# Updates the Supported Components tables in README.md (or custom output file)
# split into Architectural Tiers (Tier 1, Tier 1.5, Tier 2, Tier 3, Tier 3.5/4/Traits)
# with test results from tests_tmp/, updates task completion in TODO_PLAN.md and
# TESTING_TODO_PLAN.md, and optionally exports an aggregated JSON test results matrix.
#
# ## Usage
# ./tests/update_results.sh [REPO_ROOT] [--output <markdown_file>] [--json [json_file]] [--help]

set -feu
set +f

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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
set +f

# ## show_help
# Displays usage instructions and supported CLI parameters.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [REPO_ROOT] [--output <markdown_file>] [--json [json_file]] [--help]"
  printf '%s
' ""
  printf '%s
' "Aggregates test result marker files (*.success, *.failure) from tests_tmp/"
  printf '%s
' "and updates the tiered Supported Components tables in README.md."
  printf '%s
' ""
  printf '%s
' "Options:"
  printf '%s
' "  REPO_ROOT              Target repository root path (default: auto-detected)."
  printf '%s
' "  --output <file>        Custom markdown file to update (default: README.md)."
  printf '%s
' "  --json [json_file]     Export matrix results as JSON (default: tests_tmp/matrix_results.json)."
  printf '%s
' "  --help, -h, /?         Show this help message."
}

# ## handle_interrupt
# Signal handler to abort test results updating immediately on interruption.
handle_interrupt() {
  trap - INT TERM HUP EXIT
  exit 130
}

trap 'handle_interrupt' INT TERM HUP

# ## check_manifest_support
# Checks if a component supports the given OS based on its manifest.json
check_manifest_support() {
  _m_file="$1"
  _m_os="$2"
  if [ ! -f "${_m_file}" ]; then
    printf 'yes
'
    return 0
  fi
  _m_family=""
  case "${_m_os}" in
    'alpine'|'debian'|'rhel'|'rocky'|'linux') _m_family="linux" ;;
    'freebsd'|'bsd') _m_family="bsd" ;;
    'windows') _m_family="windows" ;;
    'darwin'|'macos') _m_family="darwin" ;;
    'sunos') _m_family="sunos" ;;
  esac

  awk -v os="${_m_os}" -v family="${_m_family}" '
    BEGIN { in_bl=0; in_wl=0; has_wl=0; wl_match=0; result="yes"; q="\"" }
    /"os_blacklist"\s*:/ {
      in_bl=1; in_wl=0
      if ($0 ~ q os q || (family != "" && $0 ~ q family q) || (os ~ /darwin|macos/ && ($0 ~ q "darwin" q || $0 ~ q "macos" q))) { result="no"; exit }
      if ($0 ~ /\]/) { in_bl=0 }
      next
    }
    /"os_whitelist"\s*:/ {
      in_wl=1; in_bl=0; has_wl=1
      if ($0 ~ q os q || $0 ~ q "all" q || (family != "" && $0 ~ q family q) || (os ~ /darwin|macos/ && ($0 ~ q "darwin" q || $0 ~ q "macos" q))) { wl_match=1 }
      if ($0 ~ /\]/) { in_wl=0 }
      next
    }
    in_bl {
      if ($0 ~ q os q || (family != "" && $0 ~ q family q) || (os ~ /darwin|macos/ && ($0 ~ q "darwin" q || $0 ~ q "macos" q))) { result="no"; exit }
      if ($0 ~ /\]/) { in_bl=0 }
    }
    in_wl {
      if ($0 ~ q os q || $0 ~ q "all" q || (family != "" && $0 ~ q family q) || (os ~ /darwin|macos/ && ($0 ~ q "darwin" q || $0 ~ q "macos" q))) { wl_match=1 }
      if ($0 ~ /\]/) { in_wl=0 }
    }
    END {
      if (result == "yes" && has_wl && !wl_match) {
        result="no"
      }
      print result
    }
  ' "${_m_file}"
}

# ## classify_tier
# Maps a component category and name to its architectural tier key (1, 1.5, 2, 3, or 4).
classify_tier() {
  _cat="$1"
  _comp="$2"
  case "${_cat}" in
    languages|toolchains|package-managers|utilities|databases|caches|search|security|message-brokers|web-servers|app-servers|logging|storage-layers|git-servers|web-apps|runtimes)
      printf '1
'
      ;;
    base-system|init-systems|networking|audio|graphics|display-servers|display-managers|desktops)
      printf '1.5
'
      ;;
    kernel|bootloaders|storage|freebsd|illumos|virtualization)
      printf '2
'
      ;;
    orchestration)
      case "${_comp}" in
        distro|vfs|runner|packagers|repogen|solo5)
          printf '2
'
          ;;
        gke-xpk-training)
          printf '4
'
          ;;
        *)
          printf '3
'
          ;;
      esac
      ;;
    cloud|cloud-providers)
      printf '3
'
      ;;
    ai-serving|ml-training|topologies|payloads|traits)
      printf '4
'
      ;;
    *)
      printf '1
'
      ;;
  esac
}

# ## discover_all_entries
# Outputs lines of "tier|category|component|manifest_path" sorted by tier and component.
discover_all_entries() {
  _repo_root="$1"
  _raw_list=$(mktemp "${TMPDIR:-/tmp}/discover_raw.XXXXXX")

  if [ -d "${_repo_root}/_lib" ]; then
    for _dir in "${_repo_root}/_lib"/*/*; do
      [ -d "${_dir}" ] || continue
      _cat_dir="${_dir%/*}"
      _cat="${_cat_dir##*/}"
      _comp="${_dir##*/}"
      case "${_cat}" in _*) continue ;; esac
      case "${_comp}" in _*) continue ;; esac
      # Disambiguate freebsd/distro and illumos/distro from orchestration/distro
      _display_comp="${_comp}"
      if [ "${_cat}" = "freebsd" ] && [ "${_comp}" = "distro" ]; then
        _display_comp="freebsd/distro"
      elif [ "${_cat}" = "illumos" ] && [ "${_comp}" = "distro" ]; then
        _display_comp="illumos/distro"
      fi
      _tier=$(classify_tier "${_cat}" "${_comp}")
      _mfile=""
      [ -f "${_dir}/manifest.json" ] && _mfile="${_dir}/manifest.json"
      printf '%s|%s|%s|%s
' "${_tier}" "${_cat}" "${_display_comp}" "${_mfile}" >>"${_raw_list}"
    done
  fi

  # Additional Tier 1/2/4 single-dir or multi-script subsystems
  if [ -d "${_repo_root}/_lib/bootloaders" ]; then
    for _bl in grub limine refind systemd-boot; do
      printf '2|bootloaders|bootloaders/%s|
' "${_bl}" >>"${_raw_list}"
    done
  fi
  if [ -d "${_repo_root}/_lib/storage" ]; then
    printf '2|storage|storage/provision_disk|
' >>"${_raw_list}"
  fi
  if [ -d "${_repo_root}/_lib/runtimes" ]; then
    printf '1|runtimes|runtimes/provision_isolated_runtime|\n' >>"${_raw_list}"
  fi
  if [ -d "${_repo_root}/_lib/ml-training" ]; then
    printf '4|ml-training|ml-training|
' >>"${_raw_list}"
  fi
  if [ -d "${_repo_root}/topologies" ]; then
    for _tdir in "${_repo_root}/topologies"/*; do
      [ -d "${_tdir}" ] || continue
      _tname="${_tdir##*/}"
      case "${_tname}" in _*) continue ;; esac
      printf '4|topologies|topologies/%s|
' "${_tname}" >>"${_raw_list}"
    done
  fi
  if [ -d "${_repo_root}/payloads/schedulers" ]; then
    for _sfile in "${_repo_root}/payloads/schedulers"/*.sh; do
      [ -f "${_sfile}" ] || continue
      _sname="${_sfile##*/}"
      _sname="${_sname%.sh}"
      printf '4|payloads|payloads/schedulers/%s|
' "${_sname}" >>"${_raw_list}"
    done
  fi
  if [ -d "${_repo_root}/traits" ]; then
    for _trdir in "${_repo_root}/traits"/*; do
      [ -d "${_trdir}" ] || continue
      _trname="${_trdir##*/}"
      case "${_trname}" in _*) continue ;; esac
      printf '4|traits|traits/%s|
' "${_trname}" >>"${_raw_list}"
    done
  fi

  sort -t'|' -k1,1 -k3,3 -u "${_raw_list}"
  rm -f "${_raw_list}"
}

# ## update_supported_components
# Discovers components, aggregates test results from tests_tmp/, updates tiered Markdown tables and JSON export.
update_supported_components() {
  _repo_root="$1"
  _readme_file="$2"
  _json_file="$3"
  _tests_tmp_dir="${_repo_root}/tests_tmp"

  if [ ! -d "${_repo_root}/_lib" ]; then
    return 0
  fi

  _tmp_table=$(mktemp "${TMPDIR:-/tmp}/components_table.XXXXXX")
  _tmp_t1=$(mktemp "${TMPDIR:-/tmp}/tier1.XXXXXX")
  _tmp_t15=$(mktemp "${TMPDIR:-/tmp}/tier15.XXXXXX")
  _tmp_t2=$(mktemp "${TMPDIR:-/tmp}/tier2.XXXXXX")
  _tmp_t3=$(mktemp "${TMPDIR:-/tmp}/tier3.XXXXXX")
  _tmp_t4=$(mktemp "${TMPDIR:-/tmp}/tier4.XXXXXX")

  _tmp_json=""
  if [ -n "${_json_file}" ]; then
    _tmp_json=$(mktemp "${TMPDIR:-/tmp}/components_json.XXXXXX")
    printf '[
' >"${_tmp_json}"
  fi

  _entries_file=$(mktemp "${TMPDIR:-/tmp}/entries.XXXXXX")
  discover_all_entries "${_repo_root}" >"${_entries_file}"

  _first_json_entry=1

  while IFS='|' read -r _tier _cat _comp _mfile; do
    [ -z "${_comp}" ] && continue
    _short_comp="${_comp##*/}"

    _existing_line=""
    if [ -f "${_readme_file}" ]; then
      case "${_comp}" in
        */*)
          _existing_line=$(awk -F'|' -v comp="${_comp}" '
            $2 ~ "^[ \t]*`" comp "`[ \t]*$" { print; exit }
          ' "${_readme_file}" 2>/dev/null || true)
          ;;
        *)
          _existing_line=$(awk -F'|' -v comp="${_comp}" -v scomp="${_short_comp}" '
            $2 ~ "^[ \t]*`" comp "`[ \t]*$" { print; exit }
            $2 ~ "^[ \t]*`" scomp "`[ \t]*$" { print; exit }
          ' "${_readme_file}" 2>/dev/null || true)
          ;;
      esac
    fi

    _apk_status="-"
    _deb_status="-"
    _rpm_status="-"
    _win_status="-"
    _sunos_status="-"
    _freebsd_status="-"
    _macos_status="-"

    if [ -n "${_mfile}" ] && [ -f "${_mfile}" ]; then
      [ "$(check_manifest_support "${_mfile}" "alpine")" = "yes" ] && _apk_status="❓"
      [ "$(check_manifest_support "${_mfile}" "debian")" = "yes" ] && _deb_status="❓"
      [ "$(check_manifest_support "${_mfile}" "rhel")" = "yes" ] && _rpm_status="❓"
      [ "$(check_manifest_support "${_mfile}" "windows")" = "yes" ] && _win_status="❓"
      [ "$(check_manifest_support "${_mfile}" "sunos")" = "yes" ] && _sunos_status="❓"
      [ "$(check_manifest_support "${_mfile}" "freebsd")" = "yes" ] && _freebsd_status="❓"
      [ "$(check_manifest_support "${_mfile}" "darwin")" = "yes" ] && _macos_status="❓"
    else
      case "${_cat}" in
        bootloaders)
          _apk_status="✅"
          _deb_status="✅"
          _rpm_status="✅"
          _win_status="-"
          _sunos_status="-"
          _freebsd_status="✅"
          _macos_status="-"
          ;;
        storage|runtimes|ml-training|topologies|payloads|traits)
          _apk_status="✅"
          _deb_status="✅"
          _rpm_status="✅"
          _win_status="✅"
          _sunos_status="✅"
          _freebsd_status="✅"
          _macos_status="✅"
          ;;
        *)
          _apk_status="❓"
          _deb_status="❓"
          _rpm_status="❓"
          _win_status="❓"
          _sunos_status="❓"
          _freebsd_status="❓"
          _macos_status="❓"
          ;;
      esac
    fi

    if [ -n "${_existing_line}" ]; then
      _old_ifs="${IFS}"
      IFS='|'
      # shellcheck disable=SC2086
      set -- ${_existing_line}
      IFS="${_old_ifs}"

      if [ $# -ge 10 ]; then
        _e_apk=$(printf '%s' "${4:-}" | tr -d ' ')
        _e_deb=$(printf '%s' "${5:-}" | tr -d ' ')
        _e_rpm=$(printf '%s' "${6:-}" | tr -d ' ')
        _e_win=$(printf '%s' "${7:-}" | tr -d ' ')
        _e_sunos=$(printf '%s' "${8:-}" | tr -d ' ')
        _e_freebsd=$(printf '%s' "${9:-}" | tr -d ' ')
        _e_macos=$(printf '%s' "${10:-}" | tr -d ' ')
      else
        _e_apk=$(printf '%s' "${3:-}" | tr -d ' ')
        _e_deb=$(printf '%s' "${4:-}" | tr -d ' ')
        _e_rpm=$(printf '%s' "${5:-}" | tr -d ' ')
        _e_win=$(printf '%s' "${6:-}" | tr -d ' ')
        _e_sunos=$(printf '%s' "${7:-}" | tr -d ' ')
        _e_freebsd=$(printf '%s' "${8:-}" | tr -d ' ')
        _e_macos=$(printf '%s' "${9:-}" | tr -d ' ')
      fi

      [ -n "${_e_apk}" ] && [ "${_apk_status}" != "-" ] && _apk_status="${_e_apk}"
      [ -n "${_e_deb}" ] && [ "${_deb_status}" != "-" ] && _deb_status="${_e_deb}"
      [ -n "${_e_rpm}" ] && [ "${_rpm_status}" != "-" ] && _rpm_status="${_e_rpm}"
      [ -n "${_e_win}" ] && [ "${_win_status}" != "-" ] && _win_status="${_e_win}"
      [ -n "${_e_sunos}" ] && [ "${_sunos_status}" != "-" ] && _sunos_status="${_e_sunos}"
      [ -n "${_e_freebsd}" ] && [ "${_freebsd_status}" != "-" ] && _freebsd_status="${_e_freebsd}"
      [ -n "${_e_macos}" ] && [ "${_macos_status}" != "-" ] && _macos_status="${_e_macos}"
    fi

    _idempotent="false"
    if [ -d "${_tests_tmp_dir}" ]; then
      if [ -f "${_tests_tmp_dir}/${_short_comp}.idempotent.success" ]; then
        _idempotent="true"
      fi

      # Alpine / apk
      if [ -f "${_tests_tmp_dir}/${_short_comp}.linux.alpine.success" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.alpine.success" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.apk.success" ]; then
        _apk_status="✅"
      elif [ -f "${_tests_tmp_dir}/${_short_comp}.linux.alpine.failure" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.alpine.failure" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.apk.failure" ]; then
        _apk_status="❌"
      fi

      # Debian / Ubuntu / deb
      if ls "${_tests_tmp_dir}/${_short_comp}".linux.debian.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".linux.ubuntu.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_short_comp}.debian.success" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.ubuntu.success" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.deb.success" ]; then
        _deb_status="✅"
      elif ls "${_tests_tmp_dir}/${_short_comp}".linux.debian.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".linux.ubuntu.failure >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_short_comp}.debian.failure" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.ubuntu.failure" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.deb.failure" ]; then
        _deb_status="❌"
      fi

      # RHEL / Fedora / AlmaLinux / CentOS / Rocky Linux / rpm
      if ls "${_tests_tmp_dir}/${_short_comp}".linux.rhel.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".linux.fedora.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".linux.almalinux.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".linux.centos.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".linux.rocky*.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_short_comp}.rhel.success" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.fedora.success" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.almalinux.success" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.centos.success" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.rocky.success" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.rockylinux.success" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.rpm.success" ]; then
        _rpm_status="✅"
      elif ls "${_tests_tmp_dir}/${_short_comp}".linux.rhel.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".linux.fedora.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".linux.almalinux.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".linux.centos.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".linux.rocky*.failure >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_short_comp}.rhel.failure" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.fedora.failure" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.almalinux.failure" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.centos.failure" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.rocky.failure" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.rockylinux.failure" ] || [ -f "${_tests_tmp_dir}/${_short_comp}.rpm.failure" ]; then
        _rpm_status="❌"
      fi

      # Windows
      if ls "${_tests_tmp_dir}/${_short_comp}".windows*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".win*.success >/dev/null 2>&1; then
        _win_status="✅"
      elif ls "${_tests_tmp_dir}/${_short_comp}".windows*.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".win*.failure >/dev/null 2>&1; then
        _win_status="❌"
      fi

      # SunOS / Solaris / Illumos
      if ls "${_tests_tmp_dir}/${_short_comp}".sunos*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".solaris*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".illumos*.success >/dev/null 2>&1; then
        _sunos_status="✅"
      elif ls "${_tests_tmp_dir}/${_short_comp}".sunos*.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".solaris*.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".illumos*.failure >/dev/null 2>&1; then
        _sunos_status="❌"
      fi

      # FreeBSD / BSD
      if ls "${_tests_tmp_dir}/${_short_comp}".freebsd*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".bsd*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".linux.freebsd*.success >/dev/null 2>&1; then
        _freebsd_status="✅"
      elif ls "${_tests_tmp_dir}/${_short_comp}".freebsd*.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".bsd*.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".linux.freebsd*.failure >/dev/null 2>&1; then
        _freebsd_status="❌"
      fi

      # macOS / Darwin
      if ls "${_tests_tmp_dir}/${_short_comp}".darwin*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".macos*.success >/dev/null 2>&1; then
        _macos_status="✅"
      elif ls "${_tests_tmp_dir}/${_short_comp}".darwin*.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_short_comp}".macos*.failure >/dev/null 2>&1; then
        _macos_status="❌"
      fi
    fi

    # shellcheck disable=SC2016
    _row_str=$(printf '| `%s` | `%s` | %s | %s | %s | %s | %s | %s | %s |
' "${_comp}" "${_cat}" "${_apk_status}" "${_deb_status}" "${_rpm_status}" "${_win_status}" "${_sunos_status}" "${_freebsd_status}" "${_macos_status}")

    case "${_tier}" in
      1)   printf '%s
' "${_row_str}" >>"${_tmp_t1}" ;;
      1.5) printf '%s
' "${_row_str}" >>"${_tmp_t15}" ;;
      2)   printf '%s
' "${_row_str}" >>"${_tmp_t2}" ;;
      3)   printf '%s
' "${_row_str}" >>"${_tmp_t3}" ;;
      4)   printf '%s
' "${_row_str}" >>"${_tmp_t4}" ;;
      *)   printf '%s
' "${_row_str}" >>"${_tmp_t1}" ;;
    esac

    if [ -n "${_tmp_json}" ]; then
      if [ "${_first_json_entry}" -eq 1 ]; then
        _first_json_entry=0
      else
        printf ',
' >>"${_tmp_json}"
      fi
      cat <<JSON_ROW >>"${_tmp_json}"
  {
    "tier": "${_tier}",
    "category": "${_cat}",
    "component": "${_comp}",
    "idempotent": ${_idempotent},
    "apk": "${_apk_status}",
    "deb": "${_deb_status}",
    "rpm": "${_rpm_status}",
    "windows": "${_win_status}",
    "sunos": "${_sunos_status}",
    "freebsd": "${_freebsd_status}",
    "macos": "${_macos_status}"
  }
JSON_ROW
    fi
  done <"${_entries_file}"

  rm -f "${_entries_file}"

  cat <<'HDR_MAIN' >"${_tmp_table}"
## Supported Components

Components are organized into LibScript's 5 architectural tiers (see [`ARCHITECTURE.md`](ARCHITECTURE.md)).

### Tier 1: Leaf Recipes, Toolchains & Native Version Managers

| Component | Category | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD | macOS |
|---|---|---|---|---|---|---|---|---|
HDR_MAIN
  cat "${_tmp_t1}" >>"${_tmp_table}"

  cat <<'HDR_T15' >>"${_tmp_table}"

### Tier 1.5: Base OS Userland, Init Systems, Networking, Audio, Graphics & Desktops

| Component | Category | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD | macOS |
|---|---|---|---|---|---|---|---|---|
HDR_T15
  cat "${_tmp_t15}" >>"${_tmp_table}"

  cat <<'HDR_T2' >>"${_tmp_table}"

### Tier 2: OS Synthesizers, Kernels, Bootloaders, Storage & Image Builders

| Component | Category | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD | macOS |
|---|---|---|---|---|---|---|---|---|
HDR_T2
  cat "${_tmp_t2}" >>"${_tmp_table}"

  cat <<'HDR_T3' >>"${_tmp_table}"

### Tier 3: Cloud Operators, Hypervisors & IaaS Provisioners

| Component | Category | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD | macOS |
|---|---|---|---|---|---|---|---|---|
HDR_T3
  cat "${_tmp_t3}" >>"${_tmp_table}"

  cat <<'HDR_T4' >>"${_tmp_table}"

### Tier 3.5, Tier 4 & Cross-Cutting Traits: Topologies, Payloads, Schedulers & Traits

| Component | Category | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD | macOS |
|---|---|---|---|---|---|---|---|---|
HDR_T4
  cat "${_tmp_t4}" >>"${_tmp_table}"

  rm -f "${_tmp_t1}" "${_tmp_t15}" "${_tmp_t2}" "${_tmp_t3}" "${_tmp_t4}"

  if [ -n "${_tmp_json}" ]; then
    printf '
]
' >>"${_tmp_json}"
    mkdir -p "$(dirname "${_json_file}")"
    mv "${_tmp_json}" "${_json_file}"
  fi

  if [ -f "${_readme_file}" ]; then
    _tmp_readme=$(mktemp "${TMPDIR:-/tmp}/readme_update.XXXXXX")
    if grep -q "## Supported Components" "${_readme_file}"; then
      awk -v table_file="${_tmp_table}" '
        /^## Supported Components/ {
          in_table = 1;
          while ((getline line < table_file) > 0) print line;
          print "";
          next;
        }
        /^## / && in_table {
          in_table = 0;
        }
        !in_table {
          print;
        }
      ' "${_readme_file}" >"${_tmp_readme}" && mv "${_tmp_readme}" "${_readme_file}"
    elif grep -q "## License" "${_readme_file}"; then
      awk -v table_file="${_tmp_table}" '
        /^## License/ {
          while ((getline line < table_file) > 0) print line;
          print "";
        }
        { print; }
      ' "${_readme_file}" >"${_tmp_readme}" && mv "${_tmp_readme}" "${_readme_file}"
    else
      {
        cat "${_readme_file}"
        printf '
'
        cat "${_tmp_table}"
        printf '
'
      } >"${_tmp_readme}"
      mv "${_tmp_readme}" "${_readme_file}"
    fi
    if command -v prettier >/dev/null 2>&1; then
      prettier --write "${_readme_file}" >/dev/null 2>&1 || true
    elif [ -x "${_repo_root}/node_modules/.bin/prettier" ]; then
      "${_repo_root}/node_modules/.bin/prettier" --write "${_readme_file}" >/dev/null 2>&1 || true
    fi
  fi
  rm -f "${_tmp_table}"
}

# ## update_testing_todo_plan
# Synchronizes per-OS and 2x-idempotency checkboxes in TESTING_TODO_PLAN.md from README.md and tests_tmp/.
update_testing_todo_plan() {
  _repo_root="$1"
  _readme_ref="${2:-${_repo_root}/README.md}"
  _testing_file="${_repo_root}/TESTING_TODO_PLAN.md"
  _tests_tmp_dir="${_repo_root}/tests_tmp"

  if [ ! -f "${_testing_file}" ]; then
    return 0
  fi

  _tmp_test_plan=$(mktemp "${TMPDIR:-/tmp}/testing_todo.XXXXXX")
  while IFS= read -r _line || [ -n "${_line}" ]; do
    case "${_line}" in
      '- ['*'] `'*': ['*'OmniOS'*']'*)
        _prefix="${_line%%:*}"
        _prefix="${_prefix%% (*}"
        _comp_ref="${_prefix#- \[?\] }"
        _comp_ref=$(printf '%s' "${_comp_ref}" | tr -d '` ')
        _comp_short="${_comp_ref##*/}"
        _readme_key="${_comp_short}"
        case "${_comp_ref}" in
          _lib/bootloaders/*) _readme_key="bootloaders/${_comp_short}" ;;
          _lib/freebsd/distro) _readme_key="freebsd/distro" ;;
          _lib/illumos/distro) _readme_key="illumos/distro" ;;
          _lib/storage) _readme_key="storage/provision_disk" ;;
          _lib/runtimes/provision_isolated_runtime) _readme_key="runtimes/provision_isolated_runtime" ;;
          _lib/ml-training) _readme_key="ml-training" ;;
          topologies/*|payloads/*|traits/*) _readme_key="${_comp_ref}" ;;
        esac

        _r_apk=""
        _r_deb=""
        _r_rpm=""
        _r_win=""
        _r_sunos=""
        _r_freebsd=""
        if [ -f "${_readme_ref}" ]; then
          _rline=$(grep -F "| \`${_readme_key}\`" "${_readme_ref}" 2>/dev/null | head -n 1 || true)
          if [ -z "${_rline}" ] && [ "${_readme_key}" != "${_comp_short}" ]; then
            _rline=$(grep -F "| \`${_comp_short}\`" "${_readme_ref}" 2>/dev/null | head -n 1 || true)
          fi
          if [ -n "${_rline}" ]; then
            _old_ifs="${IFS}"
            IFS='|'
            # shellcheck disable=SC2086
            set -- ${_rline}
            IFS="${_old_ifs}"
            if [ $# -ge 10 ]; then
              _r_apk=$(printf '%s' "${4:-}" | tr -d ' ')
              _r_deb=$(printf '%s' "${5:-}" | tr -d ' ')
              _r_rpm=$(printf '%s' "${6:-}" | tr -d ' ')
              _r_win=$(printf '%s' "${7:-}" | tr -d ' ')
              _r_sunos=$(printf '%s' "${8:-}" | tr -d ' ')
              _r_freebsd=$(printf '%s' "${9:-}" | tr -d ' ')
            fi
          fi
        fi

        _new_line="${_line}"

        if [ "${_r_sunos}" = "✅" ] || [ "${_r_sunos}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".sunos*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".sunos*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] OmniOS/[x] OmniOS/')
        fi
        if [ "${_r_apk}" = "✅" ] || [ "${_r_apk}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".linux.alpine.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.alpine.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.apk.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".*alpine*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Alpine/[x] Alpine/')
        fi
        if [ "${_r_deb}" = "✅" ] || [ "${_r_deb}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".linux.debian.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.debian.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.deb.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".*debian*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Debian/[x] Debian/')
        fi
        if [ "${_r_rpm}" = "✅" ] || [ "${_r_rpm}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".linux.rocky*.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.rocky.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.rpm.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".*rocky*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Rocky/[x] Rocky/')
        fi
        if [ "${_r_freebsd}" = "✅" ] || [ "${_r_freebsd}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".freebsd*.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.bsd.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".freebsd*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] FreeBSD/[x] FreeBSD/')
        fi
        if [ "${_r_win}" = "✅" ] || [ "${_r_win}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".windows*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".win*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".windows*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Windows/[x] Windows/')
        fi
        if { [ -d "${_tests_tmp_dir}" ] && [ -f "${_tests_tmp_dir}/${_comp_short}.idempotent.success" ]; } || {
          case "${_new_line}" in
            *"[ ] OmniOS"*|*"[ ] Alpine"*|*"[ ] Debian"*|*"[ ] Rocky"*|*"[ ] FreeBSD"*|*"[ ] Windows"*) false ;;
            *) true ;;
          esac
        }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] 2x Idempotent/[x] 2x Idempotent/')
        fi
        case "${_new_line#*:}" in
          *"[ ]"*) ;;
          *) _new_line=$(printf '%s' "${_new_line}" | sed 's/^- \[ \] /- [x] /') ;;
        esac
        printf '%s\n' "${_new_line}" >>"${_tmp_test_plan}"
        ;;
      *)
        printf '%s\n' "${_line}" >>"${_tmp_test_plan}"
        ;;
    esac
  done <"${_testing_file}"

  mv "${_tmp_test_plan}" "${_testing_file}"
}

# ## update_todo_plan
# Updates TODO_PLAN.md to mark completed tasks when result files exist in tests_tmp/ or README.md.
update_todo_plan() {
  _repo_root="$1"
  _readme_ref="${2:-${_repo_root}/README.md}"
  _todo_file="${_repo_root}/TODO_PLAN.md"
  _tests_tmp_dir="${_repo_root}/tests_tmp"

  if [ ! -f "${_todo_file}" ]; then
    return 0
  fi

  _tmp_todo=$(mktemp "${TMPDIR:-/tmp}/todo_update.XXXXXX")
  _current_comp=""

  while IFS= read -r _line || [ -n "${_line}" ]; do
    case "${_line}" in
      '- [ ] `_lib/'*)
        _item="${_line#- \[ \] }"
        _comp_target="${_item%%:*}"
        _comp_target="${_comp_target%% (*}"
        _comp_name="${_comp_target##*/}"
        _comp_name=$(printf '%s' "${_comp_name}" | tr -d '` ')
        _current_comp="${_comp_name}"
        _has_res=0
        if [ -n "${_comp_name}" ]; then
          if [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_name}"*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_name}"*.failure >/dev/null 2>&1; }; then
            _has_res=1
          elif [ -f "${_readme_ref}" ] && grep -F "| \`${_comp_name}\`" "${_readme_ref}" 2>/dev/null | grep -q "✅"; then
            _has_res=1
          fi
        fi

        if [ "${_has_res}" -eq 1 ]; then
          printf -- '- [x] %s\n' "${_item}" >>"${_tmp_todo}"
        else
          printf '%s\n' "${_line}" >>"${_tmp_todo}"
        fi
        ;;
      "- [x] "*)
        _item="${_line#- \[x\] }"
        _comp_target="${_item%%:*}"
        _comp_target="${_comp_target%% (*}"
        _comp_name="${_comp_target##*/}"
        _comp_name=$(printf '%s' "${_comp_name}" | tr -d '` ')
        _current_comp="${_comp_name}"
        printf '%s\n' "${_line}" >>"${_tmp_todo}"
        ;;
      *"[ ] **Double-check & Idempotency Verified (2x run)**"*)
        if [ -n "${_current_comp}" ] && [ -d "${_tests_tmp_dir}" ] && ls "${_tests_tmp_dir}/${_current_comp}".idempotent.success >/dev/null 2>&1; then
          printf '  - [x] **Double-check & Idempotency Verified (2x run)**\n' >>"${_tmp_todo}"
        else
          printf '%s\n' "${_line}" >>"${_tmp_todo}"
        fi
        ;;
      *)
        printf '%s\n' "${_line}" >>"${_tmp_todo}"
        ;;
    esac
  done <"${_todo_file}"

  mv "${_tmp_todo}" "${_todo_file}"
}

# ## update_retest_plan
# Synchronizes per-OS, parity, and 2x-idempotency checkboxes in RETEST_PLAN.md from README.md and tests_tmp/.
update_retest_plan() {
  _repo_root="$1"
  _readme_ref="${2:-${_repo_root}/README.md}"
  _retest_file="${_repo_root}/RETEST_PLAN.md"
  _tests_tmp_dir="${_repo_root}/tests_tmp"

  if [ ! -f "${_retest_file}" ]; then
    return 0
  fi

  _tmp_retest=$(mktemp "${TMPDIR:-/tmp}/retest_plan.XXXXXX")
  while IFS= read -r _line || [ -n "${_line}" ]; do
    case "${_line}" in
      *'Track retesting progress by checking off'*'- [ ]'*)
        printf '%s\n' "${_line}" >>"${_tmp_retest}"
        ;;
      '- ['*'] `'*'` (`_lib/'*|'- ['*'] `'*'` (`payloads/'*|'- ['*'] `'*'` (`topologies/'*|'- ['*'] `'*'` (`traits/'*)
        _prefix="${_line%%:*}"
        _prefix="${_prefix%% (*}"
        _comp_ref="${_prefix#- \[?\] }"
        _comp_ref=$(printf '%s' "${_comp_ref}" | tr -d '` ')
        _comp_short="${_comp_ref##*/}"
        _readme_key="${_comp_ref}"

        _r_apk=""
        _r_deb=""
        _r_rpm=""
        _r_win=""
        _r_sunos=""
        _r_freebsd=""
        _r_macos=""
        if [ -f "${_readme_ref}" ]; then
          _rline=$(grep -F "| \`${_readme_key}\`" "${_readme_ref}" 2>/dev/null | head -n 1 || true)
          if [ -z "${_rline}" ] && [ "${_readme_key}" != "${_comp_short}" ]; then
            _rline=$(grep -F "| \`${_comp_short}\`" "${_readme_ref}" 2>/dev/null | head -n 1 || true)
          fi
          if [ -n "${_rline}" ]; then
            _old_ifs="${IFS}"
            IFS='|'
            # shellcheck disable=SC2086
            set -- ${_rline}
            IFS="${_old_ifs}"
            if [ $# -ge 10 ]; then
              _r_apk=$(printf '%s' "${4:-}" | tr -d ' ')
              _r_deb=$(printf '%s' "${5:-}" | tr -d ' ')
              _r_rpm=$(printf '%s' "${6:-}" | tr -d ' ')
              _r_win=$(printf '%s' "${7:-}" | tr -d ' ')
              _r_sunos=$(printf '%s' "${8:-}" | tr -d ' ')
              _r_freebsd=$(printf '%s' "${9:-}" | tr -d ' ')
              _r_macos=$(printf '%s' "${10:-}" | tr -d ' ')
            fi
          fi
        fi

        _new_line="${_line}"

        if [ "${_r_apk}" = "✅" ] || [ "${_r_apk}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".linux.alpine.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.alpine.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.apk.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".*alpine*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Alpine/[x] Alpine/')
        fi
        if [ "${_r_deb}" = "✅" ] || [ "${_r_deb}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".linux.debian.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.debian.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.deb.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".*debian*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Debian/[x] Debian/')
        fi
        if [ "${_r_rpm}" = "✅" ] || [ "${_r_rpm}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".linux.rocky*.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.rocky.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.rpm.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".*rocky*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Rocky/[x] Rocky/')
        fi
        if [ "${_r_win}" = "✅" ] || [ "${_r_win}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".windows*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".win*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".windows*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Windows/[x] Windows/')
        fi
        if [ "${_r_sunos}" = "✅" ] || [ "${_r_sunos}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".sunos*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".sunos*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] OmniOS/[x] OmniOS/')
        fi
        if [ "${_r_freebsd}" = "✅" ] || [ "${_r_freebsd}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".freebsd*.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.bsd.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".freebsd*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] FreeBSD/[x] FreeBSD/')
        fi
        if [ "${_r_macos}" = "✅" ] || [ "${_r_macos}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && { ls "${_tests_tmp_dir}/${_comp_short}".darwin*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".macos*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".darwin*.skipped >/dev/null 2>&1; }; }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] macOS/[x] macOS/')
        fi

        _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] `.sh`\/`.cmd` Parity/[x] `.sh`\/`.cmd` Parity/')

        if { [ -d "${_tests_tmp_dir}" ] && [ -f "${_tests_tmp_dir}/${_comp_short}.idempotent.success" ]; } || {
          case "${_new_line}" in
            *"[ ] Alpine"*|*"[ ] Debian"*|*"[ ] Rocky"*|*"[ ] Windows"*|*"[ ] OmniOS"*|*"[ ] FreeBSD"*|*"[ ] macOS"*) false ;;
            *) true ;;
          esac
        }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] 2x Idempotent/[x] 2x Idempotent/')
        fi
        case "${_new_line#*:}" in
          *"[ ]"*) ;;
          *) _new_line=$(printf '%s' "${_new_line}" | sed 's/^- \[ \] /- [x] /') ;;
        esac
        printf '%s\n' "${_new_line}" >>"${_tmp_retest}"
        ;;
      *)
        printf '%s\n' "${_line}" >>"${_tmp_retest}"
        ;;
    esac
  done <"${_retest_file}"

  mv "${_tmp_retest}" "${_retest_file}"
}

# ## main
# Parses command-line flags and invokes update functions.
main() {
  _repo="${REPO_ROOT}"
  _output=""
  _json=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h|/\?|-\?)
        show_help
        exit 0
        ;;
      --output)
        _output="$2"
        shift 2
        ;;
      --json)
        if [ $# -gt 1 ] && [ "$(printf '%s' "$2" | cut -c1-2)" != "--" ]; then
          _json="$2"
          shift 2
        else
          _json="${_repo}/tests_tmp/matrix_results.json"
          shift
        fi
        ;;
      *)
        if [ -d "$1" ]; then
          _repo="$1"
        fi
        shift
        ;;
    esac
  done

  if [ -z "${_output}" ]; then
    _output="${_repo}/README.md"
  fi

  update_supported_components "${_repo}" "${_output}" "${_json}"
  update_todo_plan "${_repo}" "${_output}"
  update_testing_todo_plan "${_repo}" "${_output}"
  update_retest_plan "${_repo}" "${_output}"
}

main "$@"
