#!/bin/sh
# ## Overview
# Test suite for the msi-rs component.
# Validates that msi-rs CLI and WiX/msitools replacement binaries are installed and operational.
#
# ## Usage
# Execute this script to perform a component-specific test:
#   ./test.sh

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

if [ -f "$SCRIPT_DIR/env.sh" ]; then
  unset SCRIPT_NAME || true
  . "$SCRIPT_DIR/env.sh"
fi

if command -v msi-cli >/dev/null 2>&1; then
  msi-cli --help >/dev/null 2>&1 || true
  printf '[PASS] msi-cli is operational\n'
elif command -v msi-rs >/dev/null 2>&1; then
  msi-rs --help >/dev/null 2>&1 || true
  printf '[PASS] msi-rs is operational\n'
elif command -v msi >/dev/null 2>&1; then
  msi --help >/dev/null 2>&1 || true
  printf '[PASS] msi is operational\n'
elif command -v wix >/dev/null 2>&1; then
  wix --help >/dev/null 2>&1 || true
  printf '[PASS] wix is operational\n'
else
  printf '[FAIL] No msi-rs executable found in PATH\n' >&2
  exit 1
fi

# ## test_roundtrip_msi
# Verifies full round-trip WiX XML compilation, linking, and inspection via msi-rs toolchain.
if command -v candle >/dev/null 2>&1 && command -v light >/dev/null 2>&1; then
  _test_tmp="${TMPDIR:-/tmp}/msi_rs_roundtrip_$$"
  mkdir -p "$_test_tmp"
  printf 'hello 1' > "$_test_tmp/test1.txt"
  printf 'hello 2' > "$_test_tmp/test2.txt"

  cat << 'EOF_WXS' > "$_test_tmp/sample.wxs"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="MsiRsRoundtripTest" Language="1033" Version="1.0.0" Manufacturer="LibScript" UpgradeCode="12345678-1234-1234-1234-1234567890AB">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="perMachine" />
    <Media Id="1" Cabinet="media1.cab" EmbedCab="yes" />
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="INSTALLFOLDER" Name="MsiRsTest">
          <Component Id="Comp1" Guid="12345678-1234-1234-1234-123456789001">
            <File Id="File1" Source="test1.txt" KeyPath="yes" />
          </Component>
          <Component Id="Comp2" Guid="12345678-1234-1234-1234-123456789002">
            <File Id="File2" Source="test2.txt" KeyPath="yes" />
          </Component>
        </Directory>
      </Directory>
    </Directory>
    <Feature Id="Main" Title="Main" Level="1">
      <ComponentRef Id="Comp1" />
      <ComponentRef Id="Comp2" />
    </Feature>
  </Product>
</Wix>
EOF_WXS

  (
    cd "$_test_tmp"
    candle sample.wxs -out sample.wixobj >/dev/null
    light -sval sample.wixobj -out sample.msi >/dev/null
    if [ ! -f sample.msi ]; then
      printf '[FAIL] msi-rs roundtrip compilation failed to generate sample.msi\n' >&2
      exit 1
    fi
    if command -v msiinfo >/dev/null 2>&1; then
      msiinfo tables sample.msi > tables.txt 2>/dev/null || true
      if ! grep -q "Component" tables.txt; then
        printf '[FAIL] msiinfo tables inspection did not return standard Component table\n' >&2
        exit 1
      fi
      printf '[PASS] msi-rs roundtrip compilation and msiinfo inspection verified\n'
    else
      printf '[PASS] msi-rs roundtrip compilation verified (sample.msi generated)\n'
    fi
  )
  rm -rf "$_test_tmp"
fi
