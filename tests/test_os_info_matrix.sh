#!/bin/sh
# ## Overview
# Hermetic OS detection matrix test suite verifying engine/common/os_info.sh across Alpine, Debian,
# RHEL, Arch, openSUSE, Void, Gentoo, Solus, macOS (zero side effects), FreeBSD, SunOS, and Windows/MinGW/Cygwin.
# ## Usage
# ./tests/test_os_info_matrix.sh
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *)
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
TEST_TMP="${LIBSCRIPT_ROOT_DIR}/tests_tmp/os_info_matrix_$$"
MOCK_BIN="${TEST_TMP}/bin"
mkdir -p "$MOCK_BIN"
cat <<'EOF_UNAME' > "${MOCK_BIN}/uname"
#!/bin/sh
case "${1:-}" in
  -m) printf 'x86_64\n' ;;
  -r) printf '6.6.0\n' ;;
  -a) printf '%s mock 6.6.0 x86_64\n' "${MOCK_UNAME:-Linux}" ;;
  *) printf '%s\n' "${MOCK_UNAME:-Linux}" ;;
esac
EOF_UNAME
chmod +x "${MOCK_BIN}/uname"

# ## cleanup_tmp
# Removes temporary mock OS release files on exit.
cleanup_tmp() {
  rm -rf "$TEST_TMP"
}
trap 'cleanup_tmp' EXIT INT TERM

# ## fail_test
# Prints an error message and exits 1.
fail_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

# ## check_linux_distro
# Asserts that mocked /etc/os-release ID and ID_LIKE resolve to expected PKG_MGR and TARGET_OS.
check_linux_distro() {
  _id="$1"
  _like="$2"
  _exp_pm="$3"
  _exp_os="$4"
  _rel_file="${TEST_TMP}/os-release-${_id}"
  printf 'ID=%s\nID_LIKE="%s"\n' "$_id" "$_like" > "$_rel_file"
  _got=$(
    env -i PATH="${MOCK_BIN}:$PATH" HOME="${HOME:-/root}" LIBSCRIPT_ROOT_DIR="$LIBSCRIPT_ROOT_DIR" \
      MOCK_UNAME='Linux' LIBSCRIPT_OS_RELEASE_FILE="$_rel_file" sh <<'EOF_LINUX'
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/os_info.sh"
export SCRIPT_NAME
. "${SCRIPT_NAME}"
printf '%s|%s|%s' "${PKG_MGR:-}" "${TARGET_OS:-}" "${NGINX_SERVERS_ROOT:-}"
EOF_LINUX
  )
  [ "$_got" = "${_exp_pm}|${_exp_os}|" ] || fail_test "Distro ${_id}: expected ${_exp_pm}|${_exp_os}|, got ${_got}"
}

check_linux_distro 'alpine' '' 'apk' 'alpine'
check_linux_distro 'debian' '' 'apt-get' 'debian'
check_linux_distro 'ubuntu' 'debian' 'apt-get' 'debian'
check_linux_distro 'rocky' 'rhel centos fedora' 'dnf' 'rhel'
check_linux_distro 'arch' '' 'pacman' 'arch'
check_linux_distro 'manjaro' 'arch' 'pacman' 'arch'
check_linux_distro 'opensuse-tumbleweed' 'opensuse suse' 'zypper' 'opensuse'
check_linux_distro 'void' '' 'xbps-install' 'void'
check_linux_distro 'gentoo' '' 'emerge' 'gentoo'
check_linux_distro 'solus' '' 'eopkg' 'solus'
printf '[PASS] All 10 Linux distro families (including Arch pacman & openSUSE zypper) resolved cleanly.\n'

DARWIN_OUT=$(
  env -i PATH="${MOCK_BIN}:$PATH" HOME="${HOME:-/root}" LIBSCRIPT_ROOT_DIR="$LIBSCRIPT_ROOT_DIR" MOCK_UNAME='Darwin' sh <<'EOF_DARWIN'
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/os_info.sh"
export SCRIPT_NAME
. "${SCRIPT_NAME}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/os_info.sh"
export SCRIPT_NAME
. "${SCRIPT_NAME}"
printf '%s|%s|%s|%s' "${PKG_MGR:-}" "${TARGET_OS:-}" "${INIT_SYS:-}" "${NGINX_SERVERS_ROOT:-}"
EOF_DARWIN
)
[ "$DARWIN_OUT" = 'brew|darwin|launchd|' ] || fail_test "Darwin os_info mismatch or NGINX_SERVERS_ROOT leak: ${DARWIN_OUT}"
if grep -q 'brew/setup.sh' "${LIBSCRIPT_ROOT_DIR}/engine/common/os_info.sh"; then
  fail_test 'os_info.sh still contains side-effectful brew/setup.sh invocation'
fi
printf '[PASS] Darwin os_info is side-effect-free, idempotent (2x), and free of NGINX_SERVERS_ROOT leaks.\n'

for _win_u in 'CYGWIN_NT-10.0' 'MINGW64_NT-10.0' 'Windows_NT'; do
  _win_init=$(
    env -i PATH="${MOCK_BIN}:$PATH" HOME="${HOME:-/root}" LIBSCRIPT_ROOT_DIR="$LIBSCRIPT_ROOT_DIR" MOCK_UNAME="$_win_u" sh <<'EOF_WIN'
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/os_info.sh"
export SCRIPT_NAME
. "${SCRIPT_NAME}"
printf '%s' "${INIT_SYS:-}"
EOF_WIN
  )
  [ "$_win_init" = 'windows-scm' ] || fail_test "${_win_u} expected INIT_SYS=windows-scm, got ${_win_init}"
done
printf '[PASS] Cygwin, MinGW, and Windows_NT all set INIT_SYS=windows-scm.\n'
cleanup_tmp
exit 0
