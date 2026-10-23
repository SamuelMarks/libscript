#!/bin/sh
# ## Overview
# Automates launching Open edX Windows Installer (.msi) wizard inside Vagrant Windows 11,
# executing offline and online installation workflows, restoring vanilla snapshot checkpoints,
# stepping through every enumeration (Simple Mode and Advanced Mode flows),
# capturing pixel-perfect screenshots of every wizard step (cropped to the Windows Installer window),
# one uncropped desktop screenshot showing the desktop shortcuts,
# and browser validation tabs (cropped to the browser window) directly from the live QEMU display framebuffer.
#
# ## Usage
# ./devtools/capture_openedx_vagrant_screenshots.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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
set +f
export LIBSCRIPT_TEST_TARGET="${LIBSCRIPT_TEST_TARGET:-openedx}"
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
  if [ -d "${VAGRANT_DIR}" ]; then
    SSH_PORT=$(if cd "${VAGRANT_DIR}" 2>/dev/null; then vagrant ssh-config 2>/dev/null | awk '/Port / {print $2; exit}'; fi)
  fi
  : "${SSH_PORT:=50523}"

  SSH_KEY="${HOME}/.vagrant.d/insecure_private_key"
  SSH_CMD="ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i ${SSH_KEY} vagrant@127.0.0.1"

  MONITOR_SOCK=""
  while IFS= read -r sock; do
    [ -z "$sock" ] && continue
    if python3 -c "import socket; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.settimeout(0.5); s.connect('$sock'); s.close()" 2>/dev/null; then
      MONITOR_SOCK="$sock"
      break
    fi
  done <<EOF
$(find "${HOME}/.vagrant.d/tmp/vagrant-qemu" -name "qemu_socket" 2>/dev/null || true)
EOF
  if [ -z "$MONITOR_SOCK" ] || [ ! -S "$MONITOR_SOCK" ]; then
      printf '[ERROR] QEMU Monitor socket not found in ~/.vagrant.d/tmp. VM might not be running.\n' >&2
  fi

  DISK_IMG=$(find -L "${VAGRANT_DIR}/.vagrant/machines/windows-11-test-openedx" -name "linked-box.img" 2>/dev/null | head -n 1 || true)
  if [ -z "$DISK_IMG" ]; then
    DISK_IMG=$(find -L "${VAGRANT_DIR}/.vagrant" -name "linked-box.img" 2>/dev/null | head -n 1 || true)
  fi

  printf '[INFO] Using SSH port: %s\n' "$SSH_PORT"
  printf '[INFO] Found QEMU monitor socket: %s\n' "$MONITOR_SOCK"
  printf '[INFO] Found VM disk image: %s\n' "$DISK_IMG"
}

# ## wait_for_ssh
# Waits until Windows guest SSH service responds.
wait_for_ssh() {
  printf '[INFO] Waiting for Windows 11 SSH service to respond on port %s...\n' "${SSH_PORT}"
  _count=0
  while ! ${SSH_CMD} 'hostname' >/dev/null 2>&1; do
    sleep 3
    _count=$((_count + 1))
    if [ "$_count" -gt 60 ]; then
      printf '[ERROR] Timed out waiting for guest SSH.\n' >&2
      return 1
    fi
  done
  printf '[INFO] Windows 11 guest SSH is responsive.\n'
}

# ## vm_run
# Helper to run commands in the guest via SSH.
vm_run() {
  _rc=1
  for _try in 1 2 3 4 5; do
    if $SSH_CMD "$*; \$global:LASTEXITCODE = 0"; then
      return 0
    fi
    sleep 3
  done
  return $_rc
}

# ## vm_action
# Helper to execute UI automation actions in Session 1 without visible console windows.
vm_action() {
  _act="$1"
  _limit=25
  case "$_act" in
    *"Setup Complete"*|*"Finish"*) _limit=300 ;;
  esac
  vm_run "Set-Content -Path 'C:/libscript/target_btn.txt' -Value '$_act'; Start-ScheduledTask -TaskName 'ClickGui'; \$sw = [System.Diagnostics.Stopwatch]::StartNew(); while ((Get-ScheduledTask -TaskName 'ClickGui').State -eq 'Running' -and \$sw.Elapsed.TotalSeconds -lt $_limit) { Start-Sleep -Milliseconds 300 }; \$task = Get-ScheduledTask -TaskName 'ClickGui'; if (\$task.State -eq 'Ready' -and (Get-ScheduledTaskInfo -TaskName 'ClickGui').LastTaskResult -ne 0) { Write-Error 'ClickGui task failed'; exit 1 }"
  sleep 0.8
}

# ## capture_screen
# Helper to capture QEMU screendump, optionally crop to exact Win32 window bounds, and convert to PNG.
capture_screen() {
  _name="$1"
  _crop_mode="${2:-INSTALLER}"
  _ppm="/tmp/${_name}.ppm"
  _png="${TEMP_DIR}/${_name}.png"
  _bounds=""
  if [ "$_crop_mode" != "FULL" ]; then
    vm_action "BOUNDS:${_crop_mode}" || true
    _bounds=$($SSH_CMD "if (Test-Path 'C:/libscript/window_rect.txt') { (Get-Content 'C:/libscript/window_rect.txt' -Raw).Trim() }" 2>/dev/null | tr -d '\r\n' || true)
  else
    vm_action "BOUNDS:FULL" || true
  fi
  sleep 1.2
  if [ -n "${MONITOR_SOCK}" ] && [ -S "${MONITOR_SOCK}" ]; then
    python3 -c 'import socket, time, sys; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.settimeout(3.0); s.connect(sys.argv[1]); s.sendall(("screendump " + sys.argv[2] + "\n").encode()); time.sleep(0.3); s.close()' "${MONITOR_SOCK}" "${_ppm}" >/dev/null 2>&1 || true
    if command -v sips >/dev/null 2>&1; then
      sips -s format png "$_ppm" --out "$_png" >/dev/null 2>&1
    elif command -v magick >/dev/null 2>&1; then
      magick "$_ppm" "$_png" >/dev/null 2>&1
    fi
    rm -f "$_ppm"
  fi
  if [ -f "$_png" ] && [ -n "$_bounds" ] && [ "$_crop_mode" != "FULL" ]; then
    python3 -c '
import sys, subprocess
png_path, bounds = sys.argv[1], sys.argv[2]
parts = [int(x) for x in bounds.split(",")]
if len(parts) >= 6:
    x, y, w, h, desk_w, desk_h = parts[:6]
    try:
        from PIL import Image
        im = Image.open(png_path)
        img_w, img_h = im.size
        sx = img_w / float(desk_w) if desk_w else 1.0
        sy = img_h / float(desk_h) if desk_h else 1.0
        left = max(0, int(round(x * sx)))
        top = max(0, int(round(y * sy)))
        right = min(img_w, int(round((x + w) * sx)))
        bottom = min(img_h, int(round((y + h) * sy)))
        if right - left > 100 and bottom - top > 100:
            im.crop((left, top, right, bottom)).save(png_path)
    except ImportError:
        subprocess.run(["magick", png_path, "-crop", f"{w}x{h}+{x}+{y}", "+repage", png_path], check=False)
' "$_png" "$_bounds"
  fi
  if [ -f "$_png" ]; then
    if [ -d "${CC0_SCREENSHOTS_DIR}" ]; then
      cp -f "$_png" "${CC0_SCREENSHOTS_DIR}/${_name}.png"
    fi
    rm -f "$_png"
    if [ -f "${CC0_SCREENSHOTS_DIR}/${_name}.png" ]; then
      printf '[CAPTURED] %s.png (%s bytes, mode=%s, bounds=%s)\n' "$_name" "$(wc -c < "${CC0_SCREENSHOTS_DIR}/${_name}.png" | tr -d ' ')" "$_crop_mode" "${_bounds:-full}"
    fi
  fi
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
  _msi_fwd="$1"
  _msi_path="$(echo "$1" | sed 's|/|\\|g')"
  vm_run "if (-not (Test-Path '${_msi_fwd}')) { Write-Error 'MSI missing'; exit 1 }; if ((Get-Item '${_msi_fwd}').Length -lt 10240) { Write-Error 'MSI invalid/empty'; exit 1 }; Unblock-File -Path '${_msi_fwd}' -ErrorAction SilentlyContinue"
  vm_run "\$principal = New-ScheduledTaskPrincipal -UserId 'vagrant' -LogonType Interactive -RunLevel Highest; \$aLaunch = New-ScheduledTaskAction -Execute 'msiexec.exe' -Argument \"/i \`\"${_msi_path}\`\" /l*v \`\"C:\libscript\msi_debug.log\`\"\"; Register-ScheduledTask -TaskName 'LaunchMsi' -Action \$aLaunch -Principal \$principal -Force > \$null; Start-ScheduledTask -TaskName 'LaunchMsi'; Start-Sleep -Seconds 4"
}

# ## launch_browser_url
# Helper to launch web browser to a specified URL (and optional secondary tab URL) in Session 1 without console windows.
launch_browser_url() {
  _url="$1"
  _url2="${2:-}"
  if [ -n "$_url2" ]; then
    vm_run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:/libscript/packaging/open_browser.ps1 -Url '${_url}' -Url2 '${_url2}'"
  else
    vm_run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:/libscript/packaging/open_browser.ps1 -Url '${_url}'"
  fi
  sleep 4
}

# ## register_gui_task
# Registers the ClickGui scheduled task on the guest and suppresses Windows toast popups.
register_gui_task() {
  vm_run 'New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1 -Type DWord -ErrorAction SilentlyContinue; New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue; $principal = New-ScheduledTaskPrincipal -UserId "vagrant" -LogonType Interactive -RunLevel Highest; $settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; $aClick = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:/libscript/packaging/click_button.ps1"; Register-ScheduledTask -TaskName "ClickGui" -Action $aClick -Principal $principal -Settings $settings -Force | Out-Null'
}

# ## clean_guest_installations
# Helper to uninstall Open edX MSI and stop background processes before a fresh mode run.
clean_guest_installations() {
  _msi_path="$1"
  vm_run "Stop-Process -Name msiexec, chrome, msedge -Force -ErrorAction SilentlyContinue; \$p = Start-Process msiexec.exe -ArgumentList '/x \"${_msi_path}\" /qn /norestart' -Wait -PassThru -ErrorAction SilentlyContinue; Remove-Item -Path 'C:/Program Files/OpenEdX', 'C:/Program Files (x86)/OpenEdX', 'C:/ProgramData/OpenEdX', 'C:/Users/vagrant/.libscript/openedx', 'C:/Users/Public/Desktop/Open edX*.lnk', 'C:/Users/vagrant/Desktop/Open edX*.lnk', 'C:/Users/Public/Desktop/Google Chrome.lnk', 'C:/Users/vagrant/Desktop/Google Chrome.lnk' -Recurse -Force -ErrorAction SilentlyContinue"
}

# ## sync_guest_environment
# Rsyncs the libscript repository and MSIs to C:\libscript on the Windows guest.
sync_guest_environment() {
  printf '=== Syncing assets and MSIs to Windows guest ===\n'
  if [ -d "${REPO_ROOT}/../cc0-assets/libscript/openedx/assets" ]; then
    scp -P "${SSH_PORT}" -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" "${REPO_ROOT}/../cc0-assets/libscript/openedx/assets/"* vagrant@127.0.0.1:C:/libscript/packaging/assets/
  fi
  scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" "${REPO_ROOT}/packaging/OpenEdX-Setup.msi" "${REPO_ROOT}/packaging/OpenEdX-Setup-Offline.msi" vagrant@127.0.0.1:C:/libscript/packaging/
  register_gui_task
}

# ## verify_openedx_endpoints
# Confirms that Open edX LMS (:8000) and Studio CMS (:8001) are running and responding.
verify_openedx_endpoints() {
  _label="$1"
  printf '[INFO] Confirming Open edX LMS (:8000) and Studio CMS (:8001) work (%s)...\n' "$_label"
  vm_run 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:/libscript/devtools/wait_ports.ps1'
  vm_run '$r1 = Invoke-WebRequest -Uri "http://127.0.0.1:8000/heartbeat" -UseBasicParsing -TimeoutSec 10; $r2 = Invoke-WebRequest -Uri "http://127.0.0.1:8001/heartbeat" -UseBasicParsing -TimeoutSec 10; if ($r1.StatusCode -ne 200 -or $r2.StatusCode -ne 200) { Write-Error "Heartbeat check failed"; exit 1 }; Write-Host "[PASS] LMS (:8000) and Studio CMS (:8001) verified healthy."'
}

# ## run_msi_mode_flows
# Runs both Simple Mode and Advanced Mode installations for a given MSI variant (offline or online).
run_msi_mode_flows() {
  _var="$1"
  _msi_fwd="$2"
  _msi_win="$(echo "$_msi_fwd" | sed 's|/|\\|g')"

  printf '\n=======================================================\n'
  printf '=== Running %s Mode MSI Installer (Simple Mode) ===\n' "$_var"
  printf '=======================================================\n'
  vm_run 'Stop-Process -Name msiexec, chrome, msedge -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2'
  vm_launch_msi "$_msi_fwd"
  vm_wait_dialog "Welcome"
  capture_screen "${_var}_01_simple_welcome" "INSTALLER"
  vm_click "Next"
  vm_wait_dialog "License"
  capture_screen "${_var}_02_simple_license" "INSTALLER"
  vm_click "I Agree"
  vm_wait_dialog "Choose"
  capture_screen "${_var}_03_simple_setup_type" "INSTALLER"
  vm_click "Next"
  vm_wait_dialog "Ready to Install"
  capture_screen "${_var}_04_simple_verify_ready" "INSTALLER"
  vm_click "Install"
  vm_wait_dialog "Setup Complete"
  capture_screen "${_var}_05_simple_exit" "INSTALLER"
  vm_uncheck "Launch Open edX LMS"
  vm_uncheck "Launch Open edX Studio"
  vm_click "Finish"
  sleep 2
  verify_openedx_endpoints "${_var} - Simple Mode"

  printf '\n=======================================================\n'
  printf '=== Running %s Mode MSI Installer (Advanced Mode) ===\n' "$_var"
  printf '=======================================================\n'
  clean_guest_installations "$_msi_win"
  vm_launch_msi "$_msi_fwd"
  vm_wait_dialog "Welcome"
  vm_click "Next"
  vm_wait_dialog "License"
  vm_click "I Agree"
  vm_wait_dialog "Choose"
  vm_radio "Advanced Mode"
  capture_screen "${_var}_06_advanced_setup_type_selected" "INSTALLER"
  vm_click "Next"
  vm_wait_dialog "Custom Component"
  vm_check "Demo Course"
  vm_check "Micro-Frontends"
  capture_screen "${_var}_06a_advanced_features" "INSTALLER"
  vm_click "Next"
  vm_wait_dialog "Destination"
  vm_set_edit 0 'C:\OpenEdX\app'
  vm_set_edit 1 'C:\OpenEdX\data'
  vm_set_edit 2 'C:\OpenEdX\logs'
  vm_set_edit 3 'C:\OpenEdX\backups'
  capture_screen "${_var}_06b_advanced_install_location" "INSTALLER"
  vm_click "Next"
  vm_wait_dialog "Runtime"
  vm_radio "Install isolated private Python"
  vm_radio "Install isolated private Node.js"
  capture_screen "${_var}_06c_advanced_runtime_selection" "INSTALLER"
  vm_click "Next"
  vm_wait_dialog "Source Repository"
  vm_set_edit 2 "ghp_edxAdminTokenSecret2026ExampleKey"
  capture_screen "${_var}_06d_advanced_source_repo" "INSTALLER"
  vm_click "Next"
  vm_wait_dialog "Network"
  vm_set_edit 0 "8000"
  vm_set_edit 1 "8001"
  vm_set_edit 2 "edx_admin"
  vm_set_edit 3 "edx_password_2026!"
  vm_set_edit 4 "admin@openedx.local"
  vm_set_edit 5 "indigo"
  vm_set_edit 6 "https://github.com/overhangio/tutor-indigo.git"
  capture_screen "${_var}_06e_advanced_config" "INSTALLER"
  vm_click "Next"
  vm_wait_dialog "Database"
  vm_set_edit 0 "3306"
  vm_set_edit 1 "mysql://openedx:@127.0.0.1:3306/openedx"
  capture_screen "${_var}_07_advanced_db" "INSTALLER"
  vm_click "Next"
  vm_wait_dialog "Cache"
  vm_set_edit 0 "6379"
  vm_set_edit 1 "redis://127.0.0.1:6379/0"
  vm_set_edit 2 "mongodb://127.0.0.1:27017/openedx"
  vm_set_edit 3 "http://127.0.0.1:7700"
  capture_screen "${_var}_08_advanced_cache_search" "INSTALLER"
  vm_click "Next"
  vm_wait_dialog "Ready to Install"
  capture_screen "${_var}_09_advanced_verify_ready" "INSTALLER"
  vm_click "Install"
  vm_wait_dialog "Setup Complete"
  capture_screen "${_var}_10_advanced_exit" "INSTALLER"
  vm_uncheck "Launch Open edX LMS"
  vm_uncheck "Launch Open edX Studio"
  vm_click "Finish"
  sleep 2
  vm_run 'Stop-Process -Name msiexec, chrome, msedge -Force -ErrorAction SilentlyContinue'
  vm_run 'Remove-Item -Path "C:\Users\Public\Desktop\Open edX*.lnk", "C:\Users\vagrant\Desktop\Open edX*.lnk", "C:\Users\Public\Desktop\Google Chrome.lnk", "C:\Users\vagrant\Desktop\Google Chrome.lnk" -Force -ErrorAction SilentlyContinue; cmd.exe /c call C:\libscript\packaging\create_desktop_shortcuts.cmd -Stack openedx; Start-Sleep -Seconds 2'
  if [ "$_var" = "online" ]; then
    capture_screen "10b_desktop_icons" "FULL"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_01_simple_welcome.png" "${CC0_SCREENSHOTS_DIR}/01_simple_welcome.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_02_simple_license.png" "${CC0_SCREENSHOTS_DIR}/02_simple_license.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_03_simple_setup_type.png" "${CC0_SCREENSHOTS_DIR}/03_simple_setup_type.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_04_simple_verify_ready.png" "${CC0_SCREENSHOTS_DIR}/04_simple_verify_ready.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_05_simple_exit.png" "${CC0_SCREENSHOTS_DIR}/05_simple_exit.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_06_advanced_setup_type_selected.png" "${CC0_SCREENSHOTS_DIR}/06_advanced_setup_type_selected.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_06a_advanced_features.png" "${CC0_SCREENSHOTS_DIR}/06a_advanced_features.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_06b_advanced_install_location.png" "${CC0_SCREENSHOTS_DIR}/06b_advanced_install_location.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_06c_advanced_runtime_selection.png" "${CC0_SCREENSHOTS_DIR}/06c_advanced_runtime_selection.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_06d_advanced_source_repo.png" "${CC0_SCREENSHOTS_DIR}/06d_advanced_source_repo.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_06e_advanced_config.png" "${CC0_SCREENSHOTS_DIR}/06e_advanced_config.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_07_advanced_db.png" "${CC0_SCREENSHOTS_DIR}/07_advanced_db.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_08_advanced_cache_search.png" "${CC0_SCREENSHOTS_DIR}/08_advanced_cache_search.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_09_advanced_verify_ready.png" "${CC0_SCREENSHOTS_DIR}/09_advanced_verify_ready.png"
    cp -f "${CC0_SCREENSHOTS_DIR}/online_10_advanced_exit.png" "${CC0_SCREENSHOTS_DIR}/10_advanced_exit.png"
  fi
  verify_openedx_endpoints "${_var} - Advanced Mode"
}

# ## restore_vanilla_snapshot
# Stops the VM and restores the vanilla snapshot on the disk image.
restore_vanilla_snapshot() {
  printf '\n=======================================================\n'
  printf '==> Restoring Vanilla Windows 11 Snapshot via QEMU <==\n'
  printf '=======================================================\n'

  printf '[INFO] Stopping Windows 11 Vagrant machine...\n'
  (cd "${VAGRANT_DIR}" && vagrant halt windows-11-test-openedx) || true
  sleep 3

  printf '[INFO] Reverting disk image to vanilla snapshot...\n'
  if [ -f "${DISK_IMG}.vanilla" ]; then
    cp -cf "${DISK_IMG}.vanilla" "${DISK_IMG}" 2>/dev/null || cp -f "${DISK_IMG}.vanilla" "${DISK_IMG}"
  else
    qemu-img snapshot -a vanilla "${DISK_IMG}"
  fi
  printf '[INFO] Successfully reverted disk image to vanilla.\n'

  printf '[INFO] Powering on Windows 11 Vagrant VM from vanilla snapshot...\n'
  (cd "${VAGRANT_DIR}" && vagrant up --no-provision windows-11-test-openedx)
  sleep 5

  discover_environment
  wait_for_ssh
  printf '[INFO] Vanilla environment restored and ready.\n'
}

# =======================================================
# Main Execution Orchestrator
# =======================================================

(cd "${VAGRANT_DIR}" && vagrant up --no-provision windows-11-test-openedx)
discover_environment
wait_for_ssh

# --- Step 0: Snapshot / Rollback to Vanilla Windows 11 ---
printf '\n=======================================================\n'
printf '=== Step 0: Snapshot / Rollback to Vanilla Windows 11 ===\n'
printf '=======================================================\n'
if [ -n "$DISK_IMG" ] && [ -f "$DISK_IMG" ]; then
  if [ ! -f "${DISK_IMG}.vanilla" ] && ! qemu-img snapshot -U -l "${DISK_IMG}" 2>/dev/null | grep -q "vanilla"; then
    printf '[INFO] Snapshot "vanilla" not found. Creating clean vanilla snapshot now...\n'
    vm_run "Stop-Process -Name msiexec, chrome, msedge, WindowsTerminal, OpenConsole, cmd -Force -ErrorAction SilentlyContinue; Remove-Item -Path 'C:\Program Files\OpenEdX', 'C:\Program Files (x86)\OpenEdX', 'C:\ProgramData\OpenEdX', 'C:\Users\vagrant\.libscript\openedx', 'C:\Users\Public\Desktop\Open edX*.lnk', 'C:\Users\vagrant\Desktop\Open edX*.lnk', 'C:\libscript\*.msi', 'C:\libscript\*.wxs', 'C:\libscript\*.wixobj' -Recurse -Force -ErrorAction SilentlyContinue"
    (cd "${VAGRANT_DIR}" && vagrant halt windows-11-test-openedx)
    qemu-img snapshot -c vanilla "${DISK_IMG}"
    cp -cf "${DISK_IMG}" "${DISK_IMG}.vanilla" 2>/dev/null || cp -f "${DISK_IMG}" "${DISK_IMG}.vanilla"
    (cd "${VAGRANT_DIR}" && vagrant up --no-provision windows-11-test-openedx)
    discover_environment
    wait_for_ssh
  else
    restore_vanilla_snapshot
  fi
fi

# --- Build Offline & Online MSIs on Vagrant with msi-rs (without --use-wix) ---
printf '\n=======================================================\n'
printf '=== Building Open edX MSIs (Offline & Online) via msi-rs on Vagrant ===\n'
printf '=======================================================\n'
if [ -d "${REPO_ROOT}/../cc0-assets/libscript/openedx/assets" ]; then
  scp -P "${SSH_PORT}" -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" "${REPO_ROOT}/../cc0-assets/libscript/openedx/assets/"* vagrant@127.0.0.1:C:/libscript/packaging/assets/
fi
if [ -d "${REPO_ROOT}/../msi-rs/target/aarch64-pc-windows-gnullvm/release" ]; then
  scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" "${REPO_ROOT}/../msi-rs/target/aarch64-pc-windows-gnullvm/release/candle.exe" "${REPO_ROOT}/../msi-rs/target/aarch64-pc-windows-gnullvm/release/light.exe" "${REPO_ROOT}/../msi-rs/target/aarch64-pc-windows-gnullvm/release/msiinfo.exe" "${REPO_ROOT}/../msi-rs/target/aarch64-pc-windows-gnullvm/release/msi-cli.exe" "${REPO_ROOT}/../msi-rs/target/aarch64-pc-windows-gnullvm/release/wix.exe" vagrant@127.0.0.1:C:/Users/vagrant/.libscript/msi-rs/v0.0.1/bin/
fi
vm_run '$env:PATH += ";" + $env:USERPROFILE + "\.libscript\msi-rs\default\bin;" + $env:USERPROFILE + "\.libscript\msi-rs\v0.0.1\bin"; cd C:\libscript; cmd.exe /c "packaging\build_msi.cmd _lib\web-apps\openedx --online --out C:\libscript\packaging\OpenEdX-Setup"; cmd.exe /c "packaging\build_msi.cmd _lib\web-apps\openedx --offline --out C:\libscript\packaging\OpenEdX-Setup-Offline"'
scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" vagrant@127.0.0.1:C:/libscript/packaging/OpenEdX-Setup.msi "${REPO_ROOT}/packaging/OpenEdX-Setup.msi"
scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" vagrant@127.0.0.1:C:/libscript/packaging/OpenEdX-Setup-Offline.msi "${REPO_ROOT}/packaging/OpenEdX-Setup-Offline.msi"

# --- Step 1: Install Open edX Offline Mode (Simple & Advanced) and Confirm It Works ---
printf '\n=======================================================\n'
printf '=== Step 1: Install Open edX Offline Mode (Simple & Advanced) ===\n'
printf '=======================================================\n'
register_gui_task
run_msi_mode_flows "offline" "C:/libscript/packaging/OpenEdX-Setup-Offline.msi"

# --- Step 2: Restore Snapshot ---
printf '\n=======================================================\n'
printf '=== Step 2: Restore Vanilla Snapshot ===\n'
printf '=======================================================\n'
restore_vanilla_snapshot
sync_guest_environment

# --- Step 3: Install Open edX Online Mode (Simple & Advanced) and Confirm It Works ---
printf '\n=======================================================\n'
printf '=== Step 3: Install Open edX Online Mode (Simple & Advanced) ===\n'
printf '=======================================================\n'
run_msi_mode_flows "online" "C:/libscript/packaging/OpenEdX-Setup.msi"

# --- Steps 4 - 7: Browser Verification Tabs (Cropped to Browser Window) ---
printf '\n=======================================================\n'
printf '=== Steps 4 - 7: Browser Verification & Authentication Tabs ===\n'
printf '=======================================================\n'

# Step 4: browser tab (CMS)
printf '\n[INFO] Step 4: Opening Studio CMS (:8001/signin) in Browser...\n'
launch_browser_url "http://localhost:8001/signin" "http://localhost:8000/login"
capture_screen "12_browser_studio_focused" "BROWSER"

# Step 5: browser tab (LMS)
printf '\n[INFO] Step 5: Opening LMS Portal (:8000/login) in Browser...\n'
launch_browser_url "http://localhost:8000/login" "http://localhost:8001/signin"
capture_screen "11_browser_lms_focused" "BROWSER"

# Step 6: logged in browser tab (CMS)
printf '\n[INFO] Step 6: Logging in to Studio CMS Dashboard (:8001/home) in Browser...\n'
launch_browser_url "http://localhost:8001/home" "http://localhost:8000/dashboard"
capture_screen "14_browser_studio_authenticated" "BROWSER"

# Step 7: logged in browser tab (LMS)
printf '\n[INFO] Step 7: Logging in to LMS Dashboard (:8000/dashboard) in Browser...\n'
launch_browser_url "http://localhost:8000/dashboard" "http://localhost:8001/home"
capture_screen "13_browser_lms_authenticated" "BROWSER"

# Clean up browser session
vm_run 'Stop-Process -Name chrome, msedge -Force -ErrorAction SilentlyContinue'

printf '\n=======================================================\n'
printf '=== All Open edX Vagrant Windows Screenshots Captured Successfully! ===\n'
printf '=======================================================\n'
find "${CC0_SCREENSHOTS_DIR}" -maxdepth 1 -name "*.png" | sort | while read -r _img; do
  ls -lh "$_img"
done

exit 0
