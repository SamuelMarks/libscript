#!/bin/sh
# ## Overview
# Audits shell scripts across the repository for strict POSIX compliance:
# ensures #!/bin/sh shebang, set -feu, absence of bashisms, canonical THIS_FILE=
# resolution dance, and matching Windows batch (.cmd) companion scripts.
#
# ## Usage
# ./devtools/audit/audit_posix.sh [file1.sh file2.sh ...]

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
export LIBSCRIPT_ROOT_DIR

printf '=== LibScript POSIX Compliance & Bashism Prohibition Audit ===
'

ERRORS=0

# ## audit_file
# Validates individual file against strict POSIX /bin/sh invariants and Windows batch pairing.
audit_file() {
  file="$1"
  [ -f "$file" ] || return 0
  case "$file" in
    *audit_posix.sh) return 0 ;;
  esac

  # 1. Shebang check
  first_line=$(head -n 1 "$file")
  if [ "$first_line" != "#!/bin/sh" ]; then
    printf '[FAIL] [%s] Line 1 must be #!/bin/sh (found: %s)
' "$file" "$first_line" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 2. set -feu check
  if ! head -n 35 "$file" | grep -q "set -feu"; then
    printf '[FAIL] [%s] Missing `set -feu` declaration in header
' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 3. Canonical THIS_FILE= dance check
  if ! head -n 65 "$file" | grep -q 'THIS_FILE='; then
    printf '[FAIL] [%s] Missing canonical THIS_FILE= resolution dance in first 65 lines
' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 4. Banned Bashisms checks
  if grep -E '(if[[:space:]]+\[\[|[[:space:]]\[\[[[:space:]]|&&[[:space:]]*\[\[|\|\|[[:space:]]*\[\[)' "$file" >/dev/null 2>&1; then
    printf '[FAIL] [%s] Banned bashism: `[[ ... ]]` condition syntax detected\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  if grep -nE '^[[:space:]]*function[[:space:]]+[a-zA-Z0-9_]+([[:space:]]*\([[:space:]]*\))?[[:space:]]*\{?[[:space:]]*$' "$file" >/dev/null 2>&1; then
    printf '[FAIL] [%s] Banned bashism: `function foo()` syntax detected\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  if grep -nE '^[[:space:]]*source[[:space:]]+|[;&|][[:space:]]*source[[:space:]]+' "$file" >/dev/null 2>&1; then
    printf '[FAIL] [%s] Banned bashism: `source` used instead of POSIX `.`\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  if grep -nE '^[[:space:]]*echo[[:space:]]+-e[[:space:]]+|[;&|][[:space:]]*echo[[:space:]]+-e[[:space:]]+' "$file" >/dev/null 2>&1; then
    printf '[FAIL] [%s] Banned bashism: `echo -e` used instead of `printf`\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 5. Matching .cmd companion check
  cmd_companion="${file%.sh}.cmd"
  if [ ! -f "$cmd_companion" ]; then
    printf '[FAIL] [%s] Missing paired Windows batch companion: %s
' "$file" "$cmd_companion" >&2
    ERRORS=$((ERRORS + 1))
  else
    if ! head -n 25 "$cmd_companion" | grep -qi "EnableDelayedExpansion"; then
      printf '[FAIL] [%s] Windows companion missing EnableDelayedExpansion
' "$cmd_companion" >&2
      ERRORS=$((ERRORS + 1))
    fi
    if ! head -n 25 "$cmd_companion" | grep -qi "THIS_FILE="; then
      printf '[FAIL] [%s] Windows companion missing THIS_FILE= definition
' "$cmd_companion" >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi
}

if [ $# -gt 0 ]; then
  for target in "$@"; do
    audit_file "$target"
  done
else
  # Audit all scripts created in LFS subdirectories
  for script in \
    cli/commands/config/validate_lfs_profile.sh \
    _lib/toolchains/lfs-toolchain/setup.sh \
    _lib/base-system/lfs-temp-tools/setup.sh \
    _lib/base-system/lfs-mount-vfs.sh \
    _lib/base-system/lfs-chroot.sh \
    _lib/base-system/lfs-base/setup.sh \
    _lib/kernel/setup.sh \
    _lib/init-systems/setup.sh \
    _lib/init-systems/sysvinit/setup.sh \
    _lib/init-systems/runit/setup.sh \
    _lib/init-systems/s6/setup.sh \
    _lib/init-systems/dinit/setup.sh \
    _lib/display-servers/setup.sh \
    _lib/desktops/setup.sh \
    _lib/desktops/openbox/setup.sh \
    _lib/display-managers/setup.sh \
    _lib/audio/setup.sh \
    _lib/graphics/setup.sh \
    _lib/networking/setup.sh \
    cli/commands/package_as/disk_builder.sh \
    cli/commands/package_as/vagrant_box.sh \
    tests/vagrant_box_test.sh; do
    audit_file "$script"
  done
fi

if [ "$ERRORS" -gt 0 ]; then
  printf '[ERROR] Audit failed with %d standards violations!
' "$ERRORS" >&2
  exit 1
fi

printf '[PASS] All audited scripts strictly adhere to POSIX /bin/sh and companion requirements.
'
exit 0
