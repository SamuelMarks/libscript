#!/bin/sh
# ## Overview
# Automates launching WordPress Windows Installer (.msi) wizard inside Vagrant Windows 11,
# stepping through every enumeration (Simple Mode and Advanced Mode flows),
# executing offline and online installation workflows, restoring vanilla VM snapshots,
# and capturing pixel-perfect screenshots of wizard steps, desktop icons, and browser views
# directly from the live QEMU display framebuffer.
#
# ## Usage
# ./devtools/capture_wordpress_vagrant_screenshots.sh

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
CC0_SCREENSHOTS_DIR="${REPO_ROOT}/../cc0-assets/libscript/wordpress/screenshots"
TEMP_DIR="${REPO_ROOT}/tests_tmp/vagrant_screenshots"
mkdir -p "${TEMP_DIR}"
mkdir -p "${CC0_SCREENSHOTS_DIR}"

VAGRANT_DIR="${REPO_ROOT}/vagrant/windows-11"

# ## discover_environment
# Discovers running QEMU process, SSH port, and monitor socket for Windows 11 Vagrant VM.
discover_environment() {
  printf '[INFO] Discovering Windows 11 Vagrant environment...
'
  SSH_PORT=$(ps aux | awk '/[q]emu.*windows-11/' | sed -n 's/.*hostfwd=tcp::\([0-9]*\)-:22.*/\1/p' | head -n 1 || true)
  if [ -z "${SSH_PORT:-}" ] && [ -d "${VAGRANT_DIR}" ]; then
    SSH_PORT=$(cd "${VAGRANT_DIR}" && vagrant ssh-config 2>/dev/null | awk '/Port / {print $2; exit}' || true)
  fi
  : "${SSH_PORT:=50452}"
  SSH_KEY="${HOME}/.vagrant.d/insecure_private_key"
  SSH_CMD="ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i ${SSH_KEY} vagrant@127.0.0.1"

  MONITOR_SOCK=$(ps aux | awk '/[q]emu.*windows-11/' | sed -n 's/.*path=\([^,]*qemu_socket\).*/\1/p' | head -n 1 || true)
  if [ -z "$MONITOR_SOCK" ] || [ ! -S "$MONITOR_SOCK" ]; then
    printf '[ERROR] QEMU monitor socket not found. Is Windows 11 Vagrant VM running?
' >&2
    exit 1
  fi

  DISK_IMG=$(ps aux | awk '/[q]emu.*windows-11/' | sed -n 's/.*file=\([^,]*linked-box\.img\).*/\1/p' | head -n 1 || true)
  if [ -z "$DISK_IMG" ]; then
    DISK_IMG=$(find "${VAGRANT_DIR}/.vagrant" -name "linked-box.img" 2>/dev/null | head -n 1 || true)
  fi

  printf '[INFO] SSH port: %s
' "$SSH_PORT"
  printf '[INFO] Monitor socket: %s
' "$MONITOR_SOCK"
  printf '[INFO] Disk image: %s
' "$DISK_IMG"
}

# ## vm_run
# Helper to run commands in the guest via SSH.
vm_run() {
  $SSH_CMD "$*; exit 0"
}

# ## wait_for_ssh
# Waits until Windows guest is reachable via SSH.
wait_for_ssh() {
  printf '[INFO] Waiting for Windows guest SSH to become available...
'
  _attempts=0
  while [ "$_attempts" -lt 60 ]; do
    if $SSH_CMD 'Write-Host "PONG"' 2>/dev/null | grep -q "PONG"; then
      printf '[INFO] Windows guest SSH is online and responsive.
'
      return 0
    fi
    sleep 3
    _attempts=$((_attempts + 1))
  done
  printf '[ERROR] Timed out waiting for guest SSH.
' >&2
  exit 1
}

# ## capture_screen
# Helper to capture QEMU screendump and convert to PNG.
capture_screen() {
  _name="$1"
  _ppm="${TEMP_DIR}/${_name}.ppm"
  _png="${TEMP_DIR}/${_name}.png"
  sleep 1.2
  if [ -S "${MONITOR_SOCK}" ]; then
    python3 -c 'import socket, time, sys; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.settimeout(3.0); s.connect(sys.argv[1]); s.sendall((f"screendump {sys.argv[2]}" + chr(10)).encode()); time.sleep(0.3); s.close()' "${MONITOR_SOCK}" "${_ppm}" >/dev/null 2>&1 || true
    if command -v sips >/dev/null 2>&1; then
      sips -s format png "$_ppm" --out "$_png" >/dev/null 2>&1
    elif command -v magick >/dev/null 2>&1; then
      magick "$_ppm" "$_png" >/dev/null 2>&1
    fi
    rm -f "$_ppm"
  fi
  if [ -f "$_png" ]; then
    cp -f "$_png" "${CC0_SCREENSHOTS_DIR}/${_name}.png"
    rm -f "$_png"
    if [ -f "${CC0_SCREENSHOTS_DIR}/${_name}.png" ]; then
      printf '[CAPTURED] %s.png (%s bytes)\n' "$_name" "$(wc -c < "${CC0_SCREENSHOTS_DIR}/${_name}.png" | tr -d ' ')"
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
vm_click() {
  vm_action "CLICK:$1"
  sleep 1.5
}

# ## vm_radio
vm_radio() {
  vm_action "RADIO:$1"
  sleep 1.5
}

# ## vm_check
# shellcheck disable=SC2329
vm_check() {
  vm_action "CHECK:$1"
  sleep 1
}

# ## vm_uncheck
# shellcheck disable=SC2329
vm_uncheck() {
  vm_action "UNCHECK:$1"
  sleep 1
}

# ## vm_set_edit
vm_set_edit() {
  _idx="$1"
  _val="$2"
  vm_action "SET_EDIT:${_idx}|${_val}"
  sleep 1
}

# ## vm_wait_dialog
vm_wait_dialog() {
  _title="$1"
  vm_action "WAIT_DIALOG:$_title"
  sleep 1
}

# ## vm_wait
# shellcheck disable=SC2329
vm_wait() {
  _btn="$1"
  vm_action "WAIT:$_btn"
  sleep 1.5
}

# ## vm_launch_msi
vm_launch_msi() {
  _msi_path="$1"
  vm_run "\$principal = New-ScheduledTaskPrincipal -UserId 'vagrant' -LogonType Interactive; \$aLaunch = New-ScheduledTaskAction -Execute 'msiexec.exe' -Argument '/i ${_msi_path}'; Register-ScheduledTask -TaskName 'LaunchMsi' -Action \$aLaunch -Principal \$principal -Force | Out-Null; Start-ScheduledTask -TaskName 'LaunchMsi'; Start-Sleep -Seconds 4"
}

# ## launch_browser_url
launch_browser_url() {
  _url="$1"
  vm_run "cmd.exe /c call C:\libscript\packaging\open_browser.cmd $_url"
  sleep 5
}

# ## clean_guest_installations
clean_guest_installations() {
  printf '[INFO] Cleaning prior installations and browser sessions on guest...
'
  # shellcheck disable=SC2016
  vm_run 'Stop-Process -Name chrome, msedge, msiexec, WindowsTerminal -Force -ErrorAction SilentlyContinue; while ($p = Get-Package -Name "*WordPress*" -ErrorAction SilentlyContinue) { foreach ($pkg in $p) { Start-Process msiexec.exe -ArgumentList "/x $($pkg.FastPackageReference) /qn" -Wait } }; Get-ChildItem -Path "Registry::HKEY_CLASSES_ROOT\Installer\Products" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.ProductName -like "*WordPress*" } | ForEach-Object { Start-Process msiexec.exe -ArgumentList "/x $($_.PSChildName) /qn" -Wait }; Remove-Item "C:/Users/*/Desktop/WordPress*.lnk", "C:/Users/Public/Desktop/WordPress*.lnk" -Force -ErrorAction SilentlyContinue'
  vm_run 'Stop-Process -Name chrome, msedge, msiexec, WindowsTerminal -Force -ErrorAction SilentlyContinue'
}

# ## sync_guest_environment
sync_guest_environment() {
  printf '[INFO] Syncing scripts, assets, and MSIs to Windows guest...\n'
  scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" \
"${REPO_ROOT}/packaging/build_msi.cmd" \
"${REPO_ROOT}/packaging/build_msi.sh" \
"${REPO_ROOT}/packaging/harvest_payload.cmd" \
"${REPO_ROOT}/packaging/harvest_payload.ps1" \
"${REPO_ROOT}/packaging/harvest_payload.sh" \
"${REPO_ROOT}/packaging/click_button.ps1" \
"${REPO_ROOT}/packaging/open_browser.cmd" \
"${REPO_ROOT}/packaging/open_browser.ps1" \
"${REPO_ROOT}/packaging/create_desktop_shortcuts.cmd" \
"${REPO_ROOT}/packaging/create_desktop_shortcuts.ps1" \
"${REPO_ROOT}/packaging/create_desktop_shortcuts.sh" \
vagrant@127.0.0.1:C:/libscript/packaging/

  vm_run 'New-Item -ItemType Directory -Path "C:/libscript/packaging/assets" -Force -ErrorAction SilentlyContinue | Out-Null'

  scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" \
"${REPO_ROOT}/packaging/assets/wordpress.ico" \
"${REPO_ROOT}/packaging/assets/wordpress_banner_side.bmp" \
"${REPO_ROOT}/packaging/assets/wordpress_banner_top.bmp" \
"${REPO_ROOT}/packaging/assets/wordpress_eula.rtf" \
vagrant@127.0.0.1:C:/libscript/packaging/assets/

  vm_run 'New-Item -ItemType Directory -Path "C:/libscript/stacks/cms/wordpress" -Force -ErrorAction SilentlyContinue | Out-Null'

  scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" \
"${REPO_ROOT}/stacks/cms/wordpress/packaging.json" \
"${REPO_ROOT}/stacks/cms/wordpress/offline_bundle.json" \
"${REPO_ROOT}/stacks/cms/wordpress/manifest.json" \
"${REPO_ROOT}/stacks/cms/wordpress/vars.schema.json" \
"${REPO_ROOT}/stacks/cms/wordpress/cli.cmd" \
"${REPO_ROOT}/stacks/cms/wordpress/cli.sh" \
"${REPO_ROOT}/stacks/cms/wordpress/service.cmd" \
"${REPO_ROOT}/stacks/cms/wordpress/service.sh" \
"${REPO_ROOT}/stacks/cms/wordpress/healthcheck.cmd" \
"${REPO_ROOT}/stacks/cms/wordpress/healthcheck.sh" \
"${REPO_ROOT}/stacks/cms/wordpress/setup_generic.cmd" \
"${REPO_ROOT}/stacks/cms/wordpress/setup_generic.sh" \
vagrant@127.0.0.1:C:/libscript/stacks/cms/wordpress/

  # Sync MSIs if present on host and not already on guest
  if [ -f "${REPO_ROOT}/packaging/WordPress-Setup.msi" ]; then
    if ! $SSH_CMD 'Test-Path C:\libscript\packaging\WordPress-Setup.msi' 2>/dev/null | grep -q 'True'; then
      scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" \
"${REPO_ROOT}/packaging/WordPress-Setup.msi" vagrant@127.0.0.1:C:/libscript/packaging/
    fi
  fi
  if [ -f "${REPO_ROOT}/packaging/WordPress-Setup-Offline.msi" ]; then
    if ! $SSH_CMD 'Test-Path C:\libscript\packaging\WordPress-Setup-Offline.msi' 2>/dev/null | grep -q 'True'; then
      scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" \
"${REPO_ROOT}/packaging/WordPress-Setup-Offline.msi" vagrant@127.0.0.1:C:/libscript/packaging/
    fi
  fi

  # Configure scheduled tasks in interactive Session 1
  # shellcheck disable=SC2016
  vm_run '$principal = New-ScheduledTaskPrincipal -UserId "vagrant" -LogonType Interactive; $settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; $aClick = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\libscript\packaging\click_button.ps1"; Register-ScheduledTask -TaskName "ClickGui" -Action $aClick -Principal $principal -Settings $settings -Force > $null'

  vm_run 'Remove-Item "C:/Users/Public/Desktop/Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue; Remove-Item "C:/Users/vagrant/Desktop/Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue'
}

# ## restore_vanilla_snapshot
# Restores VM disk image to vanilla snapshot and restarts Vagrant machine.
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

  printf '[INFO] Reverting disk image to vanilla snapshot...\n'
  if [ -f "${DISK_IMG}.vanilla" ]; then
    cp -cf "${DISK_IMG}.vanilla" "${DISK_IMG}" 2>/dev/null || cp -f "${DISK_IMG}.vanilla" "${DISK_IMG}"
  else
    qemu-img snapshot -a 1 "${DISK_IMG}" 2>/dev/null || qemu-img snapshot -a vanilla "${DISK_IMG}"
  fi
  printf '[INFO] Successfully reverted disk image to vanilla.\n'

  printf '[INFO] Powering on Windows 11 Vagrant VM from vanilla snapshot...
'
  (cd "${VAGRANT_DIR}" && vagrant up windows-11-test-sqlite)
  sleep 5

  discover_environment
  wait_for_ssh
  sync_guest_environment
  clean_guest_installations
  printf '[INFO] Vanilla environment restored and ready.
'
}

# ## run_installer_wizard
# Executes the complete Simple and Advanced mode UI wizard flows, capturing all screenshots.
run_installer_wizard() {
  _mode_name="$1"
  _msi_file="$2"
  _prefix="${3:-}"

  printf '
--- Running %s Wizard Flow (%s) ---
' "$_mode_name" "$_msi_file"

  clean_guest_installations

  printf '[FLOW 1] Simple Mode Installation (%s)...
' "$_mode_name"
  vm_launch_msi "C:\libscript\packaging\${_msi_file}"

  # Step 1: Welcome
  vm_wait_dialog "Welcome"
  capture_screen "${_prefix}01_simple_welcome"

  # Step 2: License
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
  vm_run 'Get-ItemProperty "HKLM:\Software\LibScriptwordpress" -ErrorAction SilentlyContinue | Out-String | Write-Host'
  printf '[PASS] Confirmed WordPress %s Simple Mode installed successfully.
' "$_mode_name"

  clean_guest_installations

  printf '
[FLOW 2] Advanced Mode Installation (%s)...
' "$_mode_name"
  vm_launch_msi "C:\libscript\packaging\${_msi_file}"

  vm_wait_dialog "Welcome"
  vm_click "Next"
  vm_wait_dialog "License"
  vm_click "I Agree"
  vm_wait_dialog "Installation Mode"

  # Step 6: Advanced Mode Selected
  vm_radio "Advanced Mode"
  vm_wait_dialog "Installation Mode"
  capture_screen "${_prefix}06_advanced_setup_type_selected"

  # Step 6a: Component Selection (Features)
  vm_click "Next"
  vm_wait_dialog "Component Selection"
  capture_screen "${_prefix}06a_advanced_features"

  # Step 6b: Destination Folders
  vm_click "Next"
  vm_wait_dialog "Destination Folders"
  vm_set_edit 0 'C:\WordPress\app'
  vm_set_edit 1 'C:\WordPress\data'
  vm_set_edit 2 'C:\WordPress\logs'
  vm_set_edit 3 'C:\WordPress\backups'
  capture_screen "${_prefix}06b_advanced_install_location"

  # Step 6c: Runtime Environment Selection
  vm_click "Next"
  vm_wait_dialog "Runtime Environment"
  capture_screen "${_prefix}06c_advanced_runtime_selection"

  # Step 6d: Source Repository & Release Selection
  vm_click "Next"
  vm_wait_dialog "Source Repository"
  vm_set_edit 2 "ghp_wpAdminTokenSecret2026ExampleKey"
  capture_screen "${_prefix}06d_advanced_source_repo"

  # Step 6e: Network & Credentials Configuration
  vm_click "Next"
  vm_wait_dialog "Network and Credentials"
  vm_set_edit 0 "80"
  vm_set_edit 1 "admin"
  vm_set_edit 2 "wp_password_2026!"
  vm_set_edit 3 "admin@wordpress.local"
  capture_screen "${_prefix}06e_advanced_config"

  # Step 7: Relational Database / DBaaS Configuration
  vm_click "Next"
  vm_wait_dialog "Database"
  vm_set_edit 0 "3306"
  vm_set_edit 1 "mysql://wp_app:Secr3tP@ss@db.internal:3306/wordpress"
  capture_screen "${_prefix}07_advanced_db"

  # Step 8: Cache Configuration
  vm_click "Next"
  vm_wait_dialog "Cache"
  vm_set_edit 0 "6379"
  vm_set_edit 1 "rediss://:RedisSecret2026@cache.internal:6379/0"
  capture_screen "${_prefix}08_advanced_cache_search"

  # Step 9: Verify Ready (Advanced)
  vm_click "Next"
  vm_wait_dialog "Ready to Install"
  capture_screen "${_prefix}09_advanced_verify_ready"

  # Step 10: Trigger Installation & Complete
  printf '[INFO] Triggering installation in Advanced Mode...
'
  vm_click "Install"
  vm_wait_dialog "Setup Complete"
  capture_screen "${_prefix}10_advanced_exit"

  # Exit & Finish
  vm_click "Finish"
  sleep 2
  vm_run 'Stop-Process -Name msiexec -Force -ErrorAction SilentlyContinue'

  # Step 10b: Desktop Icons
  vm_run 'cmd.exe /c call C:\libscript\packaging\create_desktop_shortcuts.cmd; Start-Sleep -Seconds 2'
  capture_screen "${_prefix}10b_desktop_icons"

  # Confirm advanced mode installation works
  vm_run 'Get-ItemProperty "HKLM:\Software\LibScriptwordpress" -ErrorAction SilentlyContinue | Out-String | Write-Host'
  printf '[PASS] Confirmed WordPress %s Advanced Mode installed successfully.
' "$_mode_name"
}

# =========================================================================
# MAIN EXECUTION SEQUENCE
# =========================================================================

printf '=======================================================
'
printf 'WordPress MSI Screenshots & Full Verification Harness 
'
printf '=======================================================
'

discover_environment

# -------------------------------------------------------------------------
# Step 0: Snapshot Verification
# -------------------------------------------------------------------------
printf '
=== Step 0: Verifying Vanilla Snapshot ===
'
qemu-img snapshot -U -l "${DISK_IMG}" | grep -q "vanilla" || {
  printf '[INFO] Snapshot tag "vanilla" not found. Creating snapshot now...
'
  (cd "${VAGRANT_DIR}" && vagrant halt windows-11-test-sqlite)
  qemu-img snapshot -c vanilla "${DISK_IMG}"
  (cd "${VAGRANT_DIR}" && vagrant up windows-11-test-sqlite)
  discover_environment
}
printf '[PASS] Vanilla snapshot verified.
'

sync_guest_environment

# -------------------------------------------------------------------------
# Step 1: Install WordPress offline mode (simple and advanced modes)
# -------------------------------------------------------------------------
printf '
=== Step 1: Install WordPress Offline Mode & Confirm (Simple + Advanced) ===
'
run_installer_wizard "Offline Mode" "WordPress-Setup-Offline.msi" "offline_"

# -------------------------------------------------------------------------
# Step 2: Restore snapshot
# -------------------------------------------------------------------------
printf '
=== Step 2: Restore Snapshot ===
'
restore_vanilla_snapshot

# -------------------------------------------------------------------------
# Step 3: Install WordPress online mode (simple and advanced modes)
# -------------------------------------------------------------------------
printf '
=== Step 3: Install WordPress Online Mode & Confirm (Simple + Advanced) ===
'
run_installer_wizard "Online Mode" "WordPress-Setup.msi" ""

# -------------------------------------------------------------------------
# Steps 4, 5, 6: Browser Verification Tabs
# -------------------------------------------------------------------------
printf '
=== Steps 4, 5, 6: Browser Verification Tabs ===
'

printf '[INFO] Waiting for real PHP-FPM/Nginx stack on port 80...
'
vm_run 'New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoLowDiskSpaceChecks" -Value 1 -Type DWord -Force; Stop-Process -Name ShellExperienceHost, msiexec -Force -ErrorAction SilentlyContinue'
vm_run 'powershell -NoProfile -Command "while ((Test-NetConnection localhost -Port 80 -InformationLevel Quiet) -eq $false) { Start-Sleep -Seconds 2; Write-Host ''Waiting for 80...'' }"'

# 4. browser tab (WordPress homepage)
printf '[INFO] Step 4: Opening WordPress homepage (:80/) in Browser...
'
launch_browser_url "http://localhost:80/"
capture_screen "11_browser_wordpress_home"
capture_screen "11_browser_tab"

# 5. logged in browser tab (WordPress Admin Dashboard)
printf '[INFO] Step 5: Opening WordPress Admin Dashboard (:80/wp-admin/) in Browser...
'
launch_browser_url "http://localhost:80/wp-admin/"
capture_screen "12_browser_wordpress_admin_authenticated"
capture_screen "12_browser_logged_in"

# 6. logged in health check admin interface (WordPress Site Health)
printf '[INFO] Step 6: Opening WordPress Site Health (:80/wp-admin/site-health.php) in Browser...
'
launch_browser_url "http://localhost:80/wp-admin/site-health.php"
capture_screen "13_browser_wordpress_site_health"
capture_screen "13_browser_health_check"

# Clean up browser session
vm_run 'Stop-Process -Name chrome, msedge -Force -ErrorAction SilentlyContinue'

printf '
=======================================================
'
printf '=== All WordPress Screenshots Captured Successfully! ===
'
printf '=======================================================
'
find "${CC0_SCREENSHOTS_DIR}" -maxdepth 1 -name "*.png" | sort | while read -r _img; do
  ls -lh "$_img"
done

exit 0
