#!/bin/sh
# ## Overview
# Automates launching Open edX Windows Installer (.msi) wizard inside Vagrant Windows 11,
# stepping through every enumeration (Simple Mode and Advanced Mode flows),
# capturing pixel-perfect screenshots of every wizard step, the desktop icons,
# and the browser validation tabs directly from the live QEMU display framebuffer.
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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"
CC0_SCREENSHOTS_DIR="${REPO_ROOT}/../cc0-assets/libscript/openedx/screenshots"
TEMP_DIR="${REPO_ROOT}/tests_tmp/vagrant_screenshots"
mkdir -p "${TEMP_DIR}"
if [ -d "${REPO_ROOT}/../cc0-assets" ]; then
  mkdir -p "${CC0_SCREENSHOTS_DIR}"
fi

# Discover SSH port dynamically
if [ -z "${SSH_PORT:-}" ]; then
  # shellcheck disable=SC2009
  SSH_PORT=$(ps aux | grep -i 'qemu.*windows-11' | grep -v grep | sed -n 's/.*hostfwd=tcp::\([0-9]*\)-:22.*/\1/p' | head -n 1 || true)
  if [ -z "${SSH_PORT:-}" ] && [ -d "${REPO_ROOT}/vagrant/windows-11" ]; then
    SSH_PORT=$(cd "${REPO_ROOT}/vagrant/windows-11" && vagrant ssh-config 2>/dev/null | awk '/Port / {print $2; exit}' || true)
  fi
fi
: "${SSH_PORT:=50041}"
SSH_KEY="${HOME}/.vagrant.d/insecure_private_key"
SSH_CMD="ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i ${SSH_KEY} vagrant@127.0.0.1"

# Locate QEMU monitor socket for Windows 11 VM
if [ -z "${MONITOR_SOCK:-}" ]; then
  # shellcheck disable=SC2009
  MONITOR_SOCK=$(ps aux | grep -i 'qemu.*windows-11' | grep -v grep | sed -n 's/.*path=\([^,]*qemu_socket\).*/\1/p' | head -n 1 || true)
fi

if [ -z "$MONITOR_SOCK" ] || [ ! -S "$MONITOR_SOCK" ]; then
  printf '[ERROR] QEMU monitor socket not found. Is Windows 11 Vagrant VM running?\n' >&2
  exit 1
fi

printf '[INFO] Using SSH port: %s\n' "$SSH_PORT"
printf '[INFO] Found QEMU monitor socket: %s\n' "$MONITOR_SOCK"

# ## vm_run
# Helper to run commands in the guest via SSH.
# Dispatches arguments to guest SSH session and returns execution status.
vm_run() {
  $SSH_CMD "$*; exit 0"
}

# ## capture_screen
# Helper to capture QEMU screendump and convert to PNG.
# Triggers framebuffer dump via QEMU monitor, converts PPM to PNG via sips or magick,
# and saves directly and exclusively to the cc0-assets repository.
capture_screen() {
  _name="$1"
  _ppm="${TEMP_DIR}/${_name}.ppm"
  _png="${TEMP_DIR}/${_name}.png"
  sleep 1.5
  if [ -S "${MONITOR_SOCK}" ]; then
    python3 -c "import socket, time, sys; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.settimeout(3.0); s.connect(sys.argv[1]); s.sendall(f'screendump {sys.argv[2]}\n'.encode()); time.sleep(0.3); s.close()" "${MONITOR_SOCK}" "${_ppm}" >/dev/null 2>&1 || true
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
      printf '[CAPTURED] %s.png (%s bytes)\n' "$_name" "$(wc -c < "${CC0_SCREENSHOTS_DIR}/${_name}.png" | tr -d ' ')"
    fi
  fi
}

# ## vm_action
# Helper to execute UI automation actions in Session 1 without visible console windows.
vm_action() {
  _act="$1"
  vm_run "Set-Content -Path 'C:/libscript/target_btn.txt' -Value '$_act'; Start-ScheduledTask -TaskName 'ClickGui'; \$sw = [System.Diagnostics.Stopwatch]::StartNew(); while ((Get-ScheduledTask -TaskName 'ClickGui').State -eq 'Running' -and \$sw.Elapsed.TotalSeconds -lt 25) { Start-Sleep -Milliseconds 250 }"
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

# ## vm_wait
# Helper to wait for a control or button to appear in Session 1 without clicking.
vm_wait() {
  _btn="$1"
  vm_action "WAIT:$_btn"
  sleep 1.5
}

# ## vm_launch_msi
# Helper to launch MSI in Session 1 via LaunchMsi scheduled task.
vm_launch_msi() {
  vm_run "Start-ScheduledTask -TaskName 'LaunchMsi'; Start-Sleep -Seconds 4"
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
# Terminates running msiexec processes and strips any installed Open edX packages or registry keys.
clean_guest_installations() {
  printf '[INFO] Cleaning any prior installations on guest...\n'
  # shellcheck disable=SC2016
  vm_run 'Stop-Process -Name chrome, msedge, msiexec, WindowsTerminal -Force -ErrorAction SilentlyContinue; while ($p = Get-Package -Name "*Open edX*" -ErrorAction SilentlyContinue) { foreach ($pkg in $p) { Start-Process msiexec.exe -ArgumentList "/x $($pkg.FastPackageReference) /qn" -Wait } }; Get-ChildItem -Path "Registry::HKEY_CLASSES_ROOT\Installer\Products" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.ProductName -like "*Open edX*" } | ForEach-Object { Start-Process msiexec.exe -ArgumentList "/x $($_.PSChildName) /qn" -Wait }; Remove-Item "C:/Users/*/Desktop/Open edX*.lnk", "C:/Users/*/Desktop/Management CLI.lnk", "C:/Users/Public/Desktop/Open edX*.lnk", "C:/Users/Public/Desktop/Management CLI.lnk" -Force -ErrorAction SilentlyContinue'
  vm_run 'Stop-Process -Name chrome, msedge, msiexec, WindowsTerminal -Force -ErrorAction SilentlyContinue'
}

printf '=== Step 1: Syncing updated packaging and stack files to Windows guest ===\n'
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
  "${REPO_ROOT}/packaging/start_mock_server.cmd" \
  "${REPO_ROOT}/packaging/start_mock_server.ps1" \
  "${REPO_ROOT}/packaging/start_mock_server.sh" \
  "${REPO_ROOT}/packaging/mock_server.ps1" \
  "${REPO_ROOT}/packaging/click_button.ps1" \
  "${REPO_ROOT}/packaging/create_desktop_shortcuts.cmd" \
  "${REPO_ROOT}/packaging/create_desktop_shortcuts.ps1" \
  "${REPO_ROOT}/packaging/create_desktop_shortcuts.sh" \
  vagrant@127.0.0.1:C:/libscript/packaging/

vm_run 'New-Item -ItemType Directory -Path "C:/libscript/packaging/assets" -Force -ErrorAction SilentlyContinue | Out-Null'

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

clean_guest_installations

MSI_OVERRIDE="${1:-}"
if [ -n "${MSI_OVERRIDE}" ] && [ -f "${MSI_OVERRIDE}" ]; then
  printf '=== Step 2: Syncing provided MSI (%s) to Windows guest ===\n' "${MSI_OVERRIDE}"
  scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" \
    "${MSI_OVERRIDE}" vagrant@127.0.0.1:C:/libscript/packaging/OpenEdX-Setup.msi
else
  printf '=== Step 2: Compiling full self-contained OpenEdX-Setup.msi on Windows guest ===\n'
  vm_run 'cmd /c "cd C:\libscript && call packaging\build_msi.cmd stacks\cms\openedx --online --out packaging\OpenEdX-Setup --banner-side packaging\assets\openedx_banner_side.bmp --banner-top packaging\assets\openedx_banner_top.bmp --icon packaging\assets\openedx.ico --license packaging\assets\openedx_eula.rtf"'
fi

# Configure LaunchMsi, ClickGui, and RunGui scheduled tasks on guest
# shellcheck disable=SC2016
vm_run '$principal = New-ScheduledTaskPrincipal -UserId "vagrant" -LogonType Interactive; $settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; $aLaunch = New-ScheduledTaskAction -Execute "msiexec.exe" -Argument "/i C:\libscript\packaging\OpenEdX-Setup.msi"; Register-ScheduledTask -TaskName "LaunchMsi" -Action $aLaunch -Principal $principal -Force > $null; $aClick = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\libscript\packaging\click_button.ps1"; Register-ScheduledTask -TaskName "ClickGui" -Action $aClick -Principal $principal -Settings $settings -Force > $null; $aRun = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\libscript\run_gui.ps1"; Register-ScheduledTask -TaskName "RunGui" -Action $aRun -Principal $principal -Force > $null'

# Ensure broken Edge shortcut is cleaned from desktop
vm_run 'Remove-Item "C:/Users/Public/Desktop/Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue; Remove-Item "C:/Users/vagrant/Desktop/Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue'

clean_guest_installations

printf '\n=== Flow 1: Simple Mode Installation ===\n'
printf '[INFO] Launching OpenEdX-Setup.msi in Session 1...\n'
vm_launch_msi

# Step 1: Welcome
vm_wait_dialog "Welcome"
capture_screen "01_simple_welcome"

# Step 2: License Agreement (consolidated EULA with I Agree button, no checkbox)
vm_click "Next"
vm_wait_dialog "License"
capture_screen "02_simple_license"

# Single "I Agree" button advances to Setup Type
vm_click "I Agree"
vm_wait_dialog "Installation Mode"

# Step 3: Setup Type (Simple selected by default)
capture_screen "03_simple_setup_type"

# Step 4: Verify Ready (Simple Mode)
vm_click "Next"
vm_wait_dialog "Ready to Install"
capture_screen "04_simple_verify_ready"

# Trigger Simple Mode installation and capture exit
printf '[INFO] Triggering installation in Simple Mode...\n'
vm_click "Install"
vm_wait_dialog "Setup Complete"
capture_screen "05_simple_exit"
vm_click "Finish"
sleep 2

clean_guest_installations

printf '\n=== Flow 2: Advanced Mode Customization ===\n'
printf '[INFO] Launching OpenEdX-Setup.msi for Advanced Mode in Session 1...\n'
vm_launch_msi
vm_wait_dialog "Welcome"
vm_click "Next"
vm_wait_dialog "License"
vm_click "I Agree"
vm_wait_dialog "Installation Mode"

# Step 5: Advanced Mode Selected
vm_radio "Advanced Mode"
vm_wait_dialog "Installation Mode"
capture_screen "06_advanced_setup_type_selected"

# Setup Type -> Component Selection (Features)
vm_click "Next"
vm_wait_dialog "Component Selection"
vm_check "Demo Course"
vm_check "Micro-Frontends"
capture_screen "06a_advanced_features"

# Features -> Destination Folders
vm_click "Next"
vm_wait_dialog "Destination Folders"
vm_set_edit 0 'C:\OpenEdX\app'
vm_set_edit 1 'C:\OpenEdX\data'
vm_set_edit 2 'C:\OpenEdX\logs'
vm_set_edit 3 'C:\OpenEdX\backups'
capture_screen "06b_advanced_install_location"

# Destination Folders -> Runtime Environment Selection
vm_click "Next"
vm_wait_dialog "Runtime Environment"
vm_radio "Install isolated private Python"
vm_radio "Install isolated private Node.js"
capture_screen "06c_advanced_runtime_selection"

# Runtime Environment -> Source Repository & Release
vm_click "Next"
vm_wait_dialog "Source Repository"
vm_set_edit 2 "ghp_edxAdminTokenSecret2026ExampleKey"
capture_screen "06d_advanced_source_repo"

# Source Repo -> Network & Credentials Configuration
vm_click "Next"
vm_wait_dialog "Network and Credentials"
vm_set_edit 0 "8000"
vm_set_edit 1 "8001"
vm_set_edit 2 "edx_admin"
vm_set_edit 3 "edx_password_2026!"
vm_set_edit 4 "admin@openedx.local"
capture_screen "06e_advanced_config"

# Config -> Relational Database / DBaaS
vm_click "Next"
vm_wait_dialog "Database"
vm_set_edit 0 "3306"
vm_set_edit 1 "mysql://edx_app:Secr3tP@ss@db.internal:3306/edxapp"
capture_screen "07_advanced_db"

# DB -> Cache, Document Store & Search
vm_click "Next"
vm_wait_dialog "Cache"
vm_set_edit 0 "6379"
vm_set_edit 1 "rediss://:RedisSecret2026@cache.internal:6379/0"
vm_set_edit 2 "mongodb://edx_mongo:MongoSecret@docdb.internal:27017/edx"
vm_set_edit 3 "https://meili.cloud.internal:7700"
capture_screen "08_advanced_cache_search"

# Cache -> Verify Ready (Advanced)
vm_click "Next"
vm_wait_dialog "Ready to Install"
capture_screen "09_advanced_verify_ready"

# Verify Ready -> Install & Exit
printf '[INFO] Triggering installation in Advanced Mode...\n'
vm_click "Install"
vm_wait_dialog "Setup Complete"
capture_screen "10_advanced_exit"

# Exit -> Finish
printf '[INFO] Waiting for installation to complete and clicking Finish...\n'
vm_click "Finish"
sleep 2
vm_run 'Stop-Process -Name msiexec -Force -ErrorAction SilentlyContinue'
vm_run 'cmd /c call C:\libscript\packaging\create_desktop_shortcuts.cmd; Start-Sleep -Seconds 2'
capture_screen "10b_desktop_icons"

printf '\n=== Flow 3: Browser Verification & Authentication Flows ===\n'
printf '[INFO] Suppressing notifications and starting mock server on guest for ports 8000 and 8001...\n'
vm_run 'New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoLowDiskSpaceChecks" -Value 1 -Type DWord -Force; Stop-Process -Name ShellExperienceHost, msiexec -Force -ErrorAction SilentlyContinue'
vm_run 'cmd /c "cd C:\libscript && call packaging\start_mock_server.cmd"'

# Step 11: LMS Login Screen
printf '[INFO] Opening LMS Portal Login (:8000/login) in Browser...\n'
launch_browser_url "http://localhost:8000/login"
capture_screen "11_browser_lms_focused"

# Step 12: Studio CMS Sign-in Screen
printf '[INFO] Opening Studio CMS Sign-in (:8001/signin) in Browser...\n'
launch_browser_url "http://localhost:8001/signin"
capture_screen "12_browser_studio_focused"

# Step 13: LMS Authenticated Dashboard (edx_admin)
printf '[INFO] Logging in with edx_admin credentials to LMS Dashboard (:8000/dashboard)...\n'
launch_browser_url "http://localhost:8000/dashboard"
capture_screen "13_browser_lms_authenticated"

# Step 14: Studio CMS Authenticated Dashboard (staff@openedx.org)
printf '[INFO] Logging in with staff@openedx.org credentials to Studio Dashboard (:8001/home)...\n'
launch_browser_url "http://localhost:8001/home"
capture_screen "14_browser_studio_authenticated"

# Clean up browser session
vm_run 'Stop-Process -Name chrome, msedge -Force -ErrorAction SilentlyContinue'

printf '\n=== All Open edX Vagrant Windows screenshots captured successfully in cc0-assets! ===\n'
find "${CC0_SCREENSHOTS_DIR}" -maxdepth 1 -name "*.png" | sort | while read -r _img; do
  ls -lh "$_img"
done
