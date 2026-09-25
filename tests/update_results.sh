#!/bin/sh
# ## Overview
# Updates the Supported Components table in README.md (or custom output file)
# with test results from tests_tmp/, updates task completion in TODO_PLAN.md if present,
# and optionally exports an aggregated JSON test results matrix.
#
# ## Usage
# ./tests/update_results.sh [REPO_ROOT] [--output <markdown_file>] [--json [json_file]] [--help]

set -eu

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
# Displays usage instructions and supported CLI parameters.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [REPO_ROOT] [--output <markdown_file>] [--json [json_file]] [--help]"
  printf '%s
' ""
  printf '%s
' "Aggregates test result marker files (*.success, *.failure) from tests_tmp/"
  printf '%s
' "and updates the Supported Components table in README.md."
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

# ## check_manifest_support
# Checks if a component supports the given OS based on its manifest.json
check_manifest_support() {
  _m_file="$1"
  _m_os="$2"
  if [ ! -f "${_m_file}" ]; then
    printf 'yes\n'
    return 0
  fi
  _m_family=""
  case "${_m_os}" in
    'alpine'|'debian'|'rhel'|'rocky'|'linux') _m_family="linux" ;;
    'freebsd'|'bsd') _m_family="bsd" ;;
    'windows') _m_family="windows" ;;
    'darwin') _m_family="darwin" ;;
    'sunos') _m_family="sunos" ;;
  esac

  awk -v os="${_m_os}" -v family="${_m_family}" '
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
  ' "${_m_file}"
}

# ## update_supported_components
# Discovers components, aggregates test results from tests_tmp/, updates Markdown file and JSON export.
update_supported_components() {
  _repo_root="$1"
  _readme_file="$2"
  _json_file="$3"
  _tests_tmp_dir="${_repo_root}/tests_tmp"

  if [ ! -d "${_repo_root}/_lib" ]; then
    return 0
  fi

  _tmp_table=$(mktemp "${TMPDIR:-/tmp}/components_table.XXXXXX")
  _tmp_json=""
  if [ -n "${_json_file}" ]; then
    _tmp_json=$(mktemp "${TMPDIR:-/tmp}/components_json.XXXXXX")
    printf '[
' >"${_tmp_json}"
  fi

  cat <<'TABLE_HDR' >"${_tmp_table}"
## Supported Components

| Component | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD |
|---|---|---|---|---|---|---|
TABLE_HDR

  # Discover components under _lib/<cat>/<comp> and stacks/<cat>/<comp> excluding dirs starting with '_'
  _search_dirs=""
  [ -d "${_repo_root}/_lib" ] && _search_dirs="${_search_dirs} _lib"
  [ -d "${_repo_root}/stacks" ] && _search_dirs="${_search_dirs} stacks"
  # shellcheck disable=SC2086
  _components=$(cd "${_repo_root}" && find ${_search_dirs} -mindepth 2 -maxdepth 2 -type d ! -path "*/_*" ! -name "_*" 2>/dev/null | sed 's|.*/||' | sort -u)
  _first_json_entry=1

  for _comp in ${_components}; do
    [ -z "${_comp}" ] && continue

    _existing_line=""
    if [ -f "${_readme_file}" ]; then
      _existing_line=$(awk -v comp="${_comp}" '$2 == "`"comp"`" { print; exit }' "${_readme_file}" 2>/dev/null || true)
    fi

    _apk_status="-"
    _deb_status="-"
    _rpm_status="-"
    _win_status="-"
    _sunos_status="-"
    _freebsd_status="-"

    _mfile=""
    for _candidate in "${_repo_root}/_lib"/*/"${_comp}/manifest.json" "${_repo_root}/stacks"/*/"${_comp}/manifest.json"; do
      if [ -f "${_candidate}" ]; then
        _mfile="${_candidate}"
        break
      fi
    done
    if [ -f "${_mfile}" ]; then
      [ "$(check_manifest_support "${_mfile}" "alpine")" = "yes" ] && _apk_status="❓"
      [ "$(check_manifest_support "${_mfile}" "debian")" = "yes" ] && _deb_status="❓"
      [ "$(check_manifest_support "${_mfile}" "rhel")" = "yes" ] && _rpm_status="❓"
      [ "$(check_manifest_support "${_mfile}" "windows")" = "yes" ] && _win_status="❓"
      [ "$(check_manifest_support "${_mfile}" "sunos")" = "yes" ] && _sunos_status="❓"
      [ "$(check_manifest_support "${_mfile}" "freebsd")" = "yes" ] && _freebsd_status="❓"
    else
      _apk_status="❓"
      _deb_status="❓"
      _rpm_status="❓"
      _win_status="❓"
      _sunos_status="❓"
      _freebsd_status="❓"
    fi

    if [ -n "${_existing_line}" ]; then
      _old_ifs="${IFS}"
      IFS='|'
      # shellcheck disable=SC2086
      set -- ${_existing_line}
      IFS="${_old_ifs}"

      _e_apk=$(printf '%s' "${3:-}" | tr -d ' ')
      _e_deb=$(printf '%s' "${4:-}" | tr -d ' ')
      _e_rpm=$(printf '%s' "${5:-}" | tr -d ' ')
      _e_win=$(printf '%s' "${6:-}" | tr -d ' ')
      _e_sunos=$(printf '%s' "${7:-}" | tr -d ' ')
      _e_freebsd=$(printf '%s' "${8:-}" | tr -d ' ')

      [ -n "${_e_apk}" ] && [ "${_apk_status}" != "-" ] && _apk_status="${_e_apk}"
      [ -n "${_e_deb}" ] && [ "${_deb_status}" != "-" ] && _deb_status="${_e_deb}"
      [ -n "${_e_rpm}" ] && [ "${_rpm_status}" != "-" ] && _rpm_status="${_e_rpm}"
      [ -n "${_e_win}" ] && [ "${_win_status}" != "-" ] && _win_status="${_e_win}"
      [ -n "${_e_sunos}" ] && [ "${_sunos_status}" != "-" ] && _sunos_status="${_e_sunos}"
      [ -n "${_e_freebsd}" ] && [ "${_freebsd_status}" != "-" ] && _freebsd_status="${_e_freebsd}"
    fi

    if [ -d "${_tests_tmp_dir}" ]; then
      # Alpine / apk
      if [ -f "${_tests_tmp_dir}/${_comp}.linux.alpine.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.alpine.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.apk.success" ]; then
        _apk_status="✅"
      elif [ -f "${_tests_tmp_dir}/${_comp}.linux.alpine.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.alpine.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.apk.failure" ]; then
        _apk_status="❌"
      fi

      # Debian / Ubuntu / deb
      if ls "${_tests_tmp_dir}/${_comp}".linux.debian.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.ubuntu.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp}.debian.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.ubuntu.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.deb.success" ]; then
        _deb_status="✅"
      elif ls "${_tests_tmp_dir}/${_comp}".linux.debian.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.ubuntu.failure >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp}.debian.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.ubuntu.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.deb.failure" ]; then
        _deb_status="❌"
      fi

      # RHEL / Fedora / AlmaLinux / CentOS / Rocky Linux / rpm
      if ls "${_tests_tmp_dir}/${_comp}".linux.rhel.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.fedora.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.almalinux.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.centos.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.rocky*.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp}.rhel.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.fedora.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.almalinux.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.centos.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.rocky.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.rockylinux.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.rpm.success" ]; then
        _rpm_status="✅"
      elif ls "${_tests_tmp_dir}/${_comp}".linux.rhel.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.fedora.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.almalinux.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.centos.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.rocky*.failure >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp}.rhel.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.fedora.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.almalinux.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.centos.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.rocky.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.rockylinux.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.rpm.failure" ]; then
        _rpm_status="❌"
      fi

      # Windows
      if ls "${_tests_tmp_dir}/${_comp}".windows*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".win*.success >/dev/null 2>&1; then
        _win_status="✅"
      elif ls "${_tests_tmp_dir}/${_comp}".windows*.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".win*.failure >/dev/null 2>&1; then
        _win_status="❌"
      fi

      # SunOS / Solaris / Illumos
      if ls "${_tests_tmp_dir}/${_comp}".sunos*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".solaris*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".illumos*.success >/dev/null 2>&1; then
        _sunos_status="✅"
      elif ls "${_tests_tmp_dir}/${_comp}".sunos*.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".solaris*.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".illumos*.failure >/dev/null 2>&1; then
        _sunos_status="❌"
      fi

      # FreeBSD / BSD
      if ls "${_tests_tmp_dir}/${_comp}".freebsd*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".bsd*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.freebsd*.success >/dev/null 2>&1; then
        _freebsd_status="✅"
      elif ls "${_tests_tmp_dir}/${_comp}".freebsd*.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".bsd*.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.freebsd*.failure >/dev/null 2>&1; then
        _freebsd_status="❌"
      fi
    fi

    # shellcheck disable=SC2016
    printf '| `%s` | %s | %s | %s | %s | %s | %s |\n' "${_comp}" "${_apk_status}" "${_deb_status}" "${_rpm_status}" "${_win_status}" "${_sunos_status}" "${_freebsd_status}" >>"${_tmp_table}"

    if [ -n "${_tmp_json}" ]; then
      if [ "${_first_json_entry}" -eq 1 ]; then
        _first_json_entry=0
      else
        printf ',
' >>"${_tmp_json}"
      fi
      cat <<JSON_ROW >>"${_tmp_json}"
  {
    "component": "${_comp}",
    "apk": "${_apk_status}",
    "deb": "${_deb_status}",
    "rpm": "${_rpm_status}",
    "windows": "${_win_status}",
    "sunos": "${_sunos_status}",
    "freebsd": "${_freebsd_status}"
  }
JSON_ROW
    fi
  done

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
        /## Supported Components/ {
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
    if command -v npx >/dev/null 2>&1; then
      npx --yes prettier --write "${_readme_file}" >/dev/null 2>&1 || true
    fi
  fi
  rm -f "${_tmp_table}"
}

# ## update_todo_plan
# Updates TODO_PLAN.md to mark completed tasks when result files exist in tests_tmp/.
update_todo_plan() {
  _repo_root="$1"
  _todo_file="${_repo_root}/TODO_PLAN.md"
  _tests_tmp_dir="${_repo_root}/tests_tmp"

  if [ ! -f "${_todo_file}" ] || [ ! -d "${_tests_tmp_dir}" ]; then
    return 0
  fi

  _tmp_todo=$(mktemp "${TMPDIR:-/tmp}/todo_update.XXXXXX")
  _current_comp=""
  _is_alpine=0
  _is_debian=0
  _is_sunos=0
  if grep -qi "alpine" "${_todo_file}"; then
    _is_alpine=1
  elif grep -qi "debian\|ubuntu" "${_todo_file}"; then
    _is_debian=1
  elif grep -qi "sunos\|omnios" "${_todo_file}"; then
    _is_sunos=1
  fi

  while IFS= read -r _line || [ -n "${_line}" ]; do
    case "${_line}" in
      "- [ ] "*)
        _item="${_line#- \[ \] }"
        _comp_target="${_item%%:*}"
        _comp_target="${_comp_target%% (*}"
        _comp_name="${_comp_target##*/}"
        _comp_name=$(printf '%s' "${_comp_name}" | tr -d '` ')
        _current_comp="${_comp_name}"
        _has_res=0
        if [ -n "${_comp_name}" ]; then
          if [ "${_is_alpine}" -eq 1 ]; then
            if ls "${_tests_tmp_dir}/${_comp_name}".linux.alpine.* >/dev/null 2>&1 || \
               ls "${_tests_tmp_dir}/${_comp_name}".alpine.* >/dev/null 2>&1 || \
               ls "${_tests_tmp_dir}/${_comp_name}".apk.* >/dev/null 2>&1; then
              _has_res=1
            fi
          elif [ "${_is_debian}" -eq 1 ]; then
            if ls "${_tests_tmp_dir}/${_comp_name}".linux.debian.* >/dev/null 2>&1 || \
               ls "${_tests_tmp_dir}/${_comp_name}".linux.ubuntu.* >/dev/null 2>&1 || \
               ls "${_tests_tmp_dir}/${_comp_name}".debian.* >/dev/null 2>&1 || \
               ls "${_tests_tmp_dir}/${_comp_name}".ubuntu.* >/dev/null 2>&1 || \
               ls "${_tests_tmp_dir}/${_comp_name}".deb.* >/dev/null 2>&1; then
              _has_res=1
            fi
          elif [ "${_is_sunos}" -eq 1 ]; then
            if ls "${_tests_tmp_dir}/${_comp_name}".sunos.* >/dev/null 2>&1; then
              _has_res=1
            fi
          else
            if ls "${_tests_tmp_dir}/${_comp_name}"*.success >/dev/null 2>&1 || \
               ls "${_tests_tmp_dir}/${_comp_name}"*.failure >/dev/null 2>&1; then
              _has_res=1
            fi
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
        _has_idem=0
        if [ -n "${_current_comp}" ]; then
          if [ "${_is_alpine}" -eq 1 ]; then
            if (ls "${_tests_tmp_dir}/${_current_comp}".linux.alpine.success >/dev/null 2>&1 || \
                ls "${_tests_tmp_dir}/${_current_comp}".alpine.success >/dev/null 2>&1) && \
               ls "${_tests_tmp_dir}/${_current_comp}".idempotent.success >/dev/null 2>&1; then
              _has_idem=1
            fi
          elif [ "${_is_debian}" -eq 1 ]; then
            if (ls "${_tests_tmp_dir}/${_current_comp}".linux.debian.success >/dev/null 2>&1 || \
                ls "${_tests_tmp_dir}/${_current_comp}".linux.ubuntu.success >/dev/null 2>&1 || \
                ls "${_tests_tmp_dir}/${_current_comp}".debian.success >/dev/null 2>&1 || \
                ls "${_tests_tmp_dir}/${_current_comp}".ubuntu.success >/dev/null 2>&1 || \
                ls "${_tests_tmp_dir}/${_current_comp}".deb.success >/dev/null 2>&1) && \
               ls "${_tests_tmp_dir}/${_current_comp}".idempotent.success >/dev/null 2>&1; then
              _has_idem=1
            fi
          elif [ "${_is_sunos}" -eq 1 ]; then
            if ls "${_tests_tmp_dir}/${_current_comp}".sunos.success >/dev/null 2>&1 && \
               ls "${_tests_tmp_dir}/${_current_comp}".idempotent.success >/dev/null 2>&1; then
              _has_idem=1
            fi
          else
            if ls "${_tests_tmp_dir}/${_current_comp}".idempotent.success >/dev/null 2>&1; then
              _has_idem=1
            fi
          fi
        fi

        if [ "${_has_idem}" -eq 1 ]; then
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
  update_todo_plan "${_repo}"
}

main "$@"
