#!/bin/sh
# ## Overview
# Clean-snapshot 3-mode installer runner (`Step 2`) driving `headless`, `quick`, and `custom` guest installs.
# ## Usage
# ./_lib/_common/experiment/install_modes.sh <stage|headless|quick|custom|run-trial> [args...]
set -feu
_im_caller_this="${THIS_FILE:-}"; _im_caller_dir="${SCRIPT_DIR:-}"
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi
case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if [ -n "$_im_caller_this" ]; then THIS_FILE="$_im_caller_this"; fi; if [ -n "$_im_caller_dir" ]; then SCRIPT_DIR="$_im_caller_dir"; fi
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

for _im_lib in '_lib/_common/experiment/vagrant_substrate.sh' '_lib/_common/experiment/guest_ui_verify.sh'; do
  if [ -f "${LIBSCRIPT_ROOT_DIR}/${_im_lib}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_im_lib}"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "$SCRIPT_NAME"
  fi
done
unset SCRIPT_NAME || true

# ## im_guest_stage_dir
# Returns the isolated staging directory path inside the guest OS.
im_guest_stage_dir() {
  if [ "${1:-windows}" = 'windows' ]; then
    printf '%s\n' 'C:/libscript_exp'
  else
    printf '%s\n' '/tmp/libscript_exp'
  fi
}

# ## im_stage_package_to_guest
# Uploads the resolved installer artifact, target packaging.json, and guest UI helpers into the guest staging directory.
im_stage_package_to_guest() {
  _im_ws="${1:?workspace required}"
  _im_fam="${2:?os-family required}"
  _im_pkg="${3:?host package path required}"
  _im_man="${4:?packaging.json required}"
  _im_guest_dir=$(im_guest_stage_dir "$_im_fam")
  _im_pkg_base=$(basename "$_im_pkg")

  if [ "$_im_fam" = 'windows' ]; then
    vs_exec_guest "$_im_ws" 'windows' "New-Item -ItemType Directory -Force -Path '${_im_guest_dir}/screenshots' | Out-Null"
  else
    vs_exec_guest "$_im_ws" "$_im_fam" "mkdir -p '${_im_guest_dir}/screenshots'"
  fi

  vs_upload_guest "$_im_ws" "$_im_pkg" "${_im_guest_dir}/${_im_pkg_base}"
  vs_upload_guest "$_im_ws" "$_im_man" "${_im_guest_dir}/packaging.json"

  for _im_hlp in \
    "${LIBSCRIPT_ROOT_DIR}/packaging/click_button.sh" \
    "${LIBSCRIPT_ROOT_DIR}/packaging/click_button.cmd" \
    "${LIBSCRIPT_ROOT_DIR}/packaging/click_button.ps1" \
    "${LIBSCRIPT_ROOT_DIR}/packaging/open_browser.sh" \
    "${LIBSCRIPT_ROOT_DIR}/packaging/open_browser.cmd" \
    "${LIBSCRIPT_ROOT_DIR}/packaging/open_browser.ps1" \
    "${LIBSCRIPT_ROOT_DIR}/packaging/create_desktop_shortcuts.sh" \
    "${LIBSCRIPT_ROOT_DIR}/packaging/create_desktop_shortcuts.cmd" \
    "${LIBSCRIPT_ROOT_DIR}/packaging/create_desktop_shortcuts.ps1" \
    "${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment/guest_capture_agent.sh" \
    "${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment/guest_capture_agent.cmd" \
    "${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment/guest_capture_agent.ps1"; do
    if [ -f "$_im_hlp" ]; then
      vs_upload_guest "$_im_ws" "$_im_hlp" "${_im_guest_dir}/$(basename "$_im_hlp")"
    fi
  done

  if [ "$_im_fam" != 'windows' ]; then
    vs_exec_guest "$_im_ws" "$_im_fam" "chmod 755 '${_im_guest_dir}'/*.sh 2>/dev/null || true"
  fi
  printf '%s\n' "${_im_guest_dir}/${_im_pkg_base}"
}

# ## im_run_headless_install
# Runs a 100% unattended guest CLI installation for msi, exe, deb, rpm, pkg, or dmg packages.
im_run_headless_install() {
  _im_ws="${1:?workspace required}"
  _im_fam="${2:?os-family required}"
  _im_fmt="${3:?format required}"
  _im_gpkg="${4:?guest package path required}"
  _im_guest_dir=$(im_guest_stage_dir "$_im_fam")

  case "${_im_fam}:${_im_fmt}" in
    windows:msi)
      vs_exec_guest "$_im_ws" 'windows' "\$p = Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i', '\"${_im_gpkg}\"', '/qn', '/norestart', '/l*v', '\"${_im_guest_dir}/install_headless.log\"' -Wait -PassThru; exit \$p.ExitCode"
      ;;
    windows:exe)
      vs_exec_guest "$_im_ws" 'windows' "\$p = Start-Process -FilePath '${_im_gpkg}' -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/S' -Wait -PassThru; exit \$p.ExitCode"
      ;;
    *:deb)
      # libscript-allow-raw-pkg libscript-allow-raw-priv
      vs_exec_guest "$_im_ws" "$_im_fam" "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y '${_im_gpkg}' >'${_im_guest_dir}/install_headless.log' 2>&1 || (sudo dpkg -i '${_im_gpkg}' >>'${_im_guest_dir}/install_headless.log' 2>&1 || sudo DEBIAN_FRONTEND=noninteractive apt-get -f install -y >>'${_im_guest_dir}/install_headless.log' 2>&1)"
      ;;
    *:rpm)
      # libscript-allow-raw-pkg libscript-allow-raw-priv
      vs_exec_guest "$_im_ws" "$_im_fam" "if command -v dnf >/dev/null 2>&1; then sudo dnf install -y '${_im_gpkg}' >'${_im_guest_dir}/install_headless.log' 2>&1; else sudo rpm -Uvh '${_im_gpkg}' >'${_im_guest_dir}/install_headless.log' 2>&1; fi"
      ;;
    macos:pkg|*:pkg)
      # libscript-allow-raw-pkg libscript-allow-raw-priv
      vs_exec_guest "$_im_ws" "$_im_fam" "sudo installer -pkg '${_im_gpkg}' -target / >'${_im_guest_dir}/install_headless.log' 2>&1"
      ;;
    macos:dmg|*:dmg)
      # libscript-allow-raw-pkg libscript-allow-raw-priv
      vs_exec_guest "$_im_ws" "$_im_fam" "hdiutil attach -readonly -mountpoint /Volumes/libscript_dmg '${_im_gpkg}' && (set +f; for _ip in /Volumes/libscript_dmg/*.pkg; do [ -f \"\$_ip\" ] && sudo installer -pkg \"\$_ip\" -target /; done; for _ia in /Volumes/libscript_dmg/*.app; do [ -d \"\$_ia\" ] && sudo cp -R \"\$_ia\" /Applications/; done); hdiutil detach /Volumes/libscript_dmg"
      ;;
    *)
      printf '[ERROR] Unsupported headless install pair: %s:%s\n' "$_im_fam" "$_im_fmt" >&2
      return 1
      ;;
  esac
}

# ## im_prepare_guest_gui_session
# Prepares interactive Session 1 (Windows), X11/Wayland/Xvfb (Linux/BSD), or WindowServer (macOS) inside the guest.
im_prepare_guest_gui_session() {
  _im_ws="${1:?workspace required}"
  _im_fam="${2:?os-family required}"
  _im_guest_dir=$(im_guest_stage_dir "$_im_fam")

  case "$_im_fam" in
    windows)
      vs_exec_guest "$_im_ws" 'windows' "
        \$reg = 'HKCU:\\Software\\Policies\\Microsoft\\Windows\\Explorer';
        New-Item -Path \$reg -Force | Out-Null;
        New-ItemProperty -Path \$reg -Name 'DisableNotificationCenter' -Value 1 -PropertyType DWord -Force | Out-Null;
        \$u = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
        \$p = New-ScheduledTaskPrincipal -UserId \$u -LogonType Interactive -RunLevel Highest;
        \$s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries;
        \$a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File ${_im_guest_dir}/run_gui_step.ps1';
        Register-ScheduledTask -TaskName 'LibScriptExpGui' -Action \$a -Principal \$p -Settings \$s -Force | Out-Null
      "
      ;;
    macos)
      vs_exec_guest "$_im_ws" 'macos' 'pgrep -x WindowServer >/dev/null 2>&1 || true'
      ;;
    *)
      vs_exec_guest "$_im_ws" "$_im_fam" "
        if [ -z \"\${DISPLAY:-}\" ] && [ -z \"\${WAYLAND_DISPLAY:-}\" ]; then
          if command -v Xvfb >/dev/null 2>&1; then
            pgrep -f 'Xvfb :99' >/dev/null 2>&1 || (Xvfb :99 -screen 0 1280x800x24 >/dev/null 2>&1 &)
            sleep 1
          fi
        fi
      "
      ;;
  esac
}

# ## im_guest_click_control
# Clicks a wizard button or control inside the guest GUI session and optionally captures an installer dialog screenshot.
im_guest_click_control() {
  _im_ws="${1:?workspace required}"
  _im_fam="${2:?os-family required}"
  _im_label="${3:?button label required}"
  _im_shot="${4:-}"
  _im_guest_dir=$(im_guest_stage_dir "$_im_fam")

  if [ -n "$_im_shot" ]; then
    if [ "$_im_fam" = 'windows' ]; then
      vs_exec_guest "$_im_ws" 'windows' "
        Set-Content -Path '${_im_guest_dir}/run_gui_step.ps1' -Value \"& '${_im_guest_dir}/guest_capture_agent.ps1' -Action screen -OutFile '${_im_guest_dir}/screenshots/${_im_shot}.png' -CropMode INSTALLER\";
        Start-ScheduledTask -TaskName 'LibScriptExpGui'; Start-Sleep -Seconds 2
      " || true
    else
      vs_exec_guest "$_im_ws" "$_im_fam" "DISPLAY=\${DISPLAY:-:99} sh '${_im_guest_dir}/guest_capture_agent.sh' screen '${_im_guest_dir}/screenshots/${_im_shot}.png' INSTALLER" || true
    fi
  fi

  if [ "$_im_fam" = 'windows' ]; then
    vs_exec_guest "$_im_ws" 'windows' "
      Set-Content -Path '${_im_guest_dir}/run_gui_step.ps1' -Value \"& '${_im_guest_dir}/click_button.ps1' -ButtonText '${_im_label}'\";
      Start-ScheduledTask -TaskName 'LibScriptExpGui'; Start-Sleep -Seconds 3
    "
  elif [ "$_im_fam" = 'macos' ]; then
    vs_exec_guest "$_im_ws" 'macos' "osascript -e 'tell application \"System Events\" to tell process \"Installer\" to click button \"${_im_label}\" of window 1' 2>/dev/null || true"
  else
    vs_exec_guest "$_im_ws" "$_im_fam" "DISPLAY=\${DISPLAY:-:99} sh '${_im_guest_dir}/click_button.sh' '${_im_label}'"
  fi
}

# ## im_run_quick_install
# Drives the default GUI quick/simple installation wizard inside the guest VM.
im_run_quick_install() {
  _im_ws="${1:?workspace required}"
  _im_fam="${2:?os-family required}"
  _im_fmt="${3:?format required}"
  _im_gpkg="${4:?guest package path required}"
  _im_cap_wiz="${5:-true}"
  _im_guest_dir=$(im_guest_stage_dir "$_im_fam")

  im_prepare_guest_gui_session "$_im_ws" "$_im_fam"

  case "${_im_fam}:${_im_fmt}" in
    windows:msi|windows:exe)
      if [ "$_im_fmt" = 'msi' ]; then
        _im_launch="Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i', '\"${_im_gpkg}\"', '/l*v', '\"${_im_guest_dir}/install_quick.log\"'"
      else
        _im_launch="Start-Process -FilePath '${_im_gpkg}'"
      fi
      vs_exec_guest "$_im_ws" 'windows' "
        Set-Content -Path '${_im_guest_dir}/run_gui_step.ps1' -Value '${_im_launch}';
        Start-ScheduledTask -TaskName 'LibScriptExpGui'; Start-Sleep -Seconds 5
      "
      _im_s1=''; _im_s2=''; _im_s3=''; _im_s4=''
      if [ "$_im_cap_wiz" = 'true' ]; then
        _im_s1='01_quick_welcome'; _im_s2='02_quick_license'; _im_s3='03_quick_mode'; _im_s4='04_quick_finish'
      fi
      im_guest_click_control "$_im_ws" 'windows' 'Next' "$_im_s1"
      im_guest_click_control "$_im_ws" 'windows' 'I accept' '' || true
      im_guest_click_control "$_im_ws" 'windows' 'Next' "$_im_s2"
      im_guest_click_control "$_im_ws" 'windows' 'Next' "$_im_s3" || true
      im_guest_click_control "$_im_ws" 'windows' 'Install' ''
      vs_exec_guest "$_im_ws" 'windows' "
        \$deadline = (Get-Date).AddMinutes(15);
        while ((Get-Date) -lt \$deadline) {
          if (Select-String -Path '${_im_guest_dir}/install_quick.log' -Pattern 'Installation success or error status: 0' -Quiet -ErrorAction SilentlyContinue) { break }
          Start-Sleep -Seconds 3
        }
      " || true
      im_guest_click_control "$_im_ws" 'windows' 'Finish' "$_im_s4" || true
      ;;
    macos:pkg|macos:dmg)
      vs_exec_guest "$_im_ws" 'macos' "open '${_im_gpkg}'; sleep 3"
      im_guest_click_control "$_im_ws" 'macos' 'Continue' '01_quick_welcome'
      im_guest_click_control "$_im_ws" 'macos' 'Continue' '02_quick_license' || true
      im_guest_click_control "$_im_ws" 'macos' 'Agree' '' || true
      im_guest_click_control "$_im_ws" 'macos' 'Install' '03_quick_install'
      sleep 5
      im_guest_click_control "$_im_ws" 'macos' 'Close' '04_quick_finish' || true
      ;;
    *)
      im_run_headless_install "$_im_ws" "$_im_fam" "$_im_fmt" "$_im_gpkg"
      ;;
  esac
}

# ## im_run_custom_install
# Drives the custom/advanced GUI installation wizard path with suite custom_mode_overrides inside the guest VM.
im_run_custom_install() {
  _im_ws="${1:?workspace required}"
  _im_fam="${2:?os-family required}"
  _im_fmt="${3:?format required}"
  _im_gpkg="${4:?guest package path required}"
  _im_suite_json="${5:?suite.json required}"
  _im_cap_wiz="${6:-true}"
  _im_guest_dir=$(im_guest_stage_dir "$_im_fam")

  im_prepare_guest_gui_session "$_im_ws" "$_im_fam"

  case "${_im_fam}:${_im_fmt}" in
    windows:msi|windows:exe)
      _im_cdir=$(jq -r '.installer_e2e.install_matrix.custom_mode_overrides.install_dir_windows // "C:\\OpenEdXCustom"' "$_im_suite_json")
      if [ "$_im_fmt" = 'msi' ]; then
        _im_launch="Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i', '\"${_im_gpkg}\"', 'INSTALLFOLDER=\"${_im_cdir}\"', '/l*v', '\"${_im_guest_dir}/install_custom.log\"'"
      else
        _im_launch="Start-Process -FilePath '${_im_gpkg}' -ArgumentList '/DIR=${_im_cdir}'"
      fi
      vs_exec_guest "$_im_ws" 'windows' "
        Set-Content -Path '${_im_guest_dir}/run_gui_step.ps1' -Value '${_im_launch}';
        Start-ScheduledTask -TaskName 'LibScriptExpGui'; Start-Sleep -Seconds 5
      "
      _im_s1=''; _im_s2=''; _im_s3=''; _im_s4=''; _im_s5=''
      if [ "$_im_cap_wiz" = 'true' ]; then
        _im_s1='01_custom_welcome'; _im_s2='02_custom_license'; _im_s3='03_custom_mode'; _im_s4='04_custom_features'; _im_s5='05_custom_finish'
      fi
      im_guest_click_control "$_im_ws" 'windows' 'Next' "$_im_s1"
      im_guest_click_control "$_im_ws" 'windows' 'I accept' '' || true
      im_guest_click_control "$_im_ws" 'windows' 'Next' "$_im_s2"
      im_guest_click_control "$_im_ws" 'windows' 'Custom' "$_im_s3" || im_guest_click_control "$_im_ws" 'windows' 'Advanced' '' || true
      im_guest_click_control "$_im_ws" 'windows' 'Next' "$_im_s4" || true
      im_guest_click_control "$_im_ws" 'windows' 'Next' '' || true
      im_guest_click_control "$_im_ws" 'windows' 'Install' ''
      vs_exec_guest "$_im_ws" 'windows' "
        \$deadline = (Get-Date).AddMinutes(15);
        while ((Get-Date) -lt \$deadline) {
          if (Select-String -Path '${_im_guest_dir}/install_custom.log' -Pattern 'Installation success or error status: 0' -Quiet -ErrorAction SilentlyContinue) { break }
          Start-Sleep -Seconds 3
        }
      " || true
      im_guest_click_control "$_im_ws" 'windows' 'Finish' "$_im_s5" || true
      ;;
    *)
      im_run_headless_install "$_im_ws" "$_im_fam" "$_im_fmt" "$_im_gpkg"
      ;;
  esac
}

# ## im_execute_mode_trial
# Restores the clean `"vanilla"` snapshot, runs the requested install mode, executes Steps 3-5 guest UI verification, and collects results.
im_execute_mode_trial() {
  _im_ws="${1:?workspace required}"
  _im_prov="${2:?provider required}"
  _im_fam="${3:?os-family required}"
  _im_snap="${4:-vanilla}"
  _im_mode="${5:?mode required}"
  _im_fmt="${6:?format required}"
  _im_pkg="${7:?host package required}"
  _im_suite_json="${8:?suite.json required}"
  _im_manifest="${9:?packaging.json required}"
  _im_mode_out="${10:?mode output dir required}"

  mkdir -p "${_im_mode_out}/screenshots"
  _im_iso=$(jq -r '.installer_e2e.install_matrix.isolate_each_mode_via_snapshot // true' "$_im_suite_json")
  _im_cap_wiz=$(jq -r '.installer_e2e.install_matrix.capture_wizard_dialogs // true' "$_im_suite_json")

  if [ "$_im_iso" = 'true' ]; then
    printf '[MODE:%s] Restoring clean "%s" VM snapshot...\n' "$_im_mode" "$_im_snap" >&2
    vs_restore_vanilla_snapshot "$_im_ws" "$_im_prov" "$_im_fam" "$_im_snap" "$_im_suite_json"
  fi

  _im_gpkg=$(im_stage_package_to_guest "$_im_ws" "$_im_fam" "$_im_pkg" "$_im_manifest")
  _im_t0=$(date +%s)

  case "$_im_mode" in
    headless) im_run_headless_install "$_im_ws" "$_im_fam" "$_im_fmt" "$_im_gpkg" ;;
    quick) im_run_quick_install "$_im_ws" "$_im_fam" "$_im_fmt" "$_im_gpkg" "$_im_cap_wiz" ;;
    custom) im_run_custom_install "$_im_ws" "$_im_fam" "$_im_fmt" "$_im_gpkg" "$_im_suite_json" "$_im_cap_wiz" ;;
    *)
      printf '[ERROR] Unsupported install mode: %s\n' "$_im_mode" >&2
      return 1
      ;;
  esac

  _im_t1=$(date +%s)
  _im_dur=$((_im_t1 - _im_t0))

  guv_run_verification "$_im_ws" "$_im_fam" "$_im_suite_json" "$_im_manifest" "$_im_mode_out" "$_im_mode" "$_im_dur"
}

# ## im_cli_main
# CLI router when `install_modes.sh` is executed directly rather than sourced.
im_cli_main() {
  _im_act="${1:-}"
  shift 2>/dev/null || true
  case "$_im_act" in
    stage) im_stage_package_to_guest "$@" ;;
    headless) im_run_headless_install "$@" ;;
    quick) im_run_quick_install "$@" ;;
    custom) im_run_custom_install "$@" ;;
    run-trial) im_execute_mode_trial "$@" ;;
    --help|-h|'')
      printf '%s\n' 'Usage: install_modes.sh <stage|headless|quick|custom|run-trial> [args...]'
      ;;
    *)
      printf '[ERROR] Unknown install_modes action: %s\n' "$_im_act" >&2
      return 1
      ;;
  esac
}

if (return 0 2>/dev/null); then
  STACK="${STACK%"${THIS_FILE}":}"
  export STACK
  if [ -n "$_im_caller_this" ]; then THIS_FILE="$_im_caller_this"; fi
  if [ -n "$_im_caller_dir" ]; then SCRIPT_DIR="$_im_caller_dir"; fi
  unset _im_caller_this _im_caller_dir || true
else
  im_cli_main "$@"
fi
