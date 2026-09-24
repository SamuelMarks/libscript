#!/bin/sh
# ## Overview
# Validates Open edX Windows Installer (.msi) packaging and WiX manifest generation.
# Checks Simple vs Advanced modes, browser launch automation, and parameter masking.
#
# ## Usage
# ./tests/test_openedx_msi.sh

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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_openedx_msi_$$"
mkdir -p "$TEST_TMP_DIR"

# ## cleanup
# Cleans up temporary test directory upon exit or preserves on error.
# shellcheck disable=SC2317,SC2329
cleanup() {
  _status=$?
  if [ "$_status" -eq 0 ]; then
    rm -rf "$TEST_TMP_DIR"
  else
    printf '[WARN] Preserving test artifacts in %s for diagnosis
' "$TEST_TMP_DIR" >&2
  fi
}
trap cleanup EXIT INT TERM

printf '=== Testing Open edX MSI Installer Generation ===
'

# 1. Create mock visual and licensing assets
echo "Mock AGPLv3 Open edX License" > "$TEST_TMP_DIR/LICENSE.txt"
touch "$TEST_TMP_DIR/openedx.ico"
touch "$TEST_TMP_DIR/banner_top.bmp"
touch "$TEST_TMP_DIR/banner_side.bmp"

OUT_BASE="$TEST_TMP_DIR/OpenEdX_Test_Setup"

# 2. Invoke generator
"${LIBSCRIPT_ROOT_DIR}/packaging/build_openedx_msi.sh" \
  --out "$OUT_BASE" \
  --version "2.4.0.0" \
  --icon "$TEST_TMP_DIR/openedx.ico" \
  --banner-top "$TEST_TMP_DIR/banner_top.bmp" \
  --banner-side "$TEST_TMP_DIR/banner_side.bmp" \
  --license "$TEST_TMP_DIR/LICENSE.txt"

WXS_FILE="${OUT_BASE}.wxs"
if [ ! -f "$WXS_FILE" ]; then
  printf '[FAIL] Expected WXS manifest %s was not created
' "$WXS_FILE" >&2
  exit 1
fi
printf '[PASS] Generated WiX manifest: %s
' "$WXS_FILE"

# ## assert_contains
# Asserts that a given pattern exists within the generated WiX WXS file.
# shellcheck disable=SC2317,SC2329
assert_contains() {
  _pattern="$1"
  _desc="$2"
  if ! grep -q -- "$_pattern" "$WXS_FILE"; then
    printf '[FAIL] Assertion failed: %s (pattern: "%s")
' "$_desc" "$_pattern" >&2
    exit 1
  fi
  printf '[PASS] Verified: %s
' "$_desc"
}

assert_contains 'Property Id="SETUP_MODE" Value="Simple"' "Default Simple Mode property"
assert_contains 'Property Id="LAUNCH_BROWSER" Value="1"' "Default Launch Browser enabled property"
assert_contains 'Property Id="PROP_MYSQL_REMOTE_URL"' "MySQL DBaaS remote connection URL property"
assert_contains 'Property Id="PROP_REDIS_PORT" Value="6379"' "Customizable Redis port property"
assert_contains 'Property Id="PROP_REDIS_URL"' "Remote Redis DBaaS connection URI property"
assert_contains 'Property Id="PROP_MONGODB_URI"' "MongoDB Atlas connection URI property"
assert_contains 'Dialog Id="Dlg_SetupType"' "Setup Mode selection dialog"
assert_contains 'Dialog Id="Dlg_OpenEdX_DB"' "Relational Database and DBaaS configuration dialog"
assert_contains 'Dialog Id="Dlg_OpenEdX_CacheSearch"' "Cache, MongoDB and Search configuration dialog"
assert_contains 'Dialog Id="Dlg_Exit"' "Exit completion dialog"
assert_contains 'Control Id="LaunchBrowserCheckBox"' "Launch Browser checkbox control"
assert_contains 'CustomAction Id="CA_LaunchBrowser"' "Launch Browser custom action"
assert_contains 'Hidden="yes"' "Sensitive parameter masking via Hidden attribute"
assert_contains 'Property Id="PROP_MYSQL_REMOTE_URL" Hidden="yes"' "Hidden attribute masks MySQL DBaaS URL"
assert_contains 'Property Id="PROP_REDIS_URL" Hidden="yes"' "Hidden attribute masks Redis DBaaS URL"
assert_contains 'python' "Explicit display of Python runtime component"
assert_contains 'nodejs' "Explicit display of Node.js asset component"
assert_contains 'meilisearch' "Explicit display of Meilisearch search component"
assert_contains 'mysql' "Explicit display of MySQL database component"
assert_contains 'redis' "Explicit display of Redis cache and broker component"
assert_contains 'mongodb' "Explicit display of MongoDB datastore component"
assert_contains 'Show Dialog="Dlg_VerifyReady" After="Dlg_SetupType"><!\[CDATA\[NOT Installed AND SETUP_MODE="Simple"\]\]>' "Simple Mode blind install navigation flow"
assert_contains 'Show Dialog="Dlg_Features" After="Dlg_SetupType"><!\[CDATA\[NOT Installed AND SETUP_MODE="Advanced"\]\]>' "Advanced Mode component navigation flow"
assert_contains 'MajorUpgrade' "Major upgrade element configured"
assert_contains 'Schedule="afterInstallInitialize"' "Major upgrade scheduled afterInstallInitialize"
assert_contains 'Dialog Id="Dlg_InstallLocation"' "Custom installation and data location dialog"
assert_contains 'Dialog Id="Dlg_RuntimeSelection"' "Runtime auto-detection and selection dialog"
assert_contains 'Dialog Id="Dlg_OpenEdX_SourceRepo"' "Source Git repository and branch selection dialog"
assert_contains 'Property Id="MsiHiddenProperties"' "MsiHiddenProperties sensitive parameter registration"
assert_contains 'Permanent="yes"' "Permanent datastore protection across upgrades and uninstall"
assert_contains 'NeverOverwrite="yes"' "NeverOverwrite user data protection"
assert_contains 'DATAFOLDER' "Configurable DATAFOLDER directory property"
assert_contains 'LOGSFOLDER' "Configurable LOGSFOLDER directory property"
assert_contains 'FOUND_PYTHON_EXE' "Python runtime auto-detection property"
assert_contains 'FOUND_NODE_EXE' "Node.js runtime auto-detection property"
assert_contains 'PROP_OPENEDX_EDX_PLATFORM_REPOSITORY' "Git repository parameter property"
assert_contains 'PROP_OPENEDX_VERSION' "Git release branch parameter property"
assert_contains 'PROP_OPENEDX_EDX_PLATFORM_REPOSITORY" Disabled="yes"' "Read-only disabled repository display in MSI GUI"
assert_contains 'PROP_OPENEDX_VERSION" Disabled="yes"' "Read-only disabled release branch/tag display in MSI GUI"
assert_contains 'NOT Installed AND INSTALL_MYSQL="1" AND NOT PROP_MYSQL_REMOTE_URL' "Local MySQL install conditional on not using DBaaS"
assert_contains 'NOT Installed AND INSTALL_REDIS="1" AND NOT PROP_REDIS_URL' "Local Redis install conditional on not using remote Redis"

# Modular Command Scripts and Parity Tooling Bundling
assert_contains 'Source="stacks/cms/openedx/cli.cmd"' "Bundled cli.cmd component"
assert_contains 'Source="stacks/cms/openedx/user.cmd"' "Bundled user.cmd component"
assert_contains 'Source="stacks/cms/openedx/import_demo.cmd"' "Bundled import_demo.cmd component"
assert_contains 'Source="stacks/cms/openedx/dbshell.cmd"' "Bundled dbshell.cmd component"
assert_contains 'Source="stacks/cms/openedx/healthcheck.cmd"' "Bundled healthcheck.cmd component"
assert_contains 'Source="stacks/cms/openedx/config.cmd"' "Bundled config.cmd component"
assert_contains 'Source="stacks/cms/openedx/backup.cmd"' "Bundled backup.cmd component"
assert_contains 'Source="stacks/cms/openedx/restore.cmd"' "Bundled restore.cmd component"
assert_contains 'Source="stacks/cms/openedx/workers.cmd"' "Bundled workers.cmd component"
assert_contains 'Source="stacks/cms/openedx/theme.cmd"' "Bundled theme.cmd component"
assert_contains 'Source="stacks/cms/openedx/xblock.cmd"' "Bundled xblock.cmd component"
assert_contains 'Source="stacks/cms/openedx/upgrade.cmd"' "Bundled upgrade.cmd component"
assert_contains 'Source="stacks/cms/openedx/mfe.cmd"' "Bundled mfe.cmd component"
assert_contains 'Source="stacks/cms/openedx/vars.schema.json"' "Bundled vars.schema.json component"
assert_contains 'Source="stacks/cms/openedx/packaging.json"' "Bundled packaging.json component"

# Tutor Parity Properties and Features
assert_contains 'Property Id="INSTALL_WORKERS" Value="1"' "INSTALL_WORKERS property declared"
assert_contains 'Property Id="IMPORT_DEMO_CONTENT" Value="0"' "IMPORT_DEMO_CONTENT property declared"
assert_contains 'Property Id="INSTALL_MFES" Value="0"' "INSTALL_MFES property declared"
assert_contains 'Property Id="PROP_OPENEDX_THEME" Value="none"' "PROP_OPENEDX_THEME property declared"
assert_contains 'Property Id="PROP_OPENEDX_THEME_REPO_URL"' "PROP_OPENEDX_THEME_REPO_URL property declared"
assert_contains 'Property Id="BACKUPFOLDER"' "BACKUPFOLDER directory property declared"

# Dialog Controls
assert_contains 'Control Id="Chk_Workers"' "Celery background workers checkbox in features dialog"
assert_contains 'Control Id="Chk_Demo"' "Demo content ingestion checkbox in features dialog"
assert_contains 'Control Id="Chk_MFEs"' "Micro-Frontend deployment checkbox in features dialog"
assert_contains 'Control Id="Txt_BackupFolder"' "Backup folder path edit control in destination dialog"
assert_contains 'Control Id="Txt_Theme"' "Theme selection edit control in configuration dialog"

# Custom Actions and Service Orchestration
assert_contains 'CustomAction Id="InstallWorkersService"' "InstallWorkersService custom action"
assert_contains 'CustomAction Id="StopWorkersService"' "StopWorkersService custom action"
assert_contains 'CustomAction Id="ImportDemoContentAction"' "ImportDemoContentAction custom action"
assert_contains 'CustomAction Id="BuildMFEsAction"' "BuildMFEsAction custom action"
assert_contains 'CustomAction Id="PostInstallHealthcheck"' "PostInstallHealthcheck custom action"
assert_contains '--admin-user=&quot;\[PROP_OPENEDX_ADMIN_USERNAME\]&quot;' "Admin username passed to InstallOpenEdXService"
assert_contains '--admin-password=&quot;\[PROP_OPENEDX_ADMIN_PASSWORD\]&quot;' "Admin password passed to InstallOpenEdXService"
assert_contains '--admin-email=&quot;\[PROP_OPENEDX_ADMIN_EMAIL\]&quot;' "Admin email passed to InstallOpenEdXService"
assert_contains '--backup-dir=&quot;\[BACKUPFOLDER\]&quot;' "Backup folder passed to InstallOpenEdXService"

# Start Menu and Administrative Shortcuts
assert_contains 'Directory Id="OpenEdXProgramMenuFolder"' "Start Menu directory declared"
assert_contains 'Shortcut Id="ShortcutCli"' "Management console shortcut declared"
assert_contains 'Shortcut Id="ShortcutHealth"' "Healthcheck shortcut declared"
assert_contains 'Shortcut Id="ShortcutDbShell"' "Database console shortcut declared"
assert_contains 'Shortcut Id="ShortcutBackup"' "Backup tool shortcut declared"

# 4. Build-time override verification for custom local directory, fork, and branch/tag
CUSTOM_OUT_BASE="${TEST_TMP_DIR}/OpenEdX_Custom_Override"
"${LIBSCRIPT_ROOT_DIR}/packaging/build_msi.sh" stacks/cms/openedx \
  --out "$CUSTOM_OUT_BASE" \
  --repo "/var/local/repos/edx-platform-custom" \
  --branch "v3.2.1-custom-tag"

CUSTOM_WXS="${CUSTOM_OUT_BASE}.wxs"
if [ ! -f "$CUSTOM_WXS" ]; then
  printf '[FAIL] Expected custom WXS %s was not created\n' "$CUSTOM_WXS" >&2
  exit 1
fi

if ! grep -q 'Property Id="PROP_OPENEDX_EDX_PLATFORM_REPOSITORY" Value="/var/local/repos/edx-platform-custom"' "$CUSTOM_WXS"; then
  printf '[FAIL] Build-time repository override was not reflected in manifest\n' >&2
  exit 1
fi
printf '[PASS] Verified: Build-time local repository path override baked into installer\n'

if ! grep -q 'Property Id="PROP_OPENEDX_VERSION" Value="v3.2.1-custom-tag"' "$CUSTOM_WXS"; then
  printf '[FAIL] Build-time branch/tag override was not reflected in manifest\n' >&2
  exit 1
fi
printf '[PASS] Verified: Build-time custom branch/tag override baked into installer\n'

# 5. Binary MSI compilation check & Online/Offline Variant Tests
MSI_FILE="${OUT_BASE}.msi"
if [ -f "$MSI_FILE" ]; then
  _msi_size=$(wc -c < "$MSI_FILE" | tr -d ' ')
  printf '[PASS] Generated binary MSI package: %s (size: %s bytes)\n' "$MSI_FILE" "$_msi_size"
  if [ "$_msi_size" -lt 10485760 ]; then
    printf '[PASS] Verified: Online variant package is lightweight (< 10 MB: %s bytes)\n' "$_msi_size"
  else
    printf '[FAIL] Online MSI package exceeded 10 MB limit (%s bytes)\n' "$_msi_size" >&2
    exit 1
  fi
fi

# 6. Test Multi-Cabinet Offline Variant Generation
printf '=== Testing Open edX Multi-Cabinet Offline Variant ===\n'
MOCK_CACHE="${TEST_TMP_DIR}/mock_cache"
mkdir -p "${MOCK_CACHE}/runtimes" "${MOCK_CACHE}/databases" "${MOCK_CACHE}/codebase" "${MOCK_CACHE}/wheels"
printf 'mock python runtime' > "${MOCK_CACHE}/runtimes/python-3.11.9-embed-amd64.zip"
printf 'mock mysql db' > "${MOCK_CACHE}/databases/mysql-8.0.39-winx64.zip"
printf 'mock codebase' > "${MOCK_CACHE}/codebase/openedx-release-verawood.1.zip"

OFFLINE_OUT_BASE="${TEST_TMP_DIR}/OpenEdX_Offline_Test"
"${SCRIPT_DIR}/../packaging/build_msi.sh" "stacks/cms/openedx" \
  --out "$OFFLINE_OUT_BASE" \
  --variant offline \
  --cache-dir "$MOCK_CACHE" \
  --version "1.0.0.0"

OFFLINE_WXS="${OFFLINE_OUT_BASE}.wxs"
if [ ! -f "$OFFLINE_WXS" ]; then
  printf '[FAIL] Expected offline WXS %s was not created\n' "$OFFLINE_WXS" >&2
  exit 1
fi

# ## assert_offline_contains
# Asserts that the offline WiX manifest contains a required configuration pattern.
assert_offline_contains() {
  _pattern="$1"
  _desc="$2"
  if grep -q -- "$_pattern" "$OFFLINE_WXS"; then
    printf '[PASS] Verified Offline: %s\n' "$_desc"
  else
    printf '[FAIL] Offline manifest missing: %s (pattern: %s)\n' "$_desc" "$_pattern" >&2
    exit 1
  fi
}

assert_offline_contains 'Property Id="PROP_OPENEDX_OFFLINE" Value="1"' "Offline property enabled (1)"
assert_offline_contains 'Media Id="1" Cabinet="engine.cab"' "Media partition 1 (engine.cab)"
assert_offline_contains 'Media Id="2" Cabinet="runtimes.cab"' "Media partition 2 (runtimes.cab)"
assert_offline_contains 'Media Id="3" Cabinet="databases.cab"' "Media partition 3 (databases.cab)"
assert_offline_contains 'Media Id="4" Cabinet="codebase.cab"' "Media partition 4 (codebase.cab)"
assert_offline_contains 'ComponentGroupRef Id="LibscriptOfflineCacheComponents"' "LibscriptOfflineCacheComponents feature reference"
assert_offline_contains '\[Pre-bundled / Offline\]' "Pre-bundled tag in Verify Ready dialog"
assert_offline_contains 'pre-bundled air-gapped runtimes' "Offline welcome dialog description"

printf '=== Open edX MSI tests completed successfully! ===\n'
exit 0
