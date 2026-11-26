#!/bin/sh
# ## Overview
# Updates the Supported Components tables in README.md (or custom output file) split into Architectural Tiers (T0-T5 and Orthogonal Planes) with test results from tests_tmp/, updates task completion in TODO_PLAN.md and TESTING_TODO_PLAN.md, and optionally exports an aggregated JSON test results matrix.
# ## Usage
# ./tests/update_results.sh [REPO_ROOT] [--output <markdown_file>] [--json [json_file]] [--help]
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
THIS_DIR="${SCRIPT_DIR}"
: "${THIS_DIR}"
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
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

# shellcheck disable=SC2329
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
    'darwin'|'macos'|'mac') _m_family="darwin" ;;
    'sunos'|'illumos'|'solaris') _m_family="sunos" ;;
  esac

  awk -v os="${_m_os}" -v family="${_m_family}" '
    function matches_os(line) {
      if (line ~ q os q) return 1
      if (family != "" && line ~ q family q) return 1
      if (family == "darwin" && (line ~ q "darwin" q || line ~ q "macos" q || line ~ q "mac" q)) return 1
      if (family == "sunos" && (line ~ q "sunos" q || line ~ q "illumos" q || line ~ q "solaris" q)) return 1
      return 0
    }
    BEGIN { in_bl=0; in_wl=0; has_wl=0; wl_match=0; result="yes"; q="\"" }
    /"os_blacklist"[[:space:]]*:/ {
      in_bl=1; in_wl=0
      if (matches_os($0)) { result="no"; exit }
      if ($0 ~ /\]/) { in_bl=0 }
      next
    }
    /"os_whitelist"[[:space:]]*:/ {
      in_wl=1; in_bl=0; has_wl=1
      if ($0 ~ q "all" q || matches_os($0)) { wl_match=1 }
      if ($0 ~ /\]/) { in_wl=0 }
      next
    }
    in_bl {
      if (matches_os($0)) { result="no"; exit }
      if ($0 ~ /\]/) { in_bl=0 }
    }
    in_wl {
      if ($0 ~ q "all" q || matches_os($0)) { wl_match=1 }
      if ($0 ~ /\]/) { in_wl=0 }
    }
    END {
      if (result == "yes" && has_wl && !wl_match) { result = "no" }
      print result
    }
  ' "${_m_file}"
}

# shellcheck disable=SC2329
# ## read_manifest_tier
# Reads the explicit "tier" property ("T1" or "T2") from manifest.json, falling back to category family when absent in synthetic fixtures.
read_manifest_tier() {
  _rmt_file="$1"
  _rmt_cat="$2"
  if [ -n "$_rmt_file" ] && [ -f "$_rmt_file" ]; then
    _tier_val=$(awk -F'"' '/^[[:space:]]*"tier"[[:space:]]*:[[:space:]]*"T[12]"/ { print $4; exit }' "$_rmt_file" 2>/dev/null || true)
    if [ "$_tier_val" = 'T1' ] || [ "$_tier_val" = 'T2' ]; then
      printf '%s\n' "$_tier_val"
      return 0
    fi
  fi
  case "$_rmt_cat" in
    base-system|kernel|bootloaders|init-systems|unikernels|graphics|audio|display-servers|display-managers|desktops)
      printf 'T2\n'
      ;;
    *)
      printf 'T1\n'
      ;;
  esac
}

# ## discover_all_entries
# Outputs lines of "tier|category|component|manifest_path" sorted by tier and component.
discover_all_entries() {
  _repo_root="$1"
  _raw_list=$(mktemp "${TMPDIR:-/tmp}/discover_raw.XXXXXX")
  set +f

  if [ -d "${_repo_root}/_lib" ]; then
    for _dir in "${_repo_root}/_lib"/*/*; do
      [ -d "${_dir}" ] || continue
      _cat_dir="${_dir%/*}"
      _cat="${_cat_dir##*/}"
      _comp="${_dir##*/}"
      case "${_cat}" in _*) continue ;; esac
      case "${_comp}" in _*) continue ;; esac
      _mfile=""
      [ -f "${_dir}/manifest.json" ] && _mfile="${_dir}/manifest.json"
      printf 'LIB|%s|%s|%s\n' "${_cat}" "${_comp}" "${_mfile}" >>"${_raw_list}"
    done
  fi

  if [ -d "${_repo_root}/synthesis/distro" ]; then
    for _distro_dir in "${_repo_root}/synthesis/distro"/*; do
      [ -d "${_distro_dir}" ] || continue
      _dname="${_distro_dir##*/}"
      case "${_dname}" in _*|*-base) continue ;; esac
      _mfile=""
      [ -f "${_distro_dir}/manifest.json" ] && _mfile="${_distro_dir}/manifest.json"
      printf 'T3|distro|synthesis/distro/%s|%s\n' "${_dname}" "${_mfile}" >>"${_raw_list}"
    done
  fi
  if [ -d "${_repo_root}/synthesis/repogen" ]; then
    _mfile=""
    [ -f "${_repo_root}/synthesis/repogen/manifest.json" ] && _mfile="${_repo_root}/synthesis/repogen/manifest.json"
    printf 'T3|repogen|synthesis/repogen|%s\n' "${_mfile}" >>"${_raw_list}"
  fi
  if [ -d "${_repo_root}/synthesis/vfs" ]; then
    for _vdir in "${_repo_root}/synthesis/vfs"/*; do
      [ -d "${_vdir}" ] || continue
      _vname="${_vdir##*/}"
      _mfile=""
      [ -f "${_vdir}/manifest.json" ] && _mfile="${_vdir}/manifest.json"
      printf 'T3|vfs|synthesis/vfs/%s|%s\n' "${_vname}" "${_mfile}" >>"${_raw_list}"
    done
  fi
  if [ -f "${_repo_root}/synthesis/disk/provision_disk.sh" ]; then
    printf 'T3|disk|synthesis/disk/provision_disk|\n' >>"${_raw_list}"
  fi

  for _infra_sub in providers resources clusters; do
    if [ -d "${_repo_root}/infrastructure/${_infra_sub}" ]; then
      for _infra_dir in "${_repo_root}/infrastructure/${_infra_sub}"/*; do
        [ -d "${_infra_dir}" ] || continue
        _iname="${_infra_dir##*/}"
        case "${_iname}" in _*) continue ;; esac
        _mfile=""
        [ -f "${_infra_dir}/manifest.json" ] && _mfile="${_infra_dir}/manifest.json"
        printf 'T4|%s|infrastructure/%s/%s|%s\n' "${_infra_sub}" "${_infra_sub}" "${_iname}" "${_mfile}" >>"${_raw_list}"
      done
    fi
  done

  for _work_sub in apps ai constellations; do
    if [ -d "${_repo_root}/workloads/${_work_sub}" ]; then
      for _wdir in "${_repo_root}/workloads/${_work_sub}"/*; do
        [ -d "${_wdir}" ] || continue
        _work_name="${_wdir##*/}"
        case "${_work_name}" in _*) continue ;; esac
        _mfile=""
        [ -f "${_wdir}/manifest.json" ] && _mfile="${_wdir}/manifest.json"
        printf 'T5|%s|workloads/%s/%s|%s\n' "${_work_sub}" "${_work_sub}" "${_work_name}" "${_mfile}" >>"${_raw_list}"
      done
    fi
  done
  if [ -d "${_repo_root}/workloads/schedulers" ]; then
    for _sfile in "${_repo_root}/workloads/schedulers"/*.sh; do
      [ -f "${_sfile}" ] || continue
      _sname="${_sfile##*/}"
      _sname="${_sname%.sh}"
      printf 'T5|schedulers|workloads/schedulers/%s|\n' "${_sname}" >>"${_raw_list}"
    done
  fi

  if [ -d "${_repo_root}/traits" ]; then
    for _trdir in "${_repo_root}/traits"/*; do
      [ -d "${_trdir}" ] || continue
      _trname="${_trdir##*/}"
      case "${_trname}" in _*) continue ;; esac
      printf 'PlaneA|traits|traits/%s|\n' "${_trname}" >>"${_raw_list}"
    done
  fi
  set -f

  awk -F'|' '
    {
      tier = $1; cat = $2; comp = $3; mfile = $4
      if (tier == "LIB") {
        tier = "T1"
        if (cat ~ /^(base-system|kernel|bootloaders|init-systems|unikernels|graphics|audio|display-servers|display-managers|desktops)$/) {
          tier = "T2"
        }
        if (mfile != "") {
          rc = (getline m_line < mfile)
          if (rc >= 0) {
            while (rc > 0) {
              if (m_line ~ /^[ \t]*"tier"[ \t]*:[ \t]*"T[12]"/) {
                if (split(m_line, mq, "\"") >= 4 && (mq[4] == "T1" || mq[4] == "T2")) {
                  tier = mq[4]
                }
                break
              }
              rc = (getline m_line < mfile)
            }
            close(mfile)
          }
        }
      }
      printf "%s|%s|%s|%s\n", tier, cat, comp, mfile
    }
  ' "${_raw_list}" | sort -t'|' -k1,1 -k3,3 -u
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
  _tmp_t1=$(mktemp "${TMPDIR:-/tmp}/tier_t1.XXXXXX")
  _tmp_t2=$(mktemp "${TMPDIR:-/tmp}/tier_t2.XXXXXX")
  _tmp_t3=$(mktemp "${TMPDIR:-/tmp}/tier_t3.XXXXXX")
  _tmp_t4=$(mktemp "${TMPDIR:-/tmp}/tier_t4.XXXXXX")
  _tmp_t5=$(mktemp "${TMPDIR:-/tmp}/tier_t5.XXXXXX")
  _tmp_pa=$(mktemp "${TMPDIR:-/tmp}/plane_a.XXXXXX")

  _tmp_json=""
  if [ -n "${_json_file}" ]; then
    _tmp_json=$(mktemp "${TMPDIR:-/tmp}/components_json.XXXXXX")
    printf '[
' >"${_tmp_json}"
  fi

  _entries_file=$(mktemp "${TMPDIR:-/tmp}/entries.XXXXXX")
  discover_all_entries "${_repo_root}" >"${_entries_file}"

  _markers_list=$(mktemp "${TMPDIR:-/tmp}/markers_list.XXXXXX")
  if [ -d "${_tests_tmp_dir}" ]; then
    ls -1 "${_tests_tmp_dir}" >"${_markers_list}" 2>/dev/null || true
  fi

  UR_README="${_readme_file}" \
  UR_MARKERS="${_markers_list}" \
  UR_T1="${_tmp_t1}" \
  UR_T2="${_tmp_t2}" \
  UR_T3="${_tmp_t3}" \
  UR_T4="${_tmp_t4}" \
  UR_T5="${_tmp_t5}" \
  UR_PA="${_tmp_pa}" \
  UR_JSON="${_tmp_json}" \
  awk '
    function has_exact(c, target) {
      return ((c "." target) in exact)
    }
    function has_glob(c, rx,   i, n) {
      n = cnt[c] + 0
      for (i = 1; i <= n; i++) {
        if (sfx[c, i] ~ rx) return 1
      }
      return 0
    }
    function os_matches(line, os, fam) {
      if (index(line, q os q) > 0) return 1
      if (fam != "" && index(line, q fam q) > 0) return 1
      if (fam == "darwin" && (index(line, q "darwin" q) > 0 || index(line, q "macos" q) > 0 || index(line, q "mac" q) > 0)) return 1
      if (fam == "sunos" && (index(line, q "sunos" q) > 0 || index(line, q "illumos" q) > 0 || index(line, q "solaris" q) > 0)) return 1
      return 0
    }
    BEGIN {
      readme_file = ENVIRON["UR_README"]
      markers_file = ENVIRON["UR_MARKERS"]
      t1_out = ENVIRON["UR_T1"]
      t2_out = ENVIRON["UR_T2"]
      t3_out = ENVIRON["UR_T3"]
      t4_out = ENVIRON["UR_T4"]
      t5_out = ENVIRON["UR_T5"]
      pa_out = ENVIRON["UR_PA"]
      json_out = ENVIRON["UR_JSON"]
      q = "\""
      bt = sprintf("%c", 96)
      first_json = 1
      row_seq = 0

      if (markers_file != "") {
        rc = (getline m_entry < markers_file)
        if (rc >= 0) {
          while (rc > 0) {
            sub(/\r$/, "", m_entry)
            if (m_entry != "") {
              exact[m_entry] = 1
              dot = index(m_entry, ".")
              if (dot > 1) {
                p = substr(m_entry, 1, dot - 1)
                s = substr(m_entry, dot + 1)
                cnt[p]++
                sfx[p, cnt[p]] = s
              }
            }
            rc = (getline m_entry < markers_file)
          }
          close(markers_file)
        }
      }

      if (readme_file != "") {
        rc = (getline rline < readme_file)
        if (rc >= 0) {
          while (rc > 0) {
            sub(/\r$/, "", rline)
            if (substr(rline, 1, 1) == "|") {
              trimmed = rline
              sub(/[ \t]*\|[ \t]*$/, "", trimmed)
              nf = split(trimmed, rp, "|")
              if (nf >= 9) {
                c2 = rp[2]
                sub(/^[ \t]+/, "", c2); sub(/[ \t]+$/, "", c2)
                if (length(c2) >= 2 && substr(c2, 1, 1) == bt && substr(c2, length(c2), 1) == bt) {
                  r_comp = substr(c2, 2, length(c2) - 2)
                  c3 = rp[3]
                  sub(/^[ \t]+/, "", c3); sub(/[ \t]+$/, "", c3)
                  r_cat = ""
                  if (length(c3) >= 2 && substr(c3, 1, 1) == bt && substr(c3, length(c3), 1) == bt) {
                    r_cat = substr(c3, 2, length(c3) - 2)
                  }
                  row_seq++
                  if (nf >= 10) {
                    va = rp[4]; vd = rp[5]; vr = rp[6]; vw = rp[7]; vs = rp[8]; vf = rp[9]; vm = rp[10]
                  } else {
                    va = rp[3]; vd = rp[4]; vr = rp[5]; vw = rp[6]; vs = rp[7]; vf = rp[8]; vm = rp[9]
                  }
                  gsub(/[ \t]/, "", va); gsub(/[ \t]/, "", vd); gsub(/[ \t]/, "", vr)
                  gsub(/[ \t]/, "", vw); gsub(/[ \t]/, "", vs); gsub(/[ \t]/, "", vf); gsub(/[ \t]/, "", vm)
                  if (length(va) >= 2 && substr(va, 1, 1) == bt && substr(va, length(va), 1) == bt) va = ""
                  ex_apk[row_seq] = va; ex_deb[row_seq] = vd; ex_rpm[row_seq] = vr
                  ex_win[row_seq] = vw; ex_sun[row_seq] = vs; ex_fbsd[row_seq] = vf; ex_mac[row_seq] = vm
                  if (!(r_comp in by_comp)) by_comp[r_comp] = row_seq
                  if (r_cat != "" && !((r_comp "|" r_cat) in by_comp_cat)) by_comp_cat[r_comp "|" r_cat] = row_seq
                }
              }
            }
            rc = (getline rline < readme_file)
          }
          close(readme_file)
        }
      }
    }
    {
      n_f = split($0, f, "|")
      tier = f[1]; cat = f[2]; comp = f[3]; mfile = f[4]
      if (comp == "") next

      sc = comp
      sub(/^.*\//, "", sc)
      mc = sc
      if (comp == "freebsd/distro" || comp == "synthesis/distro/freebsd") mc = "freebsd-distro"
      else if (comp == "illumos/distro" || comp == "synthesis/distro/illumos") mc = "illumos-distro"
      else if (comp == "reactos/distro" || comp == "synthesis/distro/reactos") mc = "reactos-distro"
      else if (comp == "dos/distro" || comp == "synthesis/distro/dos") mc = "dos-distro"
      else if (comp ~ /^bootloaders\//) mc = "bootloaders-" sc
      else if (comp ~ /^workloads\/schedulers\//) mc = "scheduler-" sc
      else if (comp ~ /^traits\//) mc = "trait-" sc

      apk_st = "-"; deb_st = "-"; rpm_st = "-"; win_st = "-"; sun_st = "-"; fbsd_st = "-"; mac_st = "-"
      opened_manifest = 0
      if (mfile != "") {
        rc = (getline m_line < mfile)
        if (rc >= 0) {
          opened_manifest = 1
          in_bl = 0; in_wl = 0; has_wl = 0
          for (k = 1; k <= 7; k++) { bl[k] = 0; wl[k] = 0 }
          while (rc > 0) {
            if (m_line ~ /"os_blacklist"[ \t]*:/) {
              in_bl = 1; in_wl = 0
              if (os_matches(m_line, "alpine", "linux")) bl[1] = 1
              if (os_matches(m_line, "debian", "linux")) bl[2] = 1
              if (os_matches(m_line, "rhel", "linux")) bl[3] = 1
              if (os_matches(m_line, "windows", "windows")) bl[4] = 1
              if (os_matches(m_line, "sunos", "sunos")) bl[5] = 1
              if (os_matches(m_line, "freebsd", "bsd")) bl[6] = 1
              if (os_matches(m_line, "darwin", "darwin")) bl[7] = 1
              if (index(m_line, "]") > 0) in_bl = 0
            } else if (m_line ~ /"os_whitelist"[ \t]*:/) {
              in_wl = 1; in_bl = 0; has_wl = 1
              is_all = (index(m_line, q "all" q) > 0)
              if (is_all || os_matches(m_line, "alpine", "linux")) wl[1] = 1
              if (is_all || os_matches(m_line, "debian", "linux")) wl[2] = 1
              if (is_all || os_matches(m_line, "rhel", "linux")) wl[3] = 1
              if (is_all || os_matches(m_line, "windows", "windows")) wl[4] = 1
              if (is_all || os_matches(m_line, "sunos", "sunos")) wl[5] = 1
              if (is_all || os_matches(m_line, "freebsd", "bsd")) wl[6] = 1
              if (is_all || os_matches(m_line, "darwin", "darwin")) wl[7] = 1
              if (index(m_line, "]") > 0) in_wl = 0
            } else if (in_bl) {
              if (os_matches(m_line, "alpine", "linux")) bl[1] = 1
              if (os_matches(m_line, "debian", "linux")) bl[2] = 1
              if (os_matches(m_line, "rhel", "linux")) bl[3] = 1
              if (os_matches(m_line, "windows", "windows")) bl[4] = 1
              if (os_matches(m_line, "sunos", "sunos")) bl[5] = 1
              if (os_matches(m_line, "freebsd", "bsd")) bl[6] = 1
              if (os_matches(m_line, "darwin", "darwin")) bl[7] = 1
              if (index(m_line, "]") > 0) in_bl = 0
            } else if (in_wl) {
              is_all = (index(m_line, q "all" q) > 0)
              if (is_all || os_matches(m_line, "alpine", "linux")) wl[1] = 1
              if (is_all || os_matches(m_line, "debian", "linux")) wl[2] = 1
              if (is_all || os_matches(m_line, "rhel", "linux")) wl[3] = 1
              if (is_all || os_matches(m_line, "windows", "windows")) wl[4] = 1
              if (is_all || os_matches(m_line, "sunos", "sunos")) wl[5] = 1
              if (is_all || os_matches(m_line, "freebsd", "bsd")) wl[6] = 1
              if (is_all || os_matches(m_line, "darwin", "darwin")) wl[7] = 1
              if (index(m_line, "]") > 0) in_wl = 0
            }
            rc = (getline m_line < mfile)
          }
          close(mfile)
          if (!bl[1] && (!has_wl || wl[1])) apk_st = "❓"
          if (!bl[2] && (!has_wl || wl[2])) deb_st = "❓"
          if (!bl[3] && (!has_wl || wl[3])) rpm_st = "❓"
          if (!bl[4] && (!has_wl || wl[4])) win_st = "❓"
          if (!bl[5] && (!has_wl || wl[5])) sun_st = "❓"
          if (!bl[6] && (!has_wl || wl[6])) fbsd_st = "❓"
          if (!bl[7] && (!has_wl || wl[7])) mac_st = "❓"
        }
      }
      if (!opened_manifest) {
        if (cat == "bootloaders") {
          apk_st = "❓"; deb_st = "❓"; rpm_st = "❓"; fbsd_st = "❓"
        } else {
          apk_st = "❓"; deb_st = "❓"; rpm_st = "❓"; win_st = "❓"; sun_st = "❓"; fbsd_st = "❓"; mac_st = "❓"
        }
      }

      ex_idx = 0
      if (index(comp, "/") > 0) {
        i1 = (comp in by_comp) ? by_comp[comp] : 0
        i2 = ((sc "|" cat) in by_comp_cat) ? by_comp_cat[sc "|" cat] : 0
        if (i1 > 0 && i2 > 0) ex_idx = (i1 < i2 ? i1 : i2)
        else if (i1 > 0) ex_idx = i1
        else if (i2 > 0) ex_idx = i2
      } else {
        if (comp in by_comp) ex_idx = by_comp[comp]
      }
      if (ex_idx > 0) {
        if (ex_apk[ex_idx] != "" && apk_st != "-") apk_st = ex_apk[ex_idx]
        if (ex_deb[ex_idx] != "" && deb_st != "-") deb_st = ex_deb[ex_idx]
        if (ex_rpm[ex_idx] != "" && rpm_st != "-") rpm_st = ex_rpm[ex_idx]
        if (ex_win[ex_idx] != "" && win_st != "-") win_st = ex_win[ex_idx]
        if (ex_sun[ex_idx] != "" && sun_st != "-") sun_st = ex_sun[ex_idx]
        if (ex_fbsd[ex_idx] != "" && fbsd_st != "-") fbsd_st = ex_fbsd[ex_idx]
        if (ex_mac[ex_idx] != "" && mac_st != "-") mac_st = ex_mac[ex_idx]
      }

      idemp = (has_exact(mc, "idempotent.success") || has_exact(sc, "idempotent.success")) ? "true" : "false"

      if (has_exact(mc, "linux.alpine.success") || has_exact(sc, "linux.alpine.success") || has_exact(sc, "alpine.success") || has_exact(sc, "apk.success")) apk_st = "✅"
      else if (has_exact(mc, "linux.alpine.skipped") || has_exact(sc, "linux.alpine.skipped")) apk_st = "-"
      else if (has_exact(mc, "linux.alpine.failure") || has_exact(sc, "linux.alpine.failure") || has_exact(sc, "alpine.failure") || has_exact(sc, "apk.failure")) apk_st = "❌"

      if (has_exact(mc, "linux.debian.success") || has_exact(sc, "linux.debian.success") || has_exact(sc, "linux.ubuntu.success") || has_exact(sc, "debian.success") || has_exact(sc, "ubuntu.success") || has_exact(sc, "deb.success")) deb_st = "✅"
      else if (has_exact(mc, "linux.debian.skipped") || has_exact(sc, "linux.debian.skipped")) deb_st = "-"
      else if (has_exact(mc, "linux.debian.failure") || has_exact(sc, "linux.debian.failure") || has_exact(sc, "linux.ubuntu.failure") || has_exact(sc, "debian.failure") || has_exact(sc, "ubuntu.failure") || has_exact(sc, "deb.failure")) deb_st = "❌"

      if (has_glob(mc, "^linux\\.rocky.*\\.success$") || has_glob(sc, "^linux\\.(rocky.*|rhel|fedora|almalinux|centos)\\.success$") || has_glob(sc, "^(rhel|fedora|almalinux|centos|rocky|rockylinux|rpm)\\.success$")) rpm_st = "✅"
      else if (has_exact(mc, "linux.rocky.skipped") || has_exact(sc, "linux.rocky.skipped")) rpm_st = "-"
      else if (has_glob(mc, "^linux\\.rocky.*\\.failure$") || has_glob(sc, "^linux\\.(rocky.*|rhel|fedora|almalinux|centos)\\.failure$") || has_glob(sc, "^(rhel|fedora|almalinux|centos|rocky|rockylinux|rpm)\\.failure$")) rpm_st = "❌"

      if (has_glob(mc, "^windows.*\\.success$") || has_glob(sc, "^win.*\\.success$")) win_st = "✅"
      else if (has_glob(mc, "^windows.*\\.skipped$") || has_glob(sc, "^windows.*\\.skipped$")) win_st = "-"
      else if (has_glob(mc, "^windows.*\\.failure$") || has_glob(sc, "^win.*\\.failure$")) win_st = "❌"

      if (has_glob(mc, "^sunos.*\\.success$") || has_glob(sc, "^(sunos|solaris|illumos).*\\.success$")) sun_st = "✅"
      else if (has_glob(mc, "^sunos.*\\.skipped$") || has_glob(sc, "^sunos.*\\.skipped$")) sun_st = "-"
      else if (has_glob(mc, "^sunos.*\\.failure$") || has_glob(sc, "^(sunos|solaris|illumos).*\\.failure$")) sun_st = "❌"

      if (mc != sc) {
        if (has_glob(mc, "^freebsd.*\\.success$")) fbsd_st = "✅"
        else if (has_glob(mc, "^freebsd.*\\.skipped$")) fbsd_st = "-"
        else if (has_glob(mc, "^freebsd.*\\.failure$")) fbsd_st = "❌"
      } else {
        if (has_glob(sc, "^(freebsd|bsd|linux\\.freebsd).*\\.success$")) fbsd_st = "✅"
        else if (has_glob(sc, "^freebsd.*\\.skipped$")) fbsd_st = "-"
        else if (has_glob(sc, "^(freebsd|bsd|linux\\.freebsd).*\\.failure$")) fbsd_st = "❌"
      }

      if (mc != sc) {
        if (has_glob(mc, "^(darwin|macos).*\\.success$")) mac_st = "✅"
        else if (has_exact(mc, "darwin.unsupported") || has_glob(mc, "^(darwin|macos).*\\.skipped$")) mac_st = "-"
        else if (has_glob(mc, "^(darwin|macos).*\\.failure$")) mac_st = "❌"
      } else {
        if (has_glob(sc, "^(darwin|macos).*\\.success$")) mac_st = "✅"
        else if (has_exact(sc, "darwin.unsupported") || has_glob(sc, "^(darwin|macos).*\\.skipped$")) mac_st = "-"
        else if (has_glob(sc, "^(darwin|macos).*\\.failure$")) mac_st = "❌"
      }

      row_str = sprintf("| %s%s%s | %s%s%s | %s | %s | %s | %s | %s | %s | %s |", bt, comp, bt, bt, cat, bt, apk_st, deb_st, rpm_st, win_st, sun_st, fbsd_st, mac_st)
      if (tier == "T2") print row_str >> t2_out
      else if (tier == "T3") print row_str >> t3_out
      else if (tier == "T4") print row_str >> t4_out
      else if (tier == "T5") print row_str >> t5_out
      else if (tier == "PlaneA") print row_str >> pa_out
      else print row_str >> t1_out

      if (json_out != "") {
        if (first_json) {
          first_json = 0
        } else {
          printf ",\n" >> json_out
        }
        printf "  {\n" >> json_out
        printf "    \"tier\": \"%s\",\n", tier >> json_out
        printf "    \"category\": \"%s\",\n", cat >> json_out
        printf "    \"component\": \"%s\",\n", comp >> json_out
        printf "    \"idempotent\": %s,\n", idemp >> json_out
        printf "    \"apk\": \"%s\",\n", apk_st >> json_out
        printf "    \"deb\": \"%s\",\n", deb_st >> json_out
        printf "    \"rpm\": \"%s\",\n", rpm_st >> json_out
        printf "    \"windows\": \"%s\",\n", win_st >> json_out
        printf "    \"sunos\": \"%s\",\n", sun_st >> json_out
        printf "    \"freebsd\": \"%s\",\n", fbsd_st >> json_out
        printf "    \"macos\": \"%s\"\n", mac_st >> json_out
        printf "  }" >> json_out
      }
    }
    END {
      close(t1_out); close(t2_out); close(t3_out); close(t4_out); close(t5_out); close(pa_out)
      if (json_out != "") close(json_out)
    }
  ' "${_entries_file}"

  rm -f "${_markers_list}" "${_entries_file}"

  {
    cat <<'HDR_MAIN'
## Supported Components

Components are organized into LibScript's 6 strict compositional tiers (`T0`–`T5`) and orthogonal cross-cutting planes (see [`ARCHITECTURE.md`](ARCHITECTURE.md)).

### T1: Atomic Userland & Daemon Recipes

| Component | Category | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD | macOS |
|---|---|---|---|---|---|---|---|---|
HDR_MAIN
    cat "${_tmp_t1}"

    cat <<'HDR_T2'

### T2: OS, Kernel & System Plumbing Recipes

| Component | Category | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD | macOS |
|---|---|---|---|---|---|---|---|---|
HDR_T2
    cat "${_tmp_t2}"

    cat <<'HDR_T3'

### T3: Image, OS & Artifact Synthesis

| Component | Category | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD | macOS |
|---|---|---|---|---|---|---|---|---|
HDR_T3
    cat "${_tmp_t3}"

    cat <<'HDR_T4'

### T4: Infrastructure Providers & Cluster Substrates

| Component | Category | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD | macOS |
|---|---|---|---|---|---|---|---|---|
HDR_T4
    cat "${_tmp_t4}"

    cat <<'HDR_T5'

### T5: Declarative Workloads, Application Stacks & Stateful Constellations

| Component | Category | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD | macOS |
|---|---|---|---|---|---|---|---|---|
HDR_T5
    cat "${_tmp_t5}"

    cat <<'HDR_PA'

### Plane A (Traits): Unified Cross-Cutting Node Traits

| Component | Category | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD | macOS |
|---|---|---|---|---|---|---|---|---|
HDR_PA
    cat "${_tmp_pa}"
  } >"${_tmp_table}"

  rm -f "${_tmp_t1}" "${_tmp_t2}" "${_tmp_t3}" "${_tmp_t4}" "${_tmp_t5}" "${_tmp_pa}"

  if [ -n "${_tmp_json}" ]; then
    printf '
]
' >>"${_tmp_json}"
    mkdir -p "$(dirname "${_json_file}")"
    mv "${_tmp_json}" "${_json_file}"
  fi

  if [ -f "${_readme_file}" ]; then
    _new_norm=$(awk '
      {
        gsub(/\r/, "")
        line = $0
        sub(/^[ \t]+/, "", line)
        sub(/[ \t]+$/, "", line)
        if (line == "") next
        if (line ~ /^\|[ \t\-:|]+\|$/) {
          print "|---|---|---|---|---|---|---|---|---|"
          next
        }
        if (substr(line, 1, 1) == "|" && substr(line, length(line), 1) == "|") {
          inner = substr(line, 2, length(line) - 2)
          n = split(inner, cells, "|")
          out = "|"
          for (i = 1; i <= n; i++) {
            c = cells[i]
            sub(/^[ \t]+/, "", c)
            sub(/[ \t]+$/, "", c)
            out = out " " c " |"
          }
          print out
          next
        }
        if (substr(line, 1, 1) == "#") {
          print line
        }
      }' "${_tmp_table}")
    _old_norm=$(awk '
      /^## Supported Components/ { in_sec = 1 }
      /^## / && !/^## Supported Components/ && in_sec { in_sec = 0 }
      in_sec {
        gsub(/\r/, "")
        line = $0
        sub(/^[ \t]+/, "", line)
        sub(/[ \t]+$/, "", line)
        if (line == "") next
        if (line ~ /^\|[ \t\-:|]+\|$/) {
          print "|---|---|---|---|---|---|---|---|---|"
          next
        }
        if (substr(line, 1, 1) == "|" && substr(line, length(line), 1) == "|") {
          inner = substr(line, 2, length(line) - 2)
          n = split(inner, cells, "|")
          out = "|"
          for (i = 1; i <= n; i++) {
            c = cells[i]
            sub(/^[ \t]+/, "", c)
            sub(/[ \t]+$/, "", c)
            out = out " " c " |"
          }
          print out
          next
        }
        if (substr(line, 1, 1) == "#") {
          print line
        }
      }' "${_readme_file}")

    if [ "${_new_norm}" != "${_old_norm}" ]; then
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
          printf '\n'
          cat "${_tmp_table}"
          printf '\n'
        } >"${_tmp_readme}"
        mv "${_tmp_readme}" "${_readme_file}"
      fi
      if command -v prettier >/dev/null 2>&1; then
        prettier --write "${_readme_file}" >/dev/null 2>&1 || true
      elif [ -x "${_repo_root}/node_modules/.bin/prettier" ]; then
        "${_repo_root}/node_modules/.bin/prettier" --write "${_readme_file}" >/dev/null 2>&1 || true
      elif command -v npx >/dev/null 2>&1; then
        npx --yes prettier --write "${_readme_file}" >/dev/null 2>&1 || true
      fi
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
          synthesis/distro/freebsd) _readme_key="freebsd/distro" ;;
          synthesis/distro/illumos) _readme_key="illumos/distro" ;;
          synthesis/disk) _readme_key="storage/provision_disk" ;;
          synthesis/vfs/provision_isolated_runtime) _readme_key="runtimes/provision_isolated_runtime" ;;
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

        if [ "${_r_sunos}" = "✅" ] || [ "${_r_sunos}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".sunos*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".sunos*.skipped >/dev/null 2>&1); }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] OmniOS/[x] OmniOS/')
        fi
        if [ "${_r_apk}" = "✅" ] || [ "${_r_apk}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".linux.alpine.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.alpine.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.apk.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".*alpine*.skipped >/dev/null 2>&1); }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Alpine/[x] Alpine/')
        fi
        if [ "${_r_deb}" = "✅" ] || [ "${_r_deb}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".linux.debian.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.debian.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.deb.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".*debian*.skipped >/dev/null 2>&1); }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Debian/[x] Debian/')
        fi
        if [ "${_r_rpm}" = "✅" ] || [ "${_r_rpm}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".linux.rocky*.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.rocky.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.rpm.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".*rocky*.skipped >/dev/null 2>&1); }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Rocky/[x] Rocky/')
        fi
        if [ "${_r_freebsd}" = "✅" ] || [ "${_r_freebsd}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".freebsd*.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.bsd.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".freebsd*.skipped >/dev/null 2>&1); }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] FreeBSD/[x] FreeBSD/')
        fi
        if [ "${_r_win}" = "✅" ] || [ "${_r_win}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".windows*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".win*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".windows*.skipped >/dev/null 2>&1); }; then
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
  if head -n 1 "${_todo_file}" | grep -q 'Native Windows & MS-DOS Execution Plan'; then
    return 0
  fi

  _tmp_todo=$(mktemp "${TMPDIR:-/tmp}/todo_update.XXXXXX")
  _current_comp=""

  # shellcheck disable=SC2016
  while IFS= read -r _line || [ -n "${_line}" ]; do
    case "${_line}" in
      '- ['*'] `'*': ['*'OmniOS'*)
        _prefix="${_line%%:*}"
        _prefix="${_prefix%% (*}"
        _comp_ref="${_prefix#- \[?\] }"
        _comp_ref=$(printf '%s' "${_comp_ref}" | tr -d '` ')
        _comp_short="${_comp_ref##*/}"
        _mc="${_comp_short}"
        case "${_comp_ref}" in
          synthesis/distro/dos|dos/distro) _mc="dos-distro" ;;
          synthesis/distro/freebsd|freebsd/distro) _mc="freebsd-distro" ;;
          synthesis/distro/illumos|illumos/distro) _mc="illumos-distro" ;;
          synthesis/distro/reactos|reactos/distro) _mc="reactos-distro" ;;
          _lib/bootloaders/*) _mc="bootloaders-${_comp_short}" ;;
          workloads/schedulers/*) _mc="scheduler-${_comp_short}" ;;
          traits/*) _mc="trait-${_comp_short}" ;;
        esac
        _new_line="${_line}"
        if [ -d "${_tests_tmp_dir}" ]; then
          if [ -f "${_tests_tmp_dir}/${_mc}.linux.alpine.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.linux.alpine.success" ]; then
            _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Alpine/[x] Alpine/')
          fi
          if [ -f "${_tests_tmp_dir}/${_mc}.linux.debian.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.linux.debian.success" ]; then
            _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Debian/[x] Debian/')
          fi
          if [ -f "${_tests_tmp_dir}/${_mc}.linux.rocky.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.linux.rocky.success" ]; then
            _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Rocky/[x] Rocky/')
          fi
          if [ -f "${_tests_tmp_dir}/${_mc}.windows.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.windows.success" ]; then
            _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Windows/[x] Windows/')
          fi
          if [ -f "${_tests_tmp_dir}/${_mc}.sunos.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.sunos.success" ]; then
            _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] OmniOS/[x] OmniOS/')
          fi
          if [ -f "${_tests_tmp_dir}/${_mc}.freebsd.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.freebsd.success" ]; then
            _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] FreeBSD/[x] FreeBSD/')
          fi
          if [ -f "${_tests_tmp_dir}/${_mc}.darwin.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.darwin.success" ]; then
            _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] macOS/[x] macOS/')
          fi
          if [ -f "${_tests_tmp_dir}/${_mc}.idempotent.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.idempotent.success" ]; then
            _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] 2x Idempotent/[x] 2x Idempotent/')
          fi
        fi
        case "${_new_line#*:}" in
          *"[ ]"*) ;;
          *) _new_line=$(printf '%s' "${_new_line}" | sed 's/^- \[ \] /- [x] /') ;;
        esac
        printf '%s\n' "${_new_line}" >>"${_tmp_todo}"
        ;;
      '- [ ] `_lib/'*)
        _item="${_line#- \[ \] }"
        _comp_target="${_item%%:*}"
        _comp_target="${_comp_target%% (*}"
        _comp_name="${_comp_target##*/}"
        _comp_name=$(printf '%s' "${_comp_name}" | tr -d '` ')
        _current_comp="${_comp_name}"
        _has_res=0
        if [ -n "${_comp_name}" ]; then
          if [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_name}"*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_name}"*.failure >/dev/null 2>&1); then
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
      '- [ ] `'*'` (`'*)
        _item="${_line#- \[ \] }"
        _comp_target="${_item%% (*}"
        _comp_key=$(printf '%s' "${_comp_target}" | tr -d '` ')
        _comp_short="${_comp_key##*/}"
        _marker_comp="${_comp_short}"
        case "${_comp_key}" in
          freebsd/distro) _marker_comp='freebsd-distro' ;;
          illumos/distro) _marker_comp='illumos-distro' ;;
          bootloaders/*) _marker_comp="bootloaders-${_comp_short}" ;;
          workloads/schedulers/*) _marker_comp="scheduler-${_comp_short}" ;;
          traits/*) _marker_comp="trait-${_comp_short}" ;;
        esac
        _current_comp="${_comp_short}"
        _has_res=0
        if [ -n "${_comp_key}" ]; then
          case "${_line}" in
            *macOS*|*Darwin*)
              if [ -d "${_tests_tmp_dir}" ] && { [ -f "${_tests_tmp_dir}/${_marker_comp}.darwin.success" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.darwin.failure" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.darwin.skipped" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.darwin.unsupported" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.darwin.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.darwin.failure" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.darwin.skipped" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.darwin.unsupported" ]; }; then
                _has_res=1
              fi
              ;;
            *FreeBSD*)
              if [ -d "${_tests_tmp_dir}" ] && { [ -f "${_tests_tmp_dir}/${_marker_comp}.freebsd.success" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.freebsd.failure" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.freebsd.skipped" ]; }; then
                _has_res=1
              fi
              ;;
            *OmniOS*|*SunOS*|*"Verify \`-\`"*)
              if [ -d "${_tests_tmp_dir}" ] && { [ -f "${_tests_tmp_dir}/${_marker_comp}.sunos.success" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.sunos.failure" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.sunos.skipped" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.sunos.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.sunos.failure" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.sunos.skipped" ]; }; then
                _has_res=1
              fi
              ;;
            *Windows*)
              if [ -d "${_tests_tmp_dir}" ] && { [ -f "${_tests_tmp_dir}/${_marker_comp}.windows.success" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.windows.failure" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.windows.skipped" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.windows.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.windows.failure" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.windows.skipped" ]; }; then
                _has_res=1
              fi
              ;;
            *Rocky*)
              if [ -d "${_tests_tmp_dir}" ] && { [ -f "${_tests_tmp_dir}/${_marker_comp}.linux.rocky.success" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.linux.rocky.failure" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.linux.rocky.skipped" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.linux.rocky.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.linux.rocky.failure" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.linux.rocky.skipped" ]; }; then
                _has_res=1
              fi
              ;;
            *Debian*)
              if [ -d "${_tests_tmp_dir}" ] && { [ -f "${_tests_tmp_dir}/${_marker_comp}.linux.debian.success" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.linux.debian.failure" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.linux.debian.skipped" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.linux.debian.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.linux.debian.failure" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.linux.debian.skipped" ]; }; then
                _has_res=1
              fi
              ;;
            *)
              if [ -d "${_tests_tmp_dir}" ] && { [ -f "${_tests_tmp_dir}/${_marker_comp}.linux.alpine.success" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.linux.alpine.failure" ] || [ -f "${_tests_tmp_dir}/${_marker_comp}.linux.alpine.skipped" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.linux.alpine.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.linux.alpine.failure" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.linux.alpine.skipped" ]; }; then
                _has_res=1
              elif [ -f "${_readme_ref}" ]; then
                _rline=$(grep -F "| \`${_comp_key}\`" "${_readme_ref}" 2>/dev/null | head -n 1 || true)
                if [ -n "${_rline}" ]; then
                  _old_ifs="${IFS}"
                  IFS='|'
                  # shellcheck disable=SC2086
                  set -- ${_rline}
                  IFS="${_old_ifs}"
                  _r_apk=$(printf '%s' "${4:-}" | tr -d ' ')
                  if [ "${_r_apk}" = "✅" ] || [ "${_r_apk}" = "-" ] || [ "${_r_apk}" = "❌" ]; then
                    _has_res=1
                  fi
                fi
              fi
              ;;
          esac
        fi

        if [ "${_has_res}" -eq 1 ]; then
          _item=$(printf '%s' "${_item}" | sed 's/\[ \] macOS 27\.2 Vagrant Retest/[x] macOS 27.2 Vagrant Retest/; s/\[ \] macOS Vagrant Retest/[x] macOS Vagrant Retest/; s/\[ \] FreeBSD Vagrant Retest/[x] FreeBSD Vagrant Retest/; s/\[ \] Windows Retest/[x] Windows Retest/; s/\[ \] OmniOS Vagrant Retest/[x] OmniOS Vagrant Retest/; s/\[ \] Verify `-`/[x] Verify `-`/; s/\[ \] Verify `❓` -> Retest/[x] Verify `❓` -> Retest/; s/\[ \] Reset `[^`]*` -> `❓`/[x] Reset `✅` -> `❓`/; s/\[ \] Reset `[^`]*` ->/[x] Reset `✅` ->/; s/\[ \] 2x Idempotent/[x] 2x Idempotent/; s/\[ \] `.sh`\/`.cmd` Parity/[x] `.sh`\/`.cmd` Parity/; s/\[ \] `Linux (rpm)`/[x] `Linux (rpm)`/; s/\[ \] \*\*Double-check/[x] **Double-check/')
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
  # shellcheck disable=SC2016
  while IFS= read -r _line || [ -n "${_line}" ]; do
    case "${_line}" in
      *'Track retesting progress by checking off'*'- [ ]'*)
        printf '%s\n' "${_line}" >>"${_tmp_retest}"
        ;;
      '- ['*'] `'*'` (`_lib/'*|'- ['*'] `'*'` (`workloads/'*|'- ['*'] `'*'` (`synthesis/'*|'- ['*'] `'*'` (`infrastructure/'*|'- ['*'] `'*'` (`traits/'*)
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

        if [ "${_r_apk}" = "✅" ] || [ "${_r_apk}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".linux.alpine.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.alpine.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.apk.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".*alpine*.skipped >/dev/null 2>&1); }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Alpine/[x] Alpine/')
        fi
        if [ "${_r_deb}" = "✅" ] || [ "${_r_deb}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".linux.debian.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.debian.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.deb.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".*debian*.skipped >/dev/null 2>&1); }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Debian/[x] Debian/')
        fi
        if [ "${_r_rpm}" = "✅" ] || [ "${_r_rpm}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".linux.rocky*.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.rocky.success" ] || [ -f "${_tests_tmp_dir}/${_comp_short}.rpm.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".*rocky*.skipped >/dev/null 2>&1); }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Rocky/[x] Rocky/')
        fi
        if [ "${_r_win}" = "✅" ] || [ "${_r_win}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".windows*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".win*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".windows*.skipped >/dev/null 2>&1); }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] Windows/[x] Windows/')
        fi
        if [ "${_r_sunos}" = "✅" ] || [ "${_r_sunos}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".sunos*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".sunos*.skipped >/dev/null 2>&1); }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] OmniOS/[x] OmniOS/')
        fi
        if [ "${_r_freebsd}" = "✅" ] || [ "${_r_freebsd}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".freebsd*.success >/dev/null 2>&1 || [ -f "${_tests_tmp_dir}/${_comp_short}.bsd.success" ] || ls "${_tests_tmp_dir}/${_comp_short}".freebsd*.skipped >/dev/null 2>&1); }; then
          _new_line=$(printf '%s' "${_new_line}" | sed 's/\[ \] FreeBSD/[x] FreeBSD/')
        fi
        if [ "${_r_macos}" = "✅" ] || [ "${_r_macos}" = "-" ] || { [ -d "${_tests_tmp_dir}" ] && (set +f; ls "${_tests_tmp_dir}/${_comp_short}".darwin*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".macos*.success >/dev/null 2>&1 || ls "${_tests_tmp_dir}/${_comp_short}".darwin*.skipped >/dev/null 2>&1); }; then
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
  _sync_plans="${LIBSCRIPT_SYNC_PLAN_CHECKBOXES:-0}"

  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h|/\?|-\?)
        show_help
        exit 0
        ;;
      --sync-plan-checkboxes|--sync-plans)
        _sync_plans=1
        shift
        ;;
      --output=*)
        _output="${1#*=}"
        shift
        ;;
      --output)
        _output="$2"
        shift 2
        ;;
      --json=*)
        _json="${1#*=}"
        shift
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
  if [ "${_sync_plans}" = "1" ]; then
    update_todo_plan "${_repo}" "${_output}"
    update_testing_todo_plan "${_repo}" "${_output}"
    update_retest_plan "${_repo}" "${_output}"
  fi
  printf '%s\n' 'Done updating Supported Components in README.md.'
}

main "$@"
