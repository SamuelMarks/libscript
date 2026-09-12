#!/bin/sh
# ## Overview
# Updates the Supported Components table in README.md with test results from tests_tmp/,
# and updates task completion in TODO_PLAN.md if present.
#
# ## Usage
# ./tests/update_results.sh [REPO_ROOT]

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
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
REPO_ROOT="${1:-${LIBSCRIPT_ROOT_DIR}}"

# ## update_supported_components
# Discovers components, aggregates test results from tests_tmp/, and updates README.md.
update_supported_components() {
  _repo_root="$1"
  _readme_file="${_repo_root}/README.md"
  _tests_tmp_dir="${_repo_root}/tests_tmp"

  if [ ! -d "${_repo_root}/_lib" ]; then
    return 0
  fi

  _tmp_table=$(mktemp "${TMPDIR:-/tmp}/components_table.XXXXXX")

  cat <<'TABLE_HDR' >"${_tmp_table}"
## Supported Components

| Component | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD |
|---|---|---|---|---|---|---|
TABLE_HDR

  # Discover components under _lib/<cat>/<comp> excluding dirs starting with '_'
  _components=$(cd "${_repo_root}" && find _lib -mindepth 2 -maxdepth 2 -type d ! -path "_lib/_*" ! -name "_*" 2>/dev/null | sed 's|.*/||' | sort -u)

  for _comp in ${_components}; do
    [ -z "${_comp}" ] && continue

    _existing_line=""
    if [ -f "${_readme_file}" ]; then
      _existing_line=$(awk -v comp="${_comp}" '$2 == "`"comp"`" { print; exit }' "${_readme_file}" 2>/dev/null || true)
    fi

    _apk_status="❓"
    _deb_status="❓"
    _rpm_status="❓"
    _win_status="-"
    _sunos_status="-"
    _freebsd_status="-"

    if [ -n "${_existing_line}" ]; then
      _e_apk=$(printf '%s\n' "${_existing_line}" | awk -F'|' '{print $3}' | tr -d ' ')
      _e_deb=$(printf '%s\n' "${_existing_line}" | awk -F'|' '{print $4}' | tr -d ' ')
      _e_rpm=$(printf '%s\n' "${_existing_line}" | awk -F'|' '{print $5}' | tr -d ' ')
      _e_win=$(printf '%s\n' "${_existing_line}" | awk -F'|' '{print $6}' | tr -d ' ')
      _e_sunos=$(printf '%s\n' "${_existing_line}" | awk -F'|' '{print $7}' | tr -d ' ')
      _e_freebsd=$(printf '%s\n' "${_existing_line}" | awk -F'|' '{print $8}' | tr -d ' ')

      [ -n "${_e_apk}" ] && _apk_status="${_e_apk}"
      [ -n "${_e_deb}" ] && _deb_status="${_e_deb}"
      [ -n "${_e_rpm}" ] && _rpm_status="${_e_rpm}"
      [ -n "${_e_win}" ] && _win_status="${_e_win}"
      [ -n "${_e_sunos}" ] && _sunos_status="${_e_sunos}"
      [ -n "${_e_freebsd}" ] && _freebsd_status="${_e_freebsd}"
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

      # RHEL / Fedora / AlmaLinux / CentOS / rpm
      if ls "${_tests_tmp_dir}/${_comp}".linux.rhel.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.fedora.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.almalinux.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.centos.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp}.rhel.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.fedora.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.almalinux.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.centos.success" ] || [ -f "${_tests_tmp_dir}/${_comp}.rpm.success" ]; then
        _rpm_status="✅"
      elif ls "${_tests_tmp_dir}/${_comp}".linux.rhel.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.fedora.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.almalinux.failure >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp}".linux.centos.failure >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp}.rhel.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.fedora.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.almalinux.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.centos.failure" ] || [ -f "${_tests_tmp_dir}/${_comp}.rpm.failure" ]; then
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
    printf '| `%s` | %s | %s | %s | %s | %s | %s |\n' \
      "${_comp}" "${_apk_status}" "${_deb_status}" "${_rpm_status}" "${_win_status}" "${_sunos_status}" "${_freebsd_status}" >>"${_tmp_table}"
  done

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
        printf '\n'
        cat "${_tmp_table}"
        printf '\n'
      } >"${_tmp_readme}"
      mv "${_tmp_readme}" "${_readme_file}"
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
  while IFS= read -r _line || [ -n "${_line}" ]; do
    case "${_line}" in
      "- [ ] "*)
        _item="${_line#- \[ \] }"
        _item_name="${_item##*/}"
        _item_name=$(printf '%s' "${_item_name}" | tr -d ' ')
        if ls "${_tests_tmp_dir}/${_item_name}".*.success >/dev/null 2>&1 || 
           ls "${_tests_tmp_dir}/${_item_name}".*.failure >/dev/null 2>&1; then
          printf -- '- [x] %s\n' "${_item}" >>"${_tmp_todo}"
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

update_supported_components "${REPO_ROOT}"
update_todo_plan "${REPO_ROOT}"
