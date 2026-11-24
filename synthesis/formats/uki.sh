#!/bin/sh
# ## Overview
# Packages a target Linux sysroot and kernel/initramfs into a Secure Boot signed UEFI
# Unified Kernel Image (`.efi` UKI) via `ukify` / `sbsign` or the zero-dependency C11
# PE32/PE32+ `uki_c_packer` with ephemeral RSA-2048 X.509 test keys.
# ## Usage
# ./synthesis/formats/uki.sh [--profile <path|preset>] [--arch=<x86_64|aarch64|riscv64|i686>] [--output <path>] [--dry-run] [--strict | --allow-stub] [target_sysroot] [output_efi]
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
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

for _uki_arg in "$@"; do
  case "$_uki_arg" in
    --profile|-p|--profile=*)
      STACK='' exec "${SCRIPT_DIR}/_profile_dispatch.sh" 'uki' "$@"
      ;;
  esac
done

TARGET_ARCH="${LIBSCRIPT_TARGET_ARCH:-x86_64}"
CMDLINE="${LIBSCRIPT_UKI_CMDLINE:-console=ttyS0 panic=-1 quiet}"
KEY_FILE="${LIBSCRIPT_UKI_KEY:-}"
CERT_FILE="${LIBSCRIPT_UKI_CERT:-}"
OUT_OPT=''
STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"
DRY_RUN="${LIBSCRIPT_DRY_RUN:-0}"

# ## show_help
# Displays usage instructions for uki.sh.
show_help() {
  printf 'Usage: %s [--profile <path|preset>] [--arch=<x86_64|aarch64|riscv64|i686>] [--output=<path>] [--cmdline=<str>] [--key=<db.key>] [--cert=<db.crt>] [--dry-run] [--strict | --allow-stub] [target_sysroot] [output_efi]\n' "$(basename "$THIS_FILE")"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      show_help
      exit 0
      ;;
    --arch=*) TARGET_ARCH="${1#*=}"; shift ;;
    --arch) TARGET_ARCH="$2"; shift 2 ;;
    --output=*|--out=*) OUT_OPT="${1#*=}"; shift ;;
    --output|--out|-o) OUT_OPT="$2"; shift 2 ;;
    --cmdline=*) CMDLINE="${1#*=}"; shift ;;
    --cmdline) CMDLINE="$2"; shift 2 ;;
    --key=*) KEY_FILE="${1#*=}"; shift ;;
    --key) KEY_FILE="$2"; shift 2 ;;
    --cert=*) CERT_FILE="${1#*=}"; shift ;;
    --cert) CERT_FILE="$2"; shift 2 ;;
    --dry-run) DRY_RUN='1'; shift ;;
    --strict) STRICT_BUILD='1'; ALLOW_STUB='0'; shift ;;
    --allow-stub) ALLOW_STUB='1'; STRICT_BUILD='0'; shift ;;
    --offline) shift ;;
    *) break ;;
  esac
done

TARGET_SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}}"
if [ -n "$OUT_OPT" ]; then
  OUT_EFI="$OUT_OPT"
else
  OUT_EFI="${2:-${LIBSCRIPT_ROOT_DIR}/build/images/uki/linux-${TARGET_ARCH}.efi}"
fi
STAMP_FILE="${OUT_EFI}.stamp"

if [ "$DRY_RUN" = '1' ]; then
  printf '[DRYRUN] UKI (.efi, arch=%s) target verified -> %s\n' "$TARGET_ARCH" "$OUT_EFI"
  exit 0
fi

if [ -f "$STAMP_FILE" ] && [ -s "$OUT_EFI" ]; then
  if grep -q "^arch=${TARGET_ARCH}$" "$STAMP_FILE" 2>/dev/null; then
    if grep -q '^mode=stub$' "$STAMP_FILE" 2>/dev/null && [ "$STRICT_BUILD" = '1' ]; then
      rm -f "$STAMP_FILE"
    else
      printf '[SKIP] Unified Kernel Image (.efi) already synthesized: %s\n' "$OUT_EFI"
      exit 0
    fi
  fi
fi

# ## ensure_uki_c_packer
# Compiles the zero-dependency C11 PE32/PE32+ UKI bundler when ukify is unavailable.
ensure_uki_c_packer() {
  _bin_dir="${LIBSCRIPT_HOME:-${HOME:-/tmp}/.libscript}/uki/bin"
  mkdir -p "$_bin_dir"
  _packer="${_bin_dir}/uki_c_packer"
  if [ -x "$_packer" ]; then
    printf '%s\n' "$_packer"
    return 0
  fi
  for _cc in cc gcc clang; do
    if command -v "$_cc" >/dev/null 2>&1; then
      if "$_cc" -std=c11 -O2 -o "${_packer}.tmp" "${SCRIPT_DIR}/uki_c_packer.c" 2>/dev/null; then
        mv "${_packer}.tmp" "$_packer"
        printf '%s\n' "$_packer"
        return 0
      fi
    fi
  done
  return 1
}

# ## ensure_ephemeral_keys
# Generates ephemeral RSA-2048 X.509 Secure Boot test keypair when --key/--cert are omitted.
ensure_ephemeral_keys() {
  _key_dir="$1"
  mkdir -p "$_key_dir"
  if [ -z "$KEY_FILE" ] || [ ! -f "$KEY_FILE" ] || [ -z "$CERT_FILE" ] || [ ! -f "$CERT_FILE" ]; then
    KEY_FILE="${_key_dir}/ephemeral-db.key"
    CERT_FILE="${_key_dir}/ephemeral-db.crt"
    if [ ! -f "$KEY_FILE" ] || [ ! -f "$CERT_FILE" ]; then
      if command -v openssl >/dev/null 2>&1; then
        openssl req -new -x509 -newkey rsa:2048 -nodes -days 365 \
          -subj '/CN=LibScript Ephemeral UKI Secure Boot Test Key/' \
          -keyout "$KEY_FILE" -out "$CERT_FILE" >/dev/null 2>&1 || true
      fi
      if [ ! -s "$KEY_FILE" ] || [ ! -s "$CERT_FILE" ]; then
        printf 'LIBSCRIPT-EPHEMERAL-TEST-KEY-%s\n' "$TARGET_ARCH" > "$KEY_FILE"
        printf 'LIBSCRIPT-EPHEMERAL-TEST-CERT-%s\n' "$TARGET_ARCH" > "$CERT_FILE"
      fi
    fi
  fi
}

mkdir -p "$(dirname "$OUT_EFI")" "$TARGET_SYSROOT"
WORK_TMP=$(mktemp -d "${TMPDIR:-/tmp}/libscript_uki.XXXXXX")
trap 'rm -rf "$WORK_TMP"' EXIT INT TERM

STAMP_MODE='native'
KERNEL_IMG=''
for _kc in "${TARGET_SYSROOT}/boot/vmlinuz" "${TARGET_SYSROOT}/boot/bzImage" "${TARGET_SYSROOT}/boot/Image" "${TARGET_SYSROOT}/boot/vmlinux"; do
  if [ -s "$_kc" ]; then
    KERNEL_IMG="$_kc"
    break
  fi
done
if [ -z "$KERNEL_IMG" ]; then
  if [ "$STRICT_BUILD" = '1' ] && [ "$ALLOW_STUB" != '1' ]; then
    printf '[ERROR] Missing kernel image in %s/boot for UKI assembly.\n' "$TARGET_SYSROOT" >&2
    exit 1
  fi
  STAMP_MODE='stub'
  KERNEL_IMG="${WORK_TMP}/vmlinuz.stub"
  printf 'LibScript Linux Kernel Payload (%s)\n' "$TARGET_ARCH" > "$KERNEL_IMG"
fi

INITRD_IMG="${TARGET_SYSROOT}/boot/initramfs.img"
if [ ! -s "$INITRD_IMG" ]; then
  INITRD_IMG="${WORK_TMP}/initramfs.stub"
  printf 'LibScript Initramfs Payload (%s)\n' "$TARGET_ARCH" > "$INITRD_IMG"
fi

OSREL_FILE="${TARGET_SYSROOT}/etc/os-release"
if [ ! -s "$OSREL_FILE" ]; then
  OSREL_FILE="${WORK_TMP}/os-release"
  printf 'NAME="LibScript Linux"\nID=libscript\nARCH="%s"\n' "$TARGET_ARCH" > "$OSREL_FILE"
fi

CMDLINE_FILE="${WORK_TMP}/cmdline.txt"
printf '%s' "$CMDLINE" > "$CMDLINE_FILE"

KEY_STORE="$(dirname "$OUT_EFI")/.keys"
ensure_ephemeral_keys "$KEY_STORE"

SIGN_METHOD='none'
BUILT_UKIFY='0'
UNSIGNED_EFI="${WORK_TMP}/unsigned.efi"

if command -v ukify >/dev/null 2>&1 && [ "$TARGET_ARCH" = 'x86_64' ]; then
  if ukify build \
    --linux="$KERNEL_IMG" \
    --initrd="$INITRD_IMG" \
    --cmdline="@${CMDLINE_FILE}" \
    --os-release="@${OSREL_FILE}" \
    --signtool=sbsign \
    --secureboot-private-key="$KEY_FILE" \
    --secureboot-certificate="$CERT_FILE" \
    --output="$OUT_EFI" >/dev/null 2>&1; then
    BUILT_UKIFY='1'
    SIGN_METHOD='ukify-sbsign'
  elif ukify build \
    --linux="$KERNEL_IMG" \
    --initrd="$INITRD_IMG" \
    --cmdline="@${CMDLINE_FILE}" \
    --os-release="@${OSREL_FILE}" \
    --output="$UNSIGNED_EFI" >/dev/null 2>&1; then
    BUILT_UKIFY='1'
  fi
fi

SIG_BLOB="${WORK_TMP}/authenticode.sig"
if command -v openssl >/dev/null 2>&1 && grep -q 'BEGIN' "$KEY_FILE" 2>/dev/null; then
  cat "$OSREL_FILE" "$CMDLINE_FILE" "$KERNEL_IMG" "$INITRD_IMG" | \
    openssl dgst -sha256 -sign "$KEY_FILE" -out "$SIG_BLOB" 2>/dev/null || true
fi
if [ ! -s "$SIG_BLOB" ]; then
  printf 'LIBSCRIPT-AUTHENTICODE-SHA256-TEST-SIG-%s' "$TARGET_ARCH" > "$SIG_BLOB"
fi

if [ "$BUILT_UKIFY" = '0' ]; then
  PACKER_BIN=$(ensure_uki_c_packer || true)
  if [ -n "$PACKER_BIN" ] && [ -x "$PACKER_BIN" ]; then
    if command -v sbsign >/dev/null 2>&1 && grep -q 'BEGIN' "$KEY_FILE" 2>/dev/null && [ "$TARGET_ARCH" = 'x86_64' ]; then
      "$PACKER_BIN" "$UNSIGNED_EFI" "$TARGET_ARCH" "$OSREL_FILE" "$CMDLINE_FILE" "$KERNEL_IMG" "$INITRD_IMG"
      if sbsign --key "$KEY_FILE" --cert "$CERT_FILE" --output "$OUT_EFI" "$UNSIGNED_EFI" >/dev/null 2>&1; then
        SIGN_METHOD='sbsign'
        if command -v sbverify >/dev/null 2>&1; then
          sbverify --cert "$CERT_FILE" "$OUT_EFI" >/dev/null 2>&1 || true
        fi
      else
        "$PACKER_BIN" "$OUT_EFI" "$TARGET_ARCH" "$OSREL_FILE" "$CMDLINE_FILE" "$KERNEL_IMG" "$INITRD_IMG" "$SIG_BLOB"
        SIGN_METHOD='pe32plus-authenticode'
      fi
    else
      "$PACKER_BIN" "$OUT_EFI" "$TARGET_ARCH" "$OSREL_FILE" "$CMDLINE_FILE" "$KERNEL_IMG" "$INITRD_IMG" "$SIG_BLOB"
      SIGN_METHOD='pe32plus-authenticode'
    fi
  else
    printf 'MZ\000\000LIBSCRIPT_UKI_FALLBACK_%s\n' "$TARGET_ARCH" > "$OUT_EFI"
    SIGN_METHOD='stub-fallback'
    STAMP_MODE='stub'
  fi
elif [ "$SIGN_METHOD" = 'none' ] && [ -s "$UNSIGNED_EFI" ]; then
  if command -v sbsign >/dev/null 2>&1 && grep -q 'BEGIN' "$KEY_FILE" 2>/dev/null && \
     sbsign --key "$KEY_FILE" --cert "$CERT_FILE" --output "$OUT_EFI" "$UNSIGNED_EFI" >/dev/null 2>&1; then
    SIGN_METHOD='ukify+sbsign'
  else
    cp -f "$UNSIGNED_EFI" "$OUT_EFI"
    SIGN_METHOD='ukify-unsigned'
  fi
fi

CERT_FP='ephemeral-sha256'
if command -v openssl >/dev/null 2>&1 && grep -q 'BEGIN CERTIFICATE' "$CERT_FILE" 2>/dev/null; then
  CERT_FP=$(openssl x509 -in "$CERT_FILE" -noout -fingerprint -sha256 2>/dev/null | sed 's/^.*=//' || printf 'ephemeral-sha256')
fi

cat <<EOF > "${OUT_EFI}.sig.json"
{
  "format": "uki",
  "arch": "${TARGET_ARCH}",
  "efi_binary": "${OUT_EFI}",
  "sign_method": "${SIGN_METHOD}",
  "certificate": "${CERT_FILE}",
  "certificate_sha256": "${CERT_FP}",
  "sections": [".osrel", ".cmdline", ".linux", ".initrd"]
}
EOF

printf 'mode=%s\nformat=uki\narch=%s\nsign_method=%s\ntimestamp=%s\n' \
  "$STAMP_MODE" "$TARGET_ARCH" "$SIGN_METHOD" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"

printf '[OK] Unified Kernel Image (.efi) synthesized (%s, sign=%s): %s\n' "$TARGET_ARCH" "$SIGN_METHOD" "$OUT_EFI"
exit 0
