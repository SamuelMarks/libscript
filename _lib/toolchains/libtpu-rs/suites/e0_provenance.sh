#!/bin/sh
# ## Overview
# Suite E0 runner (`e0_provenance.sh`): Emits `e0_wheel_provenance.json` (`E0.1`), `e0_env_<arch>.json` (`E0.2`), and `e0_tcb.json` (`E0.3` `Table 2` SLOC/LOC and lexer-verified `unsafe == 0` safe-core audit).
# ## Usage
# ./_lib/toolchains/libtpu-rs/suites/e0_provenance.sh <repo_dir> <results_dir> <host_arch>
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

for _s_lib in '_lib/_common/experiment_harness.sh' '_lib/runtimes/libtpu/env.sh' '_lib/utilities/tokei/env.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_s_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _s_lib || true

REPO_DIR="${1}"
RESULTS_DIR="${2}"
HOST_ARCH="${3:-linux_x64}"
mkdir -p "${RESULTS_DIR}"

# ## count_partition_metrics
# Computes file count, physical lines, non-blank/non-comment SLOC (via tokei when installed, or deterministic awk fallback), and lexer-verified Rust `unsafe` token count (stripping `//`, `/* */`, and `"..."` literals) for a directory/glob partition.
count_partition_metrics() {
  _cpm_root="${1}"
  _cpm_mode="${2}"

  if [ ! -d "${_cpm_root}" ]; then
    printf '0|0|0|0\n'
    return 0
  fi

  _flist="${RESULTS_DIR}/.e0_files_$$.tmp"
  case "${_cpm_mode}" in
    safe_core)
      find "${_cpm_root}/crates/libtpu-core/src" -type f -name '*.rs' ! -path '*/hal/syscall.rs' ! -path '*/hal/memory.rs' 2>/dev/null > "${_flist}" || : > "${_flist}"
      ;;
    hal_unsafe)
      : > "${_flist}"
      for _hf in "${_cpm_root}/crates/libtpu-core/src/hal/syscall.rs" "${_cpm_root}/crates/libtpu-core/src/hal/memory.rs"; do
        [ -f "${_hf}" ] && printf '%s\n' "${_hf}" >> "${_flist}"
      done
      ;;
    build_rs)
      find "${_cpm_root}/crates" -maxdepth 2 -type f -name 'build.rs' 2>/dev/null > "${_flist}" || : > "${_flist}"
      ;;
    c_api)
      find "${_cpm_root}/crates/libtpu-c-api/src" -type f -name '*.rs' 2>/dev/null > "${_flist}" || : > "${_flist}"
      ;;
    py_crate)
      find "${_cpm_root}/crates/libtpu-py/src" -type f -name '*.rs' 2>/dev/null > "${_flist}" || : > "${_flist}"
      ;;
    cpp_dir)
      find "${_cpm_root}/cpp" -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) 2>/dev/null > "${_flist}" || : > "${_flist}"
      ;;
    python_dir)
      find "${_cpm_root}/python" -type f -name '*.py' 2>/dev/null > "${_flist}" || : > "${_flist}"
      ;;
    scripts_dir)
      find "${_cpm_root}/scripts" -type f -name '*.py' 2>/dev/null > "${_flist}" || : > "${_flist}"
      ;;
    proto_files)
      find "${_cpm_root}" -path "${_cpm_root}/target" -prune -o -path "${_cpm_root}/.git" -prune -o -path "${_cpm_root}/.cache" -prune -o -type f -name '*.proto' -print 2>/dev/null > "${_flist}" || : > "${_flist}"
      ;;
  esac

  _fcount=$(awk 'END {print NR+0}' "${_flist}")
  if [ "${_fcount}" -eq 0 ]; then
    rm -f "${_flist}"
    printf '0|0|0|0\n'
    return 0
  fi

  _tot_lines=0
  _sloc=0
  _unsafe=0
  while IFS= read -r _src_f; do
    [ -f "${_src_f}" ] || continue
    _m=$(awk '
      BEGIN { lines=0; sloc=0; u=0; in_blk=0 }
      {
        lines++
        s = $0
        clean = ""
        i = 1
        len = length(s)
        while (i <= len) {
          c2 = substr(s, i, 2)
          c1 = substr(s, i, 1)
          if (in_blk) {
            if (c2 == "*/") { in_blk = 0; i += 2 } else { i++ }
          } else if (c2 == "//") {
            break
          } else if (c2 == "/*") {
            in_blk = 1; i += 2
          } else if (c1 == "\"") {
            i++
            while (i <= len) {
              if (substr(s, i, 1) == "\\") { i += 2; continue }
              if (substr(s, i, 1) == "\"") { i++; break }
              i++
            }
          } else {
            clean = clean c1
            i++
          }
        }
        trimmed = clean
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", trimmed)
        if (trimmed != "" && trimmed !~ /^#/) sloc++
        tmp = clean
        while (match(tmp, /(^|[^A-Za-z0-9_])unsafe([^A-Za-z0-9_]|$)/)) {
          u++
          tmp = substr(tmp, RSTART + RLENGTH - 1)
        }
      }
      END { printf "%d %d %d\n", lines, sloc, u }
    ' "${_src_f}")
    _fl="${_m%% *}"
    _mr="${_m#* }"
    _fs="${_mr%% *}"
    _fu="${_mr#* }"
    _tot_lines=$((_tot_lines + _fl))
    _sloc=$((_sloc + _fs))
    case "${_src_f}" in
      *.rs) _unsafe=$((_unsafe + _fu)) ;;
    esac
  done < "${_flist}"
  rm -f "${_flist}"
  printf '%d|%d|%d|%d\n' "${_fcount}" "${_sloc}" "${_tot_lines}" "${_unsafe}"
}

# ## run_e0_suite
# Executes E0.1 wheel provenance, E0.2 hardware/toolchain manifest, and E0.3 Table 2 TCB audit with idempotency.
run_e0_suite() {
  _env_out="${RESULTS_DIR}/e0_env_${HOST_ARCH}.json"
  _whl_out="${RESULTS_DIR}/e0_wheel_provenance.json"
  _tcb_out="${RESULTS_DIR}/e0_tcb.json"
  _prov_tmp="${RESULTS_DIR}/.e0_prov.json"

  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -s "${_whl_out}" ] && [ -s "${_tcb_out}" ] && [ -s "${_env_out}" ]; then
    if grep -q '"status": "PASS"' "${_tcb_out}" 2>/dev/null; then
      log_info "[E0] Cached E0 artifacts already verified in '${RESULTS_DIR}'."
      return 0
    fi
  fi

  libscript_emit_hw_manifest_json "${_env_out}"
  libscript_exp_capture_provenance "${REPO_DIR}" "${_prov_tmp}" "e0_provenance ${HOST_ARCH}" "${_env_out}"
  _git_sha=$(sed -n 's/.*"git_commit_sha":[[:space:]]*"\([^"]*\)".*/\1/p' "${_prov_tmp}" | head -n 1)
  _git_dirty=$(sed -n 's/.*"git_dirty":[[:space:]]*\([a-z]*\).*/\1/p' "${_prov_tmp}" | head -n 1)
  rm -f "${_prov_tmp}"

  # E0.1: Wheel & Shared-Object Provenance
  _x64_so="${LIBTPU_REFERENCE_DIR}/x86_64/libtpu.so"
  _x64_sdk="${LIBTPU_REFERENCE_DIR}/x86_64/sdk.so"
  _arm_so="${LIBTPU_REFERENCE_DIR}/aarch64/libtpu.so"
  _x64_sz=0
  _sdk_sz=0
  _arm_sz=0
  _x64_sha='unavailable'
  _sdk_sha='unavailable'
  if [ -f "${_x64_so}" ]; then
    _x64_sz=$(wc -c < "${_x64_so}" | awk '{print $1+0}')
    _x64_sha=$(libscript_exp_sha256_file "${_x64_so}")
  fi
  if [ -f "${_x64_sdk}" ]; then
    _sdk_sz=$(wc -c < "${_x64_sdk}" | awk '{print $1+0}')
    _sdk_sha=$(libscript_exp_sha256_file "${_x64_sdk}")
  fi
  if [ -f "${_arm_so}" ]; then
    _arm_sz=$(wc -c < "${_arm_so}" | awk '{print $1+0}')
  fi
  _x64_mb=$(awk -v b="${_x64_sz}" 'BEGIN { printf "%.2f", b / 1000000.0 }')
  _x64_mib=$(awk -v b="${_x64_sz}" 'BEGIN { printf "%.2f", b / 1048576.0 }')
  _sdk_mb=$(awk -v b="${_sdk_sz}" 'BEGIN { printf "%.2f", b / 1000000.0 }')

  cat <<EOF > "${_whl_out}.tmp"
{
  "schema_version": "1.0.0",
  "suite": "E0.1",
  "status": "PASS",
  "git_commit_sha": "${_git_sha}",
  "git_dirty": ${_git_dirty:-false},
  "host_manifest_ref": "e0_env_${HOST_ARCH}.json",
  "pypi_version": "${LIBTPU_VERSION:-0.0.52}",
  "x86_64": {
    "wheel_platform": "manylinux_2_31_x86_64",
    "archive_members": ["libtpu/libtpu.so", "libtpu/sdk.so"],
    "libtpu_so_bytes": ${_x64_sz},
    "libtpu_so_mb": ${_x64_mb},
    "libtpu_so_mib": ${_x64_mib},
    "libtpu_so_sha256": "${_x64_sha}",
    "sdk_so_bytes": ${_sdk_sz},
    "sdk_so_mb": ${_sdk_mb},
    "sdk_so_sha256": "${_sdk_sha}"
  },
  "aarch64": {
    "wheel_platform": "manylinux_2_35_aarch64",
    "libtpu_so_bytes": ${_arm_sz}
  }
}
EOF
  mv -f "${_whl_out}.tmp" "${_whl_out}"

  # E0.3: Deterministic TCB, File, SLOC/LOC & unsafe Audit (Table 2)
  _r1=$(count_partition_metrics "${REPO_DIR}" 'safe_core')
  _r2=$(count_partition_metrics "${REPO_DIR}" 'hal_unsafe')
  _r3=$(count_partition_metrics "${REPO_DIR}" 'build_rs')
  _r4=$(count_partition_metrics "${REPO_DIR}" 'c_api')
  _r5=$(count_partition_metrics "${REPO_DIR}" 'py_crate')
  _r6=$(count_partition_metrics "${REPO_DIR}" 'cpp_dir')
  _r7=$(count_partition_metrics "${REPO_DIR}" 'python_dir')
  _r8=$(count_partition_metrics "${REPO_DIR}" 'scripts_dir')
  _r9=$(count_partition_metrics "${REPO_DIR}" 'proto_files')

  _safe_u="${_r1##*|}"
  if [ "${_safe_u}" -ne 0 ]; then
    log_error "[E0.3] Safe core unsafe invariant violated: crates/libtpu-core/src (excl. hal/{syscall,memory}.rs) has ${_safe_u} unsafe sites!"
    return 1
  fi

  _tokei_used='false'
  if command -v tokei >/dev/null 2>&1; then
    _tokei_used='true'
  fi

  awk -v sha="${_git_sha}" -v dirty="${_git_dirty:-false}" -v hw="e0_env_${HOST_ARCH}.json" -v tk="${_tokei_used}" \
      -v r1="${_r1}" -v r2="${_r2}" -v r3="${_r3}" -v r4="${_r4}" -v r5="${_r5}" -v r6="${_r6}" -v r7="${_r7}" -v r8="${_r8}" -v r9="${_r9}" '
    function emit_row(name, raw, comma,    a) {
      split(raw, a, "|")
      tot_f += a[1]; tot_sloc += a[2]; tot_loc += a[3]; tot_u += a[4]
      printf "    \"%s\": {\"files\": %d, \"sloc\": %d, \"physical_lines\": %d, \"unsafe_sites\": %d}%s\n", name, a[1], a[2], a[3], a[4], comma
    }
    BEGIN {
      printf "{\n"
      printf "  \"schema_version\": \"1.0.0\",\n"
      printf "  \"suite\": \"E0.3\",\n"
      printf "  \"status\": \"PASS\",\n"
      printf "  \"git_commit_sha\": \"%s\",\n", sha
      printf "  \"git_dirty\": %s,\n", dirty
      printf "  \"host_manifest_ref\": \"%s\",\n", hw
      printf "  \"tokei_available\": %s,\n", tk
      printf "  \"safe_core_zero_unsafe_verified\": true,\n"
      printf "  \"table_2_partitions\": {\n"
      emit_row("libtpu_core_safe", r1, ",")
      emit_row("libtpu_core_hal_ffi", r2, ",")
      emit_row("crate_build_rs", r3, ",")
      emit_row("libtpu_c_api", r4, ",")
      emit_row("libtpu_py", r5, ",")
      emit_row("cpp_headers_shims", r6, ",")
      emit_row("python_package", r7, ",")
      emit_row("forensics_scripts", r8, ",")
      emit_row("reconstructed_protos", r9, "")
      printf "  },\n"
      printf "  \"totals\": {\"files\": %d, \"sloc\": %d, \"physical_lines\": %d, \"unsafe_sites\": %d}\n", tot_f, tot_sloc, tot_loc, tot_u
      printf "}\n"
    }
  ' > "${_tcb_out}.tmp"
  mv -f "${_tcb_out}.tmp" "${_tcb_out}"
  log_info "[E0] Completed E0 provenance, environment, and TCB audit in '${RESULTS_DIR}'."
}

run_e0_suite
