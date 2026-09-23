#!/bin/sh
# ## Overview
# Generates YUM/DNF repository metadata (repomd.xml, primary.xml.gz, filelists.xml.gz)
# from RPM package repositories using createrepo_c or automated XML indexing.
#
# ## Usage
# ./_lib/orchestration/repogen/rpm_index.sh <repo_dir>

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

REPO_DIR="${1:-${LIBSCRIPT_ROOT_DIR}/build/packages/rpm}"
PACKAGES_DIR="${REPO_DIR}/Packages"
REPODATA_DIR="${REPO_DIR}/repodata"

mkdir -p "$PACKAGES_DIR" "$REPODATA_DIR"

set +f
# Move loose .rpm files into Packages dir
for f in "$REPO_DIR"/*.rpm; do
  if [ -f "$f" ]; then
    mv -f "$f" "$PACKAGES_DIR/" 2>/dev/null || true
  fi
done

printf '[REPOGEN-RPM] Indexing RPM packages in %s...\n' "$PACKAGES_DIR"

if command -v createrepo_c >/dev/null 2>&1; then
  createrepo_c "$REPO_DIR" >/dev/null 2>&1
elif command -v createrepo >/dev/null 2>&1; then
  createrepo "$REPO_DIR" >/dev/null 2>&1
else
  PRIMARY_XML="${REPODATA_DIR}/primary.xml"
  FILELISTS_XML="${REPODATA_DIR}/filelists.xml"
  REPOMD_XML="${REPODATA_DIR}/repomd.xml"

  cat <<EOF > "$PRIMARY_XML"
<?xml version="1.0" encoding="UTF-8"?>
<metadata xmlns="http://linux.duke.edu/metadata/common" xmlns:rpm="http://linux.duke.edu/metadata/rpm" packages="1">
EOF

  cat <<EOF > "$FILELISTS_XML"
<?xml version="1.0" encoding="UTF-8"?>
<filelists xmlns="http://linux.duke.edu/metadata/filelists" packages="1">
EOF

  for pkg in "$PACKAGES_DIR"/*.rpm; do
    [ -f "$pkg" ] || continue
    bname="${pkg##*/}"
    pname="${bname%%-[0-9]*}"
    pver_rest="${bname#${pname}-}"
    pver="${pver_rest%%-*}"
    fsize=$(wc -c < "$pkg" | tr -d ' ' 2>/dev/null || echo 4096)

    cat <<EOF >> "$PRIMARY_XML"
  <package type="rpm">
    <name>${pname}</name>
    <arch>x86_64</arch>
    <version epoch="0" ver="${pver}" rel="1"/>
    <summary>${pname} binary package</summary>
    <description>${pname} synthesized by LibScript</description>
    <size package="${fsize}" installed="${fsize}" archive="${fsize}"/>
    <location href="Packages/${bname}"/>
  </package>
EOF

    cat <<EOF >> "$FILELISTS_XML"
  <package pkgid="dummy" name="${pname}" arch="x86_64">
    <version epoch="0" ver="${pver}" rel="1"/>
    <file>/usr/bin/${pname}</file>
  </package>
EOF
  done
  set -f

  printf '</metadata>
' >> "$PRIMARY_XML"
  printf '</filelists>
' >> "$FILELISTS_XML"

  gzip -9 -c "$PRIMARY_XML" > "${REPODATA_DIR}/primary.xml.gz"
  gzip -9 -c "$FILELISTS_XML" > "${REPODATA_DIR}/filelists.xml.gz"

  PRIMARY_SHA256="dummy"
  if command -v sha256sum >/dev/null 2>&1; then
    PRIMARY_SHA256=$(sha256sum "${REPODATA_DIR}/primary.xml.gz" | cut -d' ' -f1)
  elif command -v shasum >/dev/null 2>&1; then
    PRIMARY_SHA256=$(shasum -a 256 "${REPODATA_DIR}/primary.xml.gz" | cut -d' ' -f1)
  fi

  cat <<EOF > "$REPOMD_XML"
<?xml version="1.0" encoding="UTF-8"?>
<repomd xmlns="http://linux.duke.edu/metadata/repo">
  <data type="primary">
    <checksum type="sha256">${PRIMARY_SHA256}</checksum>
    <location href="repodata/primary.xml.gz"/>
  </data>
</repomd>
EOF
fi

# GPG detached signature stub
REPOMD_ASC="${REPODATA_DIR}/repomd.xml.asc"
cat <<'EOF' > "$REPOMD_ASC"
-----BEGIN PGP SIGNATURE-----
Version: LibScript RPM Repodata Signature Stub
-----END PGP SIGNATURE-----
EOF

printf '[OK] RPM repository metadata synthesized successfully at: %s
' "$REPODATA_DIR"
exit 0
