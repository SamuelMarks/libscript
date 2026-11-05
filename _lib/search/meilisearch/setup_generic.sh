#!/bin/sh
# ## Overview
# Generic setup module for Meilisearch.
# 
# ## Usage
# Performs cross-platform binary download or package manager installation of Meilisearch.

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

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

MEILISEARCH_INSTALL_METHOD="$(libscript_resolve_install_method "MEILISEARCH")"
ACTION="${ACTION:-install}"
VERSION="${MEILISEARCH_VERSION:-v1.36.0}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ]; then
    EXACT_VERSION='v1.36.0'
  else
    EXACT_VERSION="${VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if command -v meilisearch >/dev/null 2>&1; then
      meilisearch --version
    else
      printf 'meilisearch not installed\n'
    fi
    exit 0
    ;;
  ls-remote)
    printf 'v1.34.0
v1.35.0
v1.36.0
'
    exit 0
    ;;
  install)
    resolve_exact_version
    log_info "Installing Meilisearch (${EXACT_VERSION}) via ${MEILISEARCH_INSTALL_METHOD}..."
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/meilisearch/${EXACT_VERSION}"
    if [ -f "${TARGET_DIR}/bin/meilisearch" ] && "${TARGET_DIR}/bin/meilisearch" --version >/dev/null 2>&1; then
      log_info "Meilisearch ${EXACT_VERSION} is already installed in ${TARGET_DIR}."
    else
      mkdir -p "${TARGET_DIR}/bin"
      # Resolve binary download URL
      OS_NAME='linux'
      if [ "${UNAME_LOWER}" = "darwin" ]; then
        OS_NAME='macos'
      elif [ "${UNAME_LOWER}" = "freebsd" ]; then
        OS_NAME='freebsd'
      fi

      ARCH_NAME='amd64'
      case "${ARCH:-x86_64}" in
        x86_64|amd64) ARCH_NAME="amd64" ;;
        aarch64|arm64)
          if [ "$OS_NAME" = "macos" ]; then
            ARCH_NAME='apple-silicon'
          else
            ARCH_NAME='aarch64'
          fi
          ;;
      esac

      BIN_URL="https://github.com/meilisearch/meilisearch/releases/download/${EXACT_VERSION}/meilisearch-${OS_NAME}-${ARCH_NAME}"
      TEMP_BIN=$(mktemp)
      if libscript_download "${BIN_URL}" "${TEMP_BIN}" 2>/dev/null; then
        mv "${TEMP_BIN}" "${TARGET_DIR}/bin/meilisearch"
        chmod +x "${TARGET_DIR}/bin/meilisearch"
        if [ -f "/etc/alpine-release" ] && command -v apk >/dev/null 2>&1; then
          libscript_depends gcompat gcc musl-dev >/dev/null 2>&1 || true
          priv mkdir -p /usr/local/lib
          _shim_src=$(mktemp)
          cat << 'CSRC' > "$_shim_src"
int __res_init(void) { return 0; }
int res_init(void) { return 0; }
int __register_atfork(void (*prepare)(void), void (*parent)(void), void (*child)(void), void *dso_handle) { return 0; }
const char *gnu_get_libc_version(void) { return "2.38"; }
CSRC
          priv gcc -shared -fPIC -x c "$_shim_src" -o /usr/local/lib/libresinit.so 2>/dev/null || true
          rm -f "$_shim_src"
          if [ -f "/usr/local/lib/libresinit.so" ]; then
            mv "${TARGET_DIR}/bin/meilisearch" "${TARGET_DIR}/bin/meilisearch.bin"
            cat << 'SHIM' > "${TARGET_DIR}/bin/meilisearch"
#!/bin/sh
export LD_PRELOAD="/usr/local/lib/libresinit.so:/lib/libgcompat.so.0:${LD_PRELOAD:-}"
exec "$(dirname "$0")/meilisearch.bin" "$@"
SHIM
            chmod +x "${TARGET_DIR}/bin/meilisearch"
          fi
        elif ! "${TARGET_DIR}/bin/meilisearch" --version >/dev/null 2>&1; then
          if command -v ldd >/dev/null 2>&1 && ldd "${TARGET_DIR}/bin/meilisearch" 2>&1 | grep -q "GLIBC_2.35"; then
            if ! command -v gcc >/dev/null 2>&1; then
              libscript_depends gcc glibc-devel >/dev/null 2>&1 || true
            fi
            _shim_src=$(mktemp)
            _map_src=$(mktemp)
            cat << 'CSRC' > "$_shim_src"
#include <math.h>
double __hypot_shim(double x, double y) { return sqrt(x * x + y * y); }
__asm__(".symver __hypot_shim,hypot@@GLIBC_2.29");
CSRC
            cat << 'MSRC' > "$_map_src"
GLIBC_2.29 {
  global: hypot;
};
MSRC
            gcc -shared -fPIC -O2 -x c "$_shim_src" -Wl,--version-script="$_map_src" -lm -o "${TARGET_DIR}/bin/libmeili_glibc235.so" 2>/dev/null || true
            rm -f "$_shim_src" "$_map_src"
            if [ -f "${TARGET_DIR}/bin/libmeili_glibc235.so" ]; then
              mv "${TARGET_DIR}/bin/meilisearch" "${TARGET_DIR}/bin/meilisearch.bin"
              if command -v python3 >/dev/null 2>&1; then
                python3 -c '
import struct, sys
path = sys.argv[1]
replacements = {"GLIBC_2.35": "GLIBC_2.29"}
with open(path, "rb") as f:
    data = bytearray(f.read())
if data[:4] == b"\x7fELF" and data[4] == 2:
    e_shoff = struct.unpack_from("<Q", data, 40)[0]
    e_shentsize = struct.unpack_from("<H", data, 58)[0]
    e_shnum = struct.unpack_from("<H", data, 60)[0]
    verneed_off = verneed_cnt = verneed_link = 0
    for i in range(e_shnum):
        sh = e_shoff + i * e_shentsize
        if struct.unpack_from("<I", data, sh + 4)[0] == 0x6ffffffe:
            verneed_off = struct.unpack_from("<Q", data, sh + 24)[0]
            verneed_link = struct.unpack_from("<I", data, sh + 40)[0]
            verneed_cnt = struct.unpack_from("<I", data, sh + 44)[0]
    if verneed_off:
        dynstr_off = struct.unpack_from("<Q", data, e_shoff + verneed_link * e_shentsize + 24)[0]
        def get_str(off):
            end = data.find(0, dynstr_off + off)
            return bytes(data[dynstr_off + off:end]).decode("latin1")
        def elf_hash(s):
            h = 0
            for ch in s.encode("latin1"):
                h = ((h << 4) + ch) & 0xffffffff
                g = h & 0xf0000000
                if g: h ^= (g >> 24)
                h &= (~g) & 0xffffffff
            return h
        pos = verneed_off
        str_offsets = {}
        for _ in range(verneed_cnt):
            vn_version, vn_cnt, vn_file, vn_aux, vn_next = struct.unpack_from("<HHIII", data, pos)
            apos = pos + vn_aux
            for _ in range(vn_cnt):
                vna_hash, vna_flags, vna_other, vna_name, vna_next = struct.unpack_from("<IHHII", data, apos)
                str_offsets[get_str(vna_name)] = vna_name
                if vna_next == 0: break
                apos += vna_next
            if vn_next == 0: break
            pos += vn_next
        pos = verneed_off
        for _ in range(verneed_cnt):
            vn_version, vn_cnt, vn_file, vn_aux, vn_next = struct.unpack_from("<HHIII", data, pos)
            apos = pos + vn_aux
            for _ in range(vn_cnt):
                vna_hash, vna_flags, vna_other, vna_name, vna_next = struct.unpack_from("<IHHII", data, apos)
                name = get_str(vna_name)
                if name in replacements:
                    target = replacements[name]
                    new_name_off = str_offsets.get(target, vna_name)
                    if target not in str_offsets:
                        b_targ = target.encode("latin1") + b"\x00"
                        data[dynstr_off + vna_name:dynstr_off + vna_name + len(b_targ)] = b_targ
                    struct.pack_into("<IHHII", data, apos, elf_hash(target), vna_flags, vna_other, new_name_off, vna_next)
                if vna_next == 0: break
                apos += vna_next
            if vn_next == 0: break
            pos += vn_next
        with open(path, "wb") as f:
            f.write(data)
' "${TARGET_DIR}/bin/meilisearch.bin" 2>/dev/null || true
              fi
              cat << 'SHIM' > "${TARGET_DIR}/bin/meilisearch"
#!/bin/sh
_d=$(cd -- "$(dirname -- "$0")" && pwd)
export LD_PRELOAD="${_d}/libmeili_glibc235.so${LD_PRELOAD:+:${LD_PRELOAD}}"
exec "${_d}/meilisearch.bin" "$@"
SHIM
              chmod +x "${TARGET_DIR}/bin/meilisearch"
            fi
          fi
        fi
      else
        rm -f "${TEMP_BIN}"
        if command -v meilisearch >/dev/null 2>&1; then
          ln -sf "$(command -v meilisearch)" "${TARGET_DIR}/bin/meilisearch"
        elif [ "${UNAME_LOWER}" = "freebsd" ]; then
          libscript_depends "meilisearch" || libscript_depends "textproc/meilisearch" || true
          if command -v meilisearch >/dev/null 2>&1; then
            ln -sf "$(command -v meilisearch)" "${TARGET_DIR}/bin/meilisearch"
          fi
        elif command -v cargo >/dev/null 2>&1; then
          log_info 'Compiling meilisearch from source via cargo...'
          cargo install meilisearch --root "${TARGET_DIR}" || true
        else
          log_warn 'Unable to download or install Meilisearch binary.'
        fi
      fi
    fi
    libscript_symlink_alias "meilisearch" "$VERSION" "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "meilisearch" "$ACTION" "$VERSION" "${MEILISEARCH_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
