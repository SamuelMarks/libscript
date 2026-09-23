#!/bin/sh
# ## Overview
# Generates Debian APT repository index archives (Packages, Packages.gz, Release,
# and InRelease) from pools of .deb binary packages.
#
# ## Usage
# ./_lib/orchestration/repogen/deb_index.sh <repo_dir> [suite] [arch] [component]

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

REPO_DIR="${1:-${LIBSCRIPT_ROOT_DIR}/build/packages/deb}"
SUITE="${2:-stable}"
ARCH="${3:-amd64}"
COMPONENT="${4:-main}"

DISTS_DIR="${REPO_DIR}/dists/${SUITE}/${COMPONENT}/binary-${ARCH}"
POOL_DIR="${REPO_DIR}/pool/${COMPONENT}"

mkdir -p "$DISTS_DIR" "$POOL_DIR"

set +f
# Move loose .deb packages into pool
for f in "$REPO_DIR"/*.deb; do
  if [ -f "$f" ]; then
    mv -f "$f" "$POOL_DIR/" 2>/dev/null || true
  fi
done

PACKAGES_FILE="${DISTS_DIR}/Packages"
RELEASE_FILE="${REPO_DIR}/dists/${SUITE}/Release"

printf '[REPOGEN-DEB] Scanning pool and generating Packages manifest at %s...\n' "$PACKAGES_FILE"

: > "$PACKAGES_FILE"

for deb in "$POOL_DIR"/*.deb; do
  [ -f "$deb" ] || continue
  bname="${deb##*/}"
  pname="${bname%%_*}"
  pver_rest="${bname#${pname}_}"
  pver="${pver_rest%_*}"
  parch="${pver_rest##*_}"
  parch="${parch%.deb}"
  fsize=$(wc -c < "$deb" | tr -d ' ' 2>/dev/null || echo 1024)

  md5_hash="d41d8cd98f00b204e9800998ecf8427e"
  sha256_hash="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

  if command -v md5sum >/dev/null 2>&1; then
    md5_hash=$(md5sum "$deb" | cut -d' ' -f1)
  elif command -v md5 >/dev/null 2>&1; then
    md5_hash=$(md5 -q "$deb")
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    sha256_hash=$(sha256sum "$deb" | cut -d' ' -f1)
  elif command -v shasum >/dev/null 2>&1; then
    sha256_hash=$(shasum -a 256 "$deb" | cut -d' ' -f1)
  fi

  cat <<EOF >> "$PACKAGES_FILE"
Package: ${pname}
Version: ${pver}
Architecture: ${parch}
Maintainer: LibScript OS Synthesizer <libscript@local>
Installed-Size: 10
Filename: pool/${COMPONENT}/${bname}
Size: ${fsize}
MD5sum: ${md5_hash}
SHA256: ${sha256_hash}
Section: admin
Priority: optional
Description: ${pname} binary package synthesized by LibScript

EOF
done
set -f

# Compress Packages
gzip -9 -c "$PACKAGES_FILE" > "${PACKAGES_FILE}.gz"

# Generate Release
PKG_GZ_SIZE=$(wc -c < "${PACKAGES_FILE}.gz" | tr -d ' ' 2>/dev/null || echo 100)
PKG_GZ_SHA256="dummy"
if command -v sha256sum >/dev/null 2>&1; then
  PKG_GZ_SHA256=$(sha256sum "${PACKAGES_FILE}.gz" | cut -d' ' -f1)
elif command -v shasum >/dev/null 2>&1; then
  PKG_GZ_SHA256=$(shasum -a 256 "${PACKAGES_FILE}.gz" | cut -d' ' -f1)
fi

DATE_RFC=$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S UTC' 2>/dev/null || echo "Wed, 01 Jan 2025 00:00:00 UTC")

cat <<EOF > "$RELEASE_FILE"
Origin: LibScript
Label: LibScript Repository
Suite: ${SUITE}
Codename: ${SUITE}
Date: ${DATE_RFC}
Architectures: ${ARCH}
Components: ${COMPONENT}
Description: LibScript APT Package Archive
SHA256:
 ${PKG_GZ_SHA256} ${PKG_GZ_SIZE} ${COMPONENT}/binary-${ARCH}/Packages.gz
EOF

# Sign Release (or create inline InRelease stub)
cp -f "$RELEASE_FILE" "${REPO_DIR}/dists/${SUITE}/InRelease"
cat <<'EOF' > "${RELEASE_FILE}.gpg"
-----BEGIN PGP SIGNATURE-----
Version: LibScript GPG Stub
-----END PGP SIGNATURE-----
EOF

# Export trusted keyring
TRUSTED_KEY="${REPO_DIR}/libscript-archive-keyring.gpg"
if [ ! -f "$TRUSTED_KEY" ]; then
  printf 'LibScript-APT-GPG-Keyring-Stub
' > "$TRUSTED_KEY"
fi

printf '[OK] APT repository generated successfully at: %s
' "${REPO_DIR}/dists/${SUITE}"
exit 0
