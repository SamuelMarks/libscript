#!/bin/sh
# ## Overview
# Synthesizes zero-daemon OCI container images and Docker v2 loadable archives
# directly from clean sysroots, generating compliant OCI image layouts and metadata.
#
# ## Usage
# ./cli/commands/package_as/container_base.sh [sysroot_dir] [out_archive] [image_tag]

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

SYSROOT="${1:-${LIBSCRIPT_ROOT_DIR}/build/rootfs}"
OUT_FILE="${2:-${LIBSCRIPT_ROOT_DIR}/build/container_image.tar}"
IMAGE_TAG="${3:-libscript-app:latest}"

OUT_DIR="${OUT_FILE%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

if [ -f "$OUT_FILE" ]; then
  printf '[IDEMPOTENT] Target container image archive already exists: %s
' "$OUT_FILE"
  exit 0
fi

printf '[CONTAINER-BASE] Synthesizing OCI layout and Docker archive for %s...
' "$IMAGE_TAG"

TMP_OCI="${LIBSCRIPT_ROOT_DIR}/build/tmp_oci_layout"
rm -rf "$TMP_OCI"
mkdir -p "$TMP_OCI/blobs/sha256"

# 1. OCI Layout Descriptor
cat <<'EOF' > "$TMP_OCI/oci-layout"
{"imageLayoutVersion": "1.0.0"}
EOF

# 2. Package sanitized rootfs layer
TMP_LAYER="${LIBSCRIPT_ROOT_DIR}/build/layer.tar.gz"
if [ -d "$SYSROOT" ]; then
  (
    cd "$SYSROOT"
    tar -czf "$TMP_LAYER" --exclude='./boot*' --exclude='./dev/*' --exclude='./proc/*' --exclude='./sys/*' . 2>/dev/null || tar -czf "$TMP_LAYER" .
  )
else
  mkdir -p "${TMP_OCI}/tmp_minimal_rootfs/bin"
  printf '#!/bin/sh
echo "LibScript Container Running"
' > "${TMP_OCI}/tmp_minimal_rootfs/bin/sh"
  chmod 755 "${TMP_OCI}/tmp_minimal_rootfs/bin/sh"
  (
    cd "${TMP_OCI}/tmp_minimal_rootfs"
    tar -czf "$TMP_LAYER" .
  )
fi

LAYER_SIZE=$(wc -c < "$TMP_LAYER" | tr -d ' ' 2>/dev/null || echo 1024)
LAYER_DIGEST="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
if command -v sha256sum >/dev/null 2>&1; then
  LAYER_DIGEST=$(sha256sum "$TMP_LAYER" | cut -d' ' -f1)
elif command -v shasum >/dev/null 2>&1; then
  LAYER_DIGEST=$(shasum -a 256 "$TMP_LAYER" | cut -d' ' -f1)
fi

cp -f "$TMP_LAYER" "$TMP_OCI/blobs/sha256/$LAYER_DIGEST"

# 3. Generate OCI Image Config JSON
CONFIG_FILE="${TMP_OCI}/blobs/sha256/config.json"
cat <<EOF > "$CONFIG_FILE"
{
  "architecture": "amd64",
  "os": "linux",
  "config": {
    "Env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
      "TERM=xterm"
    ],
    "Cmd": ["/bin/sh"],
    "WorkingDir": "/"
  },
  "rootfs": {
    "type": "layers",
    "diff_ids": [
      "sha256:${LAYER_DIGEST}"
    ]
  }
}
EOF

CONFIG_SIZE=$(wc -c < "$CONFIG_FILE" | tr -d ' ' 2>/dev/null || echo 256)
CONFIG_DIGEST="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
if command -v sha256sum >/dev/null 2>&1; then
  CONFIG_DIGEST=$(sha256sum "$CONFIG_FILE" | cut -d' ' -f1)
elif command -v shasum >/dev/null 2>&1; then
  CONFIG_DIGEST=$(shasum -a 256 "$CONFIG_FILE" | cut -d' ' -f1)
fi
mv -f "$CONFIG_FILE" "$TMP_OCI/blobs/sha256/$CONFIG_DIGEST"

# 4. Generate OCI Manifest JSON
MANIFEST_FILE="${TMP_OCI}/blobs/sha256/manifest.json"
cat <<EOF > "$MANIFEST_FILE"
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "digest": "sha256:${CONFIG_DIGEST}",
    "size": ${CONFIG_SIZE}
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "digest": "sha256:${LAYER_DIGEST}",
      "size": ${LAYER_SIZE}
    }
  ]
}
EOF

MANIFEST_SIZE=$(wc -c < "$MANIFEST_FILE" | tr -d ' ' 2>/dev/null || echo 512)
MANIFEST_DIGEST="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
if command -v sha256sum >/dev/null 2>&1; then
  MANIFEST_DIGEST=$(sha256sum "$MANIFEST_FILE" | cut -d' ' -f1)
elif command -v shasum >/dev/null 2>&1; then
  MANIFEST_DIGEST=$(shasum -a 256 "$MANIFEST_FILE" | cut -d' ' -f1)
fi
mv -f "$MANIFEST_FILE" "$TMP_OCI/blobs/sha256/$MANIFEST_DIGEST"

# 5. Generate OCI Image Index
cat <<EOF > "$TMP_OCI/index.json"
{
  "schemaVersion": 2,
  "manifests": [
    {
      "mediaType": "application/vnd.oci.image.manifest.v1+json",
      "digest": "sha256:${MANIFEST_DIGEST}",
      "size": ${MANIFEST_SIZE},
      "annotations": {
        "org.opencontainers.image.ref.name": "${IMAGE_TAG}"
      },
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    }
  ]
}
EOF

# 6. Format Docker v2 loadable archive (with manifest.json at root)
DOCKER_STAGE="${LIBSCRIPT_ROOT_DIR}/build/tmp_docker_stage"
rm -rf "$DOCKER_STAGE"
mkdir -p "$DOCKER_STAGE"

cp -f "$TMP_LAYER" "$DOCKER_STAGE/layer.tar"
cp -f "$TMP_OCI/blobs/sha256/$CONFIG_DIGEST" "$DOCKER_STAGE/${CONFIG_DIGEST}.json"

cat <<EOF > "$DOCKER_STAGE/manifest.json"
[
  {
    "Config": "${CONFIG_DIGEST}.json",
    "RepoTags": ["${IMAGE_TAG}"],
    "Layers": ["layer.tar"]
  }
]
EOF

cat <<EOF > "$DOCKER_STAGE/repositories"
{
  "${IMAGE_TAG%%:*}": {
    "${IMAGE_TAG##*:}": "${LAYER_DIGEST}"
  }
}
EOF

(
  cd "$DOCKER_STAGE"
  tar -cf "$OUT_FILE" manifest.json repositories "${CONFIG_DIGEST}.json" layer.tar
)

rm -rf "$TMP_OCI" "$DOCKER_STAGE" "$TMP_LAYER"
printf '[OK] Successfully generated container image archive: %s
' "$OUT_FILE"
exit 0
