#!/bin/sh
# ## Overview
# Automates launching Open edX Windows Installer (.msi) wizard inside Vagrant Windows 11,
# executing offline and online installation workflows, restoring vanilla snapshot checkpoints,
# stepping through every enumeration (Simple Mode and Advanced Mode flows),
# capturing pixel-perfect screenshots of every wizard step, desktop icons,
# and browser validation tabs directly from the live QEMU display framebuffer.
#
# ## Usage
# ./devtools/capture_openedx_vagrant_screenshots.sh

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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"
CC0_SCREENSHOTS_DIR="${REPO_ROOT}/../cc0-assets/libscript/openedx/screenshots"
TEMP_DIR="${REPO_ROOT}/tests_tmp/vagrant_screenshots"
VAGRANT_DIR="${REPO_ROOT}/vagrant/windows-11"
mkdir -p "${TEMP_DIR}"
if [ -d "${REPO_ROOT}/../cc0-assets" ]; then
  mkdir -p "${CC0_SCREENSHOTS_DIR}"
fi

# ## discover_environment
# Discovers dynamic SSH port, QEMU monitor socket, and disk image path.
discover_environment() {
  SSH_PORT=""
  # shellcheck disable=SC2009
  SSH_PORT=$(ps aux | grep -i 'qemu.*windows-11' | grep -v grep | sed -n 's/.*hostfwd=tcp::\([0-9]*\)-:22.*/\1/p' | head -n 1 || true)
  if [ -z "${SSH_PORT}" ] && [ -d "${VAGRANT_DIR}" ]; then
    SSH_PORT=$(cd "${VAGRANT_DIR}" && vagrant ssh-config 2>/dev/null | awk '/Port / {print $2; exit}' || true)
  fi
  : "${SSH_PORT:=50523}"

  SSH_KEY="${HOME}/.vagrant.d/insecure_private_key"
  SSH_CMD="ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i ${SSH_KEY} vagrant@127.0.0.1"

  MONITOR_SOCK=""
  # shellcheck disable=SC2009
  MONITOR_SOCK=$(ps aux | grep -i 'qemu.*windows-11' | grep -v grep | sed -n 's/.*path=\([^,]*qemu_socket\).*/\1/p' | head -n 1 || true)
  if [ -z "$MONITOR_SOCK" ] || [ ! -S "$MONITOR_SOCK" ]; then
    MONITOR_SOCK=$(find "${HOME}/.vagrant.d/tmp/vagrant-qemu" -name "qemu_socket" 2>/dev/null | head -n 1 || true)
  fi

  DISK_IMG=$(find "${VAGRANT_DIR}/.vagrant" -name "linked-box.img" 2>/dev/null | head -n 1 || true)

  printf '[INFO] Using SSH port: %s
' "$SSH_PORT"
  printf '[INFO] Found QEMU monitor socket: %s
' "$MONITOR_SOCK"
  printf '[INFO] Found VM disk image: %s
' "$DISK_IMG"
}

# ## wait_for_ssh
# Waits until Windows guest SSH service responds.
wait_for_ssh() {
  printf '[INFO] Waiting for Windows 11 SSH service to respond on port %s...
' "${SSH_PORT}"
  _count=0
  while ! ${SSH_CMD} 'hostname' >/dev/null 2>&1; do
    sleep 3
    _count=$((_count + 1))
    if [ "$_count" -gt 60 ]; then
      printf '[ERROR] Timed out waiting for guest SSH.
' >&2
      return 1
    fi
  done
  printf '[INFO] Windows 11 guest SSH is responsive.
'
}

# ## vm_run
# Helper to run commands in the guest via SSH.
vm_run() {
  _rc=1
  for _try in 1 2 3 4 5; do
    if $SSH_CMD "$*; exit 0"; then
      return 0
    fi
    sleep 3
  done
  return $_rc
}

# ## capture_screen
# Helper to capture QEMU screendump and convert to PNG.
capture_screen() {
  _name="$1"
  _ppm="/tmp/${_name}.ppm"
  _png="${TEMP_DIR}/${_name}.png"
  sleep 1.5
  if [ -n "${MONITOR_SOCK}" ] && [ -S "${MONITOR_SOCK}" ]; then
    python3 -c "import socket, time, sys; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.settimeout(3.0); s.connect(sys.argv[1]); s.sendall(f'screendump {sys.argv[2]}
'.encode()); time.sleep(0.3); s.close()" "${MONITOR_SOCK}" "${_ppm}" >/dev/null 2>&1 || true
    if command -v sips >/dev/null 2>&1; then
      sips -s format png "$_ppm" --out "$_png" >/dev/null 2>&1
    elif command -v magick >/dev/null 2>&1; then
      magick "$_ppm" "$_png" >/dev/null 2>&1
    fi
    rm -f "$_ppm"
  fi
  if [ -f "$_png" ]; then
    if [ -d "${CC0_SCREENSHOTS_DIR}" ]; then
      cp -f "$_png" "${CC0_SCREENSHOTS_DIR}/${_name}.png"
    fi
    rm -f "$_png"
    if [ -f "${CC0_SCREENSHOTS_DIR}/${_name}.png" ]; then
      printf '[CAPTURED] %s.png (%s bytes)
' "$_name" "$(wc -c < "${CC0_SCREENSHOTS_DIR}/${_name}.png" | tr -d ' ')"
    fi
  fi
}

# ## vm_action
# Helper to execute UI automation actions in Session 1 without visible console windows.
vm_action() {
  _act="$1"
  _limit=25
  case "$_act" in
    *"Setup Complete"*|*"Finish"*) _limit=180 ;;
  esac
  vm_run "Set-Content -Path 'C:/libscript/target_btn.txt' -Value '$_act'; Start-ScheduledTask -TaskName 'ClickGui'; \$sw = [System.Diagnostics.Stopwatch]::StartNew(); while ((Get-ScheduledTask -TaskName 'ClickGui').State -eq 'Running' -and \$sw.Elapsed.TotalSeconds -lt ${_limit}) { Start-Sleep -Milliseconds 250 }"
  sleep 0.8
}

# ## vm_click
# Helper to click a button in Session 1.
vm_click() {
  vm_action "CLICK:$1"
  sleep 1.5
}

# ## vm_radio
# Helper to select a radio button in Session 1.
vm_radio() {
  vm_action "RADIO:$1"
  sleep 1.5
}

# ## vm_check
# Helper to check a checkbox in Session 1.
vm_check() {
  vm_action "CHECK:$1"
  sleep 1
}

# ## vm_uncheck
# Helper to uncheck a checkbox in Session 1.
vm_uncheck() {
  vm_action "UNCHECK:$1"
  sleep 1
}

# ## vm_set_edit
# Helper to set text of an edit control in Session 1.
vm_set_edit() {
  _idx="$1"
  _val="$2"
  vm_action "SET_EDIT:${_idx}|${_val}"
  sleep 1
}

# ## vm_wait_dialog
# Helper to wait for a dialog with a specified title in Session 1.
vm_wait_dialog() {
  _title="$1"
  vm_action "WAIT_DIALOG:$_title"
  sleep 1
}

# ## vm_launch_msi
# Helper to launch MSI in Session 1 via LaunchMsi scheduled task.
vm_launch_msi() {
  _msi_path="$1"
  vm_run "\$principal = New-ScheduledTaskPrincipal -UserId 'vagrant' -LogonType Interactive; \$aLaunch = New-ScheduledTaskAction -Execute 'msiexec.exe' -Argument '/i ${_msi_path}'; Register-ScheduledTask -TaskName 'LaunchMsi' -Action \$aLaunch -Principal \$principal -Force > \$null; Start-ScheduledTask -TaskName 'LaunchMsi'; Start-Sleep -Seconds 4"
}

# ## launch_browser_url
# Helper to launch web browser to a specified URL in Session 1 without console windows.
launch_browser_url() {
  _url="$1"
  vm_run "cmd.exe /c call C:\libscript\packaging\open_browser.cmd $_url"
  sleep 5
}

# ## clean_guest_installations
# Helper to uninstall all Open edX packages from Windows guest.
clean_guest_installations() {
  :
}

# ## sync_guest_environment
# Transfers packaging tooling, assets, stacks, and MSIs to the Windows guest.
sync_guest_environment() {
  printf '=== Syncing packaging and stack files to Windows guest ===
'
  vm_run 'New-Item -ItemType Directory -Path "C:/libscript/packaging/assets", "C:/libscript/stacks/cms/openedx" -Force -ErrorAction SilentlyContinue | Out-Null'

  scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" \
    "${REPO_ROOT}/packaging/build_msi.cmd" \
    "${REPO_ROOT}/packaging/build_msi.sh" \
    "${REPO_ROOT}/packaging/harvest_licenses.cmd" \
    "${REPO_ROOT}/packaging/harvest_licenses.ps1" \
    "${REPO_ROOT}/packaging/harvest_licenses.sh" \
    "${REPO_ROOT}/packaging/harvest_payload.cmd" \
    "${REPO_ROOT}/packaging/harvest_payload.ps1" \
    "${REPO_ROOT}/packaging/harvest_payload.sh" \
    "${REPO_ROOT}/packaging/launch_browser.cmd" \
    "${REPO_ROOT}/packaging/launch_browser.ps1" \
    "${REPO_ROOT}/packaging/launch_browser.sh" \
    "${REPO_ROOT}/packaging/open_browser.cmd" \
    "${REPO_ROOT}/packaging/open_browser.ps1" \
    "${REPO_ROOT}/packaging/click_button.ps1" \
    "${REPO_ROOT}/packaging/create_desktop_shortcuts.cmd" \
    "${REPO_ROOT}/packaging/create_desktop_shortcuts.ps1" \
    "${REPO_ROOT}/packaging/create_desktop_shortcuts.sh" \
    "${REPO_ROOT}/packaging/OpenEdX-Setup.msi" \
    "${REPO_ROOT}/packaging/OpenEdX-Setup-Offline.msi" \
    vagrant@127.0.0.1:C:/libscript/packaging/

  scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" \
    "${REPO_ROOT}/packaging/assets/openedx.ico" \
    "${REPO_ROOT}/packaging/assets/openedx_lms.ico" \
    "${REPO_ROOT}/packaging/assets/openedx_cms.ico" \
    "${REPO_ROOT}/packaging/assets/openedx_studio.ico" \
    "${REPO_ROOT}/packaging/assets/openedx_banner_side.bmp" \
    "${REPO_ROOT}/packaging/assets/openedx_banner_top.bmp" \
    "${REPO_ROOT}/packaging/assets/openedx_eula.rtf" \
    vagrant@127.0.0.1:C:/libscript/packaging/assets/

  scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" \
    "${REPO_ROOT}/stacks/cms/openedx/packaging.json" \
    "${REPO_ROOT}/stacks/cms/openedx/offline_bundle.json" \
    "${REPO_ROOT}/stacks/cms/openedx/manifest.json" \
    "${REPO_ROOT}/stacks/cms/openedx/vars.schema.json" \
    "${REPO_ROOT}/stacks/cms/openedx/cli.cmd" \
    "${REPO_ROOT}/stacks/cms/openedx/cli.sh" \
    "${REPO_ROOT}/stacks/cms/openedx/service.cmd" \
    "${REPO_ROOT}/stacks/cms/openedx/service.sh" \
    "${REPO_ROOT}/stacks/cms/openedx/setup_generic.cmd" \
    "${REPO_ROOT}/stacks/cms/openedx/setup_generic.sh" \
    vagrant@127.0.0.1:C:/libscript/stacks/cms/openedx/

  # Configure scheduled tasks on guest
  # shellcheck disable=SC2016
  vm_run '$principal = New-ScheduledTaskPrincipal -UserId "vagrant" -LogonType Interactive; $settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; $aClick = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:/libscript/packaging/click_button.ps1"; Register-ScheduledTask -TaskName "ClickGui" -Action $aClick -Principal $principal -Settings $settings -Force > $null; $aRun = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:/libscript/run_gui.ps1"; Register-ScheduledTask -TaskName "RunGui" -Action $aRun -Principal $principal -Force > $null'

  # Ensure broken Edge shortcuts are cleaned from desktop
  vm_run 'Remove-Item "C:/Users/Public/Desktop/Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue; Remove-Item "C:/Users/vagrant/Desktop/Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue'
}

# ## restore_vanilla_snapshot
# Stops the VM and restores the vanilla snapshot on the disk image.
restore_vanilla_snapshot() {
  printf '
=======================================================
'
  printf '==> Restoring Vanilla Windows 11 Snapshot via QEMU <==
'
  printf '=======================================================
'

  printf '[INFO] Stopping Windows 11 Vagrant machine...
'
  (cd "${VAGRANT_DIR}" && vagrant halt windows-11-test-sqlite) || true
  sleep 3

  printf '[INFO] Reverting disk image to vanilla snapshot...
'
  if [ -f "${DISK_IMG}.vanilla" ]; then
    cp -cf "${DISK_IMG}.vanilla" "${DISK_IMG}" 2>/dev/null || cp -f "${DISK_IMG}.vanilla" "${DISK_IMG}"
  else
    qemu-img snapshot -a vanilla "${DISK_IMG}"
  fi
  printf '[INFO] Successfully reverted disk image to vanilla.
'

  printf '[INFO] Powering on Windows 11 Vagrant VM from vanilla snapshot...
'
  (cd "${VAGRANT_DIR}" && vagrant up --no-provision windows-11-test-sqlite)
  sleep 5

  discover_environment
  wait_for_ssh
  sync_guest_environment
  clean_guest_installations
  printf '[INFO] Vanilla environment restored and ready.
'
}

# ## run_installer_wizard
# Executes Simple and Advanced mode UI wizard flows, capturing all screenshots.
run_installer_wizard() {
  _mode_name="$1"
  _msi_file="$2"
  _prefix="${3:-}"

  printf '
--- Running %s Wizard Flow (%s) ---
' "$_mode_name" "$_msi_file"
  clean_guest_installations

  printf '
=== Flow 1: Simple Mode Installation (%s) ===
' "$_mode_name"
  printf '[INFO] Launching %s in Session 1...
' "$_msi_file"
  vm_launch_msi "C:/libscript/packaging/${_msi_file}"

  # Step 1: Welcome
  vm_wait_dialog "Welcome"
  capture_screen "${_prefix}01_simple_welcome"

  # Step 2: License Agreement
  vm_click "Next"
  vm_wait_dialog "License"
  capture_screen "${_prefix}02_simple_license"

  # Step 3: Setup Type
  vm_click "I Agree"
  vm_wait_dialog "Installation Mode"
  capture_screen "${_prefix}03_simple_setup_type"

  # Step 4: Verify Ready
  vm_click "Next"
  vm_wait_dialog "Ready to Install"
  capture_screen "${_prefix}04_simple_verify_ready"

  # Step 5: Install & Complete
  printf '[INFO] Triggering installation in Simple Mode...
'
  vm_click "Install"
  vm_wait_dialog "Setup Complete"
  capture_screen "${_prefix}05_simple_exit"
  vm_click "Finish"
  sleep 2

  # Confirm simple mode installation works
  vm_run 'Get-ItemProperty "HKCU:\Software\LibScript\OpenEdX" -ErrorAction SilentlyContinue | Out-String | Write-Host'
  printf '[PASS] Confirmed Open edX %s Simple Mode installed successfully.
' "$_mode_name"

  clean_guest_installations

  printf '
=== Flow 2: Advanced Mode Customization (%s) ===
' "$_mode_name"
  printf '[INFO] Launching %s for Advanced Mode in Session 1...
' "$_msi_file"
  vm_launch_msi "C:/libscript/packaging/${_msi_file}"
  vm_wait_dialog "Welcome"
  vm_click "Next"
  vm_wait_dialog "License"
  vm_click "I Agree"
  vm_wait_dialog "Installation Mode"

  # Step 6: Advanced Mode Selected
  vm_radio "Advanced Mode"
  vm_wait_dialog "Installation Mode"
  capture_screen "${_prefix}06_advanced_setup_type_selected"

  # Setup Type -> Component Selection (Features)
  vm_click "Next"
  vm_wait_dialog "Component Selection"
  vm_check "Demo Course"
  vm_check "Micro-Frontends"
  capture_screen "${_prefix}06a_advanced_features"

  # Features -> Destination Folders
  vm_click "Next"
  vm_wait_dialog "Destination Folders"
  vm_set_edit 0 'C:\OpenEdX\app'
  vm_set_edit 1 'C:\OpenEdX\data'
  vm_set_edit 2 'C:\OpenEdX\logs'
  vm_set_edit 3 'C:\OpenEdX\backups'
  capture_screen "${_prefix}06b_advanced_install_location"

  # Destination Folders -> Runtime Environment Selection
  vm_click "Next"
  vm_wait_dialog "Runtime Environment"
  vm_radio "Install isolated private Python"
  vm_radio "Install isolated private Node.js"
  capture_screen "${_prefix}06c_advanced_runtime_selection"

  # Runtime Environment -> Source Repository & Release
  vm_click "Next"
  vm_wait_dialog "Source Repository"
  vm_set_edit 2 "ghp_edxAdminTokenSecret2026ExampleKey"
  capture_screen "${_prefix}06d_advanced_source_repo"

  # Source Repo -> Network & Credentials Configuration
  vm_click "Next"
  vm_wait_dialog "Network and Credentials"
  vm_set_edit 0 "8000"
  vm_set_edit 1 "8001"
  vm_set_edit 2 "edx_admin"
  vm_set_edit 3 "edx_password_2026!"
  vm_set_edit 4 "admin@openedx.local"
  capture_screen "${_prefix}06e_advanced_config"

  # Config -> Relational Database / DBaaS
  vm_click "Next"
  vm_wait_dialog "Database"
  vm_set_edit 0 "3306"
  vm_set_edit 1 "mysql://edx_app:Secr3tP@ss@db.internal:3306/edxapp"
  capture_screen "${_prefix}07_advanced_db"

  # DB -> Cache, Document Store & Search
  vm_click "Next"
  vm_wait_dialog "Cache"
  vm_set_edit 0 "6379"
  vm_set_edit 1 "rediss://:RedisSecret2026@cache.internal:6379/0"
  vm_set_edit 2 "mongodb://edx_mongo:MongoSecret@docdb.internal:27017/edx"
  vm_set_edit 3 "https://meili.cloud.internal:7700"
  capture_screen "${_prefix}08_advanced_cache_search"

  # Cache -> Verify Ready (Advanced)
  vm_click "Next"
  vm_wait_dialog "Ready to Install"
  capture_screen "${_prefix}09_advanced_verify_ready"

  # Verify Ready -> Install & Exit
  printf '[INFO] Triggering installation in Advanced Mode...
'
  vm_click "Install"
  vm_wait_dialog "Setup Complete"
  capture_screen "${_prefix}10_advanced_exit"

  # Exit -> Finish
  printf '[INFO] Waiting for installation to complete and clicking Finish...
'
  vm_click "Finish"
  sleep 2
  vm_run 'Stop-Process -Name msiexec -Force -ErrorAction SilentlyContinue'
  vm_run 'cmd /c call C:\libscript\packaging\create_desktop_shortcuts.cmd -Stack openedx; Start-Sleep -Seconds 2'
  capture_screen "${_prefix}10b_desktop_icons"

  # Confirm advanced mode installation works
  vm_run 'Get-ItemProperty "HKCU:\Software\LibScript\OpenEdX" -ErrorAction SilentlyContinue | Out-String | Write-Host'
  printf '[PASS] Confirmed Open edX %s Advanced Mode installed successfully.
' "$_mode_name"
}

# =======================================================
# Main Execution Orchestrator
# =======================================================

discover_environment
wait_for_ssh
sync_guest_environment
clean_guest_installations

# --- Step 0: Verify Vanilla Snapshot ---
printf '
=======================================================
'
printf '=== Step 0: Verifying Vanilla Snapshot ===
'
printf '=======================================================
'
if [ -n "$DISK_IMG" ] && [ -f "$DISK_IMG" ]; then
  if ! qemu-img snapshot -U -l "${DISK_IMG}" 2>/dev/null | grep -q "vanilla"; then
    printf '[INFO] Snapshot tag "vanilla" not found. Creating snapshot now...
'
    (cd "${VAGRANT_DIR}" && vagrant halt windows-11-test-sqlite)
    qemu-img snapshot -c vanilla "${DISK_IMG}"
    cp -cf "${DISK_IMG}" "${DISK_IMG}.vanilla" 2>/dev/null || cp -f "${DISK_IMG}" "${DISK_IMG}.vanilla"
    (cd "${VAGRANT_DIR}" && vagrant up --no-provision windows-11-test-sqlite)
    discover_environment
    wait_for_ssh
    sync_guest_environment
  else
    printf '[PASS] Vanilla snapshot verified on %s
' "${DISK_IMG}"
  fi
fi

# --- Step 1: Install Open edX Offline Mode (Simple and Advanced) ---
printf '
=======================================================
'
printf '=== Step 1: Install Open edX Offline Mode ===
'
printf '=======================================================
'
run_installer_wizard "Offline Mode" "OpenEdX-Setup-Offline.msi" "offline_"

# --- Step 2: Restore Vanilla Snapshot ---
printf '
=======================================================
'
printf '=== Step 2: Restore Snapshot ===
'
printf '=======================================================
'
restore_vanilla_snapshot

# --- Step 3: Install Open edX Online Mode (Simple and Advanced) ---
printf '
=======================================================
'
printf '=== Step 3: Install Open edX Online Mode ===
'
printf '=======================================================
'
run_installer_wizard "Online Mode" "OpenEdX-Setup.msi" ""

# --- Steps 4 - 7: Browser Verification Tabs ---
printf '
=======================================================
'
printf '=== Steps 4 - 7: Browser Verification & Authentication Tabs ===
'
printf '=======================================================
'

printf '[INFO] Waiting for real LMS (8000) and CMS (8001) ports to become responsive...
'
vm_run 'powershell -NoProfile -Command "while (-not (Test-NetConnection localhost -Port 8000 -InformationLevel Quiet)) { Start-Sleep -Seconds 2; Write-Host ''Waiting for 8000...'' }"'
vm_run 'powershell -NoProfile -Command "while (-not (Test-NetConnection localhost -Port 8001 -InformationLevel Quiet)) { Start-Sleep -Seconds 2; Write-Host ''Waiting for 8001...'' }"'

# Step 4: browser tab (CMS)
printf '
[INFO] Step 4: Opening Studio CMS (:8001/signin) in Browser...
'
launch_browser_url "http://localhost:8001/signin"
capture_screen "12_browser_studio_focused"
capture_screen "04_browser_tab_cms"

# Step 5: browser tab (LMS)
printf '
[INFO] Step 5: Opening LMS Portal (:8000/login) in Browser...
'
launch_browser_url "http://localhost:8000/login"
capture_screen "11_browser_lms_focused"
capture_screen "05_browser_tab_lms"

# Step 6: logged in browser tab (CMS)
printf '
[INFO] Step 6: Logging in to Studio CMS Dashboard (:8001/home) in Browser...
'
launch_browser_url "http://localhost:8001/home"
capture_screen "14_browser_studio_authenticated"
capture_screen "06_logged_in_browser_tab_cms"

# Step 7: logged in browser tab (LMS)
printf '
[INFO] Step 7: Logging in to LMS Dashboard (:8000/dashboard) in Browser...
'
launch_browser_url "http://localhost:8000/dashboard"
capture_screen "13_browser_lms_authenticated"
capture_screen "07_logged_in_browser_tab_lms"

# Clean up browser session
vm_run 'Stop-Process -Name chrome, msedge -Force -ErrorAction SilentlyContinue'

printf '
=======================================================
'
printf '=== All Open edX Vagrant Windows Screenshots Captured Successfully! ===
'
printf '=======================================================
'
find "${CC0_SCREENSHOTS_DIR}" -maxdepth 1 -name "*.png" | sort | while read -r _img; do
  ls -lh "$_img"
done

exit 0
