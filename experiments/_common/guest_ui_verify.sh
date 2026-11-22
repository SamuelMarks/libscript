#!/bin/sh
# ## Overview
# Host-side coordinator (`Steps 3-5`) executing desktop shortcut and multi-endpoint browser login verification inside the guest VM.
# ## Usage
# ./experiments/_common/guest_ui_verify.sh <plan|verify> [args...]
set -feu
_guv_caller_this="${THIS_FILE:-}"; _guv_caller_dir="${SCRIPT_DIR:-}"
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
    if [ -n "$_guv_caller_this" ]; then THIS_FILE="$_guv_caller_this"; fi; if [ -n "$_guv_caller_dir" ]; then SCRIPT_DIR="$_guv_caller_dir"; fi
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/experiments/_common/vagrant_substrate.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "$SCRIPT_NAME"
unset SCRIPT_NAME || true

# ## guv_build_ordered_plan
# Orders verification_screenshots from packaging.json so desktop icons run first, followed by per-service-port (open -> screenshot -> login -> screenshot).
guv_build_ordered_plan() {
  _guv_suite_json="${1:?suite.json required}"
  _guv_manifest="${2:?packaging.json required}"

  jq -n \
    --slurpfile suite "$_guv_suite_json" \
    --slurpfile pkg "$_guv_manifest" '
      ($suite[0].installer_e2e.verification // {}) as $ver
      | (if ($ver.inherit_packaging_verification_screenshots // true) then ($pkg[0].verification_screenshots // []) else [] end)
        + ($ver.extra_verification_steps // [])
      | . as $all
      | [ $all[] | select(.capture_type == "desktop") ] as $desktop
      | ([ $all[] | select(.capture_type != "desktop") | .service_port ] | unique_by(.) ) as $_unused
      | (reduce ($all[] | select(.capture_type != "desktop")) as $item ([]; if (index($item.service_port) == null) then . + [$item.service_port] else . end)) as $ports
      | $desktop + [
          $ports[] as $p
          | ($all[] | select(.service_port == $p and .capture_type == "browser_unauthenticated")),
            ($all[] | select(.service_port == $p and .capture_type == "browser_authenticated"))
        ]
    '
}

# ## guv_verify_png_magic
# Verifies that a downloaded screenshot file is non-empty and begins with the 8-byte PNG signature (`89504e47`).
guv_verify_png_magic() {
  _guv_png="${1:?png path required}"
  if [ ! -s "$_guv_png" ]; then
    return 1
  fi
  _guv_hex=$(od -An -tx1 -N4 "$_guv_png" 2>/dev/null | tr -d ' \n\r\t')
  [ "$_guv_hex" = '89504e47' ] || [ "$_guv_hex" = '89504E47' ]
}

# ## guv_run_verification
# Executes all ordered desktop and browser verification steps inside the guest VM and downloads screenshots + result.json.
guv_run_verification() {
  _guv_ws="${1:?workspace required}"
  _guv_fam="${2:?os-family required}"
  _guv_suite_json="${3:?suite.json required}"
  _guv_manifest="${4:?packaging.json required}"
  _guv_mode_out="${5:?mode output dir required}"
  _guv_mode="${6:-headless}"
  _guv_inst_dur="${7:-0}"

  mkdir -p "${_guv_mode_out}/screenshots"
  _guv_desk_pol=$(jq -r '.installer_e2e.verification.capture_desktop_icons // "if-applicable"' "$_guv_suite_json")
  _guv_timeout=$(jq -r '.installer_e2e.verification.service_ready_timeout_sec // 300' "$_guv_suite_json")
  _guv_plan=$(guv_build_ordered_plan "$_guv_suite_json" "$_guv_manifest")
  _guv_guest_dir='/tmp/libscript_exp'
  if [ "$_guv_fam" = 'windows' ]; then
    _guv_guest_dir='C:/libscript_exp'
  fi

  _guv_steps_tmp="${_guv_mode_out}/.steps.jsonl"
  : > "$_guv_steps_tmp"

  _guv_count=$(printf '%s' "$_guv_plan" | jq 'length')
  _guv_idx=0
  while [ "$_guv_idx" -lt "$_guv_count" ]; do
    _guv_step=$(printf '%s' "$_guv_plan" | jq -c ".[${_guv_idx}]")
    _guv_id=$(printf '%s' "$_guv_step" | jq -r '.id')
    _guv_ctype=$(printf '%s' "$_guv_step" | jq -r '.capture_type')
    _guv_remote_png="${_guv_guest_dir}/screenshots/${_guv_id}.png"
    _guv_local_png="${_guv_mode_out}/screenshots/${_guv_id}.png"
    _guv_st0=$(date +%s)
    _guv_status='passed'

    if [ "$_guv_ctype" = 'desktop' ]; then
      if [ "$_guv_fam" = 'windows' ]; then
        vs_exec_guest "$_guv_ws" 'windows' "
          Set-Content -Path '${_guv_guest_dir}/run_gui_step.ps1' -Value \"& '${_guv_guest_dir}/guest_capture_agent.ps1' -Action desktop -OutFile '${_guv_remote_png}' -DesktopPolicy '${_guv_desk_pol}'\";
          Start-ScheduledTask -TaskName 'LibScriptExpGui'; Start-Sleep -Seconds 5
        "
        vs_download_guest "$_guv_ws" 'windows' "$_guv_remote_png" "$_guv_local_png"
      else
        _guv_desk_out=$(vs_exec_guest "$_guv_ws" "$_guv_fam" "sh '${_guv_guest_dir}/guest_capture_agent.sh' desktop '${_guv_remote_png}' '${_guv_desk_pol}'" | tr -d '\r')
        case "$_guv_desk_out" in
          *SKIPPED_NOT_APPLICABLE*)
            _guv_status='skipped_not_applicable'
            ;;
          *)
            vs_download_guest "$_guv_ws" "$_guv_fam" "$_guv_remote_png" "$_guv_local_png"
            ;;
        esac
      fi
    else
      _guv_port=$(printf '%s' "$_guv_step" | jq -r '.service_port // 80')
      _guv_health_path=$(printf '%s' "$_guv_step" | jq -r '.healthcheck_path // "/"')
      _guv_url=$(printf '%s' "$_guv_step" | jq -r '.url_template // "http://localhost/"')
      _guv_login_url=$(printf '%s' "$_guv_step" | jq -r '.auth_flow.login_url // empty')
      _guv_user_sel=$(printf '%s' "$_guv_step" | jq -r '.auth_flow.username_selector // empty')
      _guv_pass_sel=$(printf '%s' "$_guv_step" | jq -r '.auth_flow.password_selector // empty')
      _guv_submit_sel=$(printf '%s' "$_guv_step" | jq -r '.auth_flow.submit_selector // empty')
      _guv_uval=$(printf '%s' "$_guv_step" | jq -r '.auth_flow.username_value // empty')
      _guv_pass_val=$(printf '%s' "$_guv_step" | jq -r '.auth_flow.password_value // empty')
      _guv_ready_sel=$(printf '%s' "$_guv_step" | jq -r '.auth_flow.ready_selector // empty')

      if [ "$_guv_fam" = 'windows' ]; then
        vs_exec_guest "$_guv_ws" 'windows' "
          Set-Content -Path '${_guv_guest_dir}/run_gui_step.ps1' -Value \"& '${_guv_guest_dir}/guest_capture_agent.ps1' -Action browser -CaptureType '${_guv_ctype}' -OutFile '${_guv_remote_png}' -ServicePort ${_guv_port} -HealthPath '${_guv_health_path}' -Url '${_guv_url}' -TimeoutSec ${_guv_timeout} -LoginUrl '${_guv_login_url}' -UsernameSelector \`\"${_guv_user_sel}\`\" -PasswordSelector \`\"${_guv_pass_sel}\`\" -SubmitSelector \`\"${_guv_submit_sel}\`\" -UsernameValue '${_guv_uval}' -PasswordValue '${_guv_pass_val}' -ReadySelector \`\"${_guv_ready_sel}\`\"\";
          Start-ScheduledTask -TaskName 'LibScriptExpGui';
          \$dl = (Get-Date).AddSeconds(${_guv_timeout});
          while (((Get-Date) -lt \$dl) -and (-not (Test-Path '${_guv_remote_png}'))) { Start-Sleep -Seconds 3 }
        "
      else
        vs_exec_guest "$_guv_ws" "$_guv_fam" "sh '${_guv_guest_dir}/guest_capture_agent.sh' browser '${_guv_ctype}' '${_guv_remote_png}' '${_guv_port}' '${_guv_health_path}' '${_guv_url}' '${_guv_timeout}' '${_guv_login_url}' \"${_guv_user_sel}\" \"${_guv_pass_sel}\" \"${_guv_submit_sel}\" '${_guv_uval}' '${_guv_pass_val}' \"${_guv_ready_sel}\""
      fi
      vs_download_guest "$_guv_ws" "$_guv_fam" "$_guv_remote_png" "$_guv_local_png"
    fi

    if [ "$_guv_status" = 'passed' ] && ! guv_verify_png_magic "$_guv_local_png"; then
      printf '[ERROR] Verification screenshot %s is missing or invalid PNG: %s\n' "$_guv_id" "$_guv_local_png" >&2
      return 1
    fi

    _guv_st1=$(date +%s)
    _guv_lat=$((_guv_st1 - _guv_st0))
    jq -nc \
      --arg id "$_guv_id" \
      --arg ctype "$_guv_ctype" \
      --arg st "$_guv_status" \
      --arg png "screenshots/${_guv_id}.png" \
      --argjson sec "$_guv_lat" \
      '{id:$id,capture_type:$ctype,status:$st,screenshot:$png,duration_sec:$sec}' >> "$_guv_steps_tmp"

    _guv_idx=$((_guv_idx + 1))
  done

  jq -s \
    --arg mode "$_guv_mode" \
    --argjson dur "$_guv_inst_dur" \
    '{install_mode:$mode,status:"passed",install_duration_sec:$dur,verification_steps:.}' \
    "$_guv_steps_tmp" > "${_guv_mode_out}/result.json"
  rm -f "$_guv_steps_tmp"
}

# ## guv_cli_main
# CLI router when `guest_ui_verify.sh` is executed directly rather than sourced.
guv_cli_main() {
  _guv_act="${1:-}"
  shift 2>/dev/null || true
  case "$_guv_act" in
    plan) guv_build_ordered_plan "$@" ;;
    verify) guv_run_verification "$@" ;;
    --help|-h|'')
      printf '%s\n' 'Usage: guest_ui_verify.sh <plan|verify> [args...]'
      ;;
    *)
      printf '[ERROR] Unknown guest_ui_verify action: %s\n' "$_guv_act" >&2
      return 1
      ;;
  esac
}

if (return 0 2>/dev/null); then
  STACK="${STACK%"${THIS_FILE}":}"
  export STACK
  if [ -n "$_guv_caller_this" ]; then THIS_FILE="$_guv_caller_this"; fi
  if [ -n "$_guv_caller_dir" ]; then SCRIPT_DIR="$_guv_caller_dir"; fi
  unset _guv_caller_this _guv_caller_dir || true
else
  guv_cli_main "$@"
fi
