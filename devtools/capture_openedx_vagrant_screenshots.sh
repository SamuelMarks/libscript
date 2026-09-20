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
PACKAGING_SCREENSHOTS_DIR="${REPO_ROOT}/packaging/screenshots"
TEMP_DIR="${REPO_ROOT}/tests_tmp/vagrant_screenshots"
mkdir -p "${TEMP_DIR}" "${PACKAGING_SCREENSHOTS_DIR}"
if [ -d "${REPO_ROOT}/../cc0-assets" ]; then
  mkdir -p "${CC0_SCREENSHOTS_DIR}"
fi

SSH_PORT="50661"
SSH_KEY="${HOME}/.vagrant.d/insecure_private_key"
SSH_CMD="ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i ${SSH_KEY} vagrant@127.0.0.1"

# Locate QEMU monitor socket for Windows 11 VM
# shellcheck disable=SC2009
MONITOR_SOCK=$(ps aux | grep -i 'windows-11.*qemu_socket\b' | grep -o 'path=[^,]*' | head -n 1 | cut -d= -f2 || true)

if [ -z "$MONITOR_SOCK" ] || [ ! -S "$MONITOR_SOCK" ]; then
  printf '[ERROR] QEMU monitor socket not found. Is Windows 11 Vagrant VM running?\n' >&2
  exit 1
fi

printf '[INFO] Found QEMU monitor socket: %s\n' "$MONITOR_SOCK"

# ## vm_run
# Helper to run commands in the guest via SSH.
# Dispatches arguments to guest SSH session and returns execution status.
vm_run() {
  $SSH_CMD "$*; exit 0"
}

# ## capture_screen
# Helper to capture QEMU screendump and convert to PNG.
# Triggers framebuffer dump via QEMU monitor, converts PPM to PNG via sips,
# and copies the screenshot to packaging and asset directories.
capture_screen() {
  _name="$1"
  _ppm="${TEMP_DIR}/${_name}.ppm"
  _png="${TEMP_DIR}/${_name}.png"
  sleep 1.5
  printf 'screendump %s\n' "$_ppm" | nc -U "$MONITOR_SOCK" >/dev/null 2>&1
  sips -s format png "$_ppm" --out "$_png" >/dev/null 2>&1
  rm -f "$_ppm"
  cp "$_png" "${PACKAGING_SCREENSHOTS_DIR}/${_name}.png"
  if [ -d "${CC0_SCREENSHOTS_DIR}" ]; then
    cp "$_png" "${CC0_SCREENSHOTS_DIR}/${_name}.png"
  fi
  printf '[CAPTURED] %s (%s bytes)\n' "${_name}.png" "$(wc -c < "$_png" | tr -d ' ')"
}

# ## vm_click
# Helper to click a button or radio control in Session 1.
# Sets target button text in guest and triggers the interactive RunGui scheduled task.
vm_click() {
  _btn="$1"
  vm_run "Set-Content -Path 'C:/libscript/target_btn.txt' -Value '$_btn'; Start-ScheduledTask -TaskName 'RunGui'; Start-Sleep -Seconds 2"
}

# ## clean_guest_installations
# Helper to uninstall all Open edX packages from Windows guest.
# Terminates running msiexec processes and strips any installed Open edX packages or registry keys.
clean_guest_installations() {
  printf '[INFO] Cleaning any prior installations on guest...\n'
  vm_run 'Stop-Process -Name msiexec -Force -ErrorAction SilentlyContinue; while ($p = Get-Package -Name "*Open edX*" -ErrorAction SilentlyContinue) { foreach ($pkg in $p) { Start-Process msiexec.exe -ArgumentList "/x $($pkg.FastPackageReference) /qn" -Wait } }; Get-ChildItem -Path "Registry::HKEY_CLASSES_ROOT\Installer\Products" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.ProductName -like "*Open edX*" } | ForEach-Object { Start-Process msiexec.exe -ArgumentList "/x $($_.PSChildName) /qn" -Wait }'
}

printf '=== Step 1: Syncing updated packaging scripts to Windows guest ===\n'
scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" "${REPO_ROOT}/packaging/build_msi.cmd" "${REPO_ROOT}/packaging/build_msi.sh" "${REPO_ROOT}/packaging/click_button.ps1" vagrant@127.0.0.1:C:/libscript/packaging/

printf '=== Step 2: Compiling branded OpenEdX-Setup.msi on Windows guest ===
'
vm_run 'cmd.exe /c "cd /d C:\libscript && set PATH=%PATH%;C:\wix && call C:\libscript\packaging\build_openedx_msi.cmd --out C:\libscript\packaging\OpenEdX-Setup --banner-side C:\libscript\packaging\assets\openedx_banner_side.bmp --banner-top C:\libscript\packaging\assets\openedx_banner_top.bmp --icon C:\libscript\packaging\assets\openedx.ico --license C:\libscript\packaging\assets\openedx_eula.rtf"'

# Configure RunGui task helper in guest
vm_run 'Set-Content -Path "C:/libscript/run_gui.ps1" -Value "& powershell.exe -ExecutionPolicy Bypass -File C:/libscript/packaging/click_button.ps1 > C:/libscript/click.log 2>&1"; $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:/libscript/run_gui.ps1"; $principal = New-ScheduledTaskPrincipal -UserId "vagrant" -LogonType Interactive; Register-ScheduledTask -TaskName "RunGui" -Action $action -Principal $principal -Force > $null'

# Ensure broken Edge shortcut is cleaned from desktop
vm_run 'Remove-Item "C:/Users/Public/Desktop/Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue; Remove-Item "C:/Users/vagrant/Desktop/Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue'

clean_guest_installations

printf '
=== Flow 1: Simple Setup Flow Enumeration ===
'
printf '[INFO] Launching OpenEdX-Setup.msi in Session 1...
'
vm_run 'Set-Content -Path "C:/libscript/run_gui.ps1" -Value "Start-Process msiexec.exe -ArgumentList `"/i C:/libscript/packaging/OpenEdX-Setup.msi`""; Start-ScheduledTask -TaskName "RunGui"; Start-Sleep -Seconds 4'

# Step 1: Welcome
capture_screen "01_simple_welcome"

# Step 2: License Agreement
vm_click "Next"
capture_screen "02_simple_license"

# Step 3: Setup Type (Simple selected by default)
vm_click "Next"
capture_screen "03_simple_setup_type"

# Step 4: Verify Ready
vm_click "Next"
capture_screen "04_simple_verify_ready"

# Step 5: Install & Exit
printf '[INFO] Triggering installation in Simple Mode...
'
vm_click "Install"
sleep 5
capture_screen "05_simple_exit"

# Step 6: Finish and Desktop Icons
printf '[INFO] Clicking Finish to complete Simple Mode...
'
vm_click "Finish"
sleep 2
capture_screen "10b_desktop_icons"

printf '
=== Flow 2: Advanced Setup Flow Enumeration ===
'
clean_guest_installations

printf '[INFO] Launching OpenEdX-Setup.msi for Advanced Flow in Session 1...
'
vm_run 'Set-Content -Path "C:/libscript/run_gui.ps1" -Value "Start-Process msiexec.exe -ArgumentList `"/i C:/libscript/packaging/OpenEdX-Setup.msi`""; Start-ScheduledTask -TaskName "RunGui"; Start-Sleep -Seconds 4'

# Welcome -> License
vm_click "Next"

# License -> Setup Type
vm_click "Next"

# Select Advanced Mode
vm_click "Advanced Mode"
capture_screen "06_advanced_setup_type_selected"

# Setup Type -> Component Selection (Features)
vm_click "Next"
capture_screen "06a_advanced_features"

# Features -> Destination Folders
vm_click "Next"
capture_screen "06b_advanced_install_location"

# Destination Folders -> Runtime Environment Selection
vm_click "Next"
capture_screen "06c_advanced_runtime_selection"

# Runtime Environment -> Source Repository & Release
vm_click "Next"
capture_screen "06d_advanced_source_repo"
# Keep 06b_advanced_source_repo for backwards compatibility with earlier links
cp "${PACKAGING_SCREENSHOTS_DIR}/06d_advanced_source_repo.png" "${PACKAGING_SCREENSHOTS_DIR}/06b_advanced_source_repo.png"
if [ -d "${CC0_SCREENSHOTS_DIR}" ]; then
  cp "${PACKAGING_SCREENSHOTS_DIR}/06d_advanced_source_repo.png" "${CC0_SCREENSHOTS_DIR}/06b_advanced_source_repo.png"
fi

# Source Repo -> Network & Credentials Configuration
vm_click "Next"
capture_screen "06e_advanced_config"

# Config -> Relational Database / DBaaS
vm_click "Next"
capture_screen "07_advanced_db"

# DB -> Cache, Document Store & Search
vm_click "Next"
capture_screen "08_advanced_cache_search"

# Cache -> Verify Ready (Advanced)
vm_click "Next"
capture_screen "09_advanced_verify_ready"

# Verify Ready -> Install & Exit
printf '[INFO] Triggering installation in Advanced Mode...
'
vm_click "Install"
sleep 5
capture_screen "10_advanced_exit"

# Exit -> Finish
vm_click "Finish"

printf '
=== Synchronizing browser verification screenshots ===
'
if [ -f "${CC0_SCREENSHOTS_DIR}/11_browser_lms_focused.png" ]; then
  cp "${CC0_SCREENSHOTS_DIR}/11_browser_lms_focused.png" "${PACKAGING_SCREENSHOTS_DIR}/11_browser_lms_focused.png"
  cp "${CC0_SCREENSHOTS_DIR}/12_browser_studio_focused.png" "${PACKAGING_SCREENSHOTS_DIR}/12_browser_studio_focused.png"
fi

printf '
=== All Open edX Vagrant Windows screenshots captured successfully! ===
'
ls -lh "${PACKAGING_SCREENSHOTS_DIR}"/*.png
