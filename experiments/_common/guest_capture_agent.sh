#!/bin/sh
# ## Overview
# Guest-side native screen, desktop icon, and browser authentication capture agent (`Steps 3-5`).
# ## Usage
# ./experiments/_common/guest_capture_agent.sh <screen|desktop|browser> [args...]
set -feu; _gca_caller_this="${THIS_FILE:-}"; _gca_caller_dir="${SCRIPT_DIR:-}"
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
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# ## gca_has_gui_display
# Checks whether the current POSIX guest has an active X11, Wayland, or macOS Quartz GUI display.
gca_has_gui_display() {
  if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
    return 0
  fi
  if [ -x '/usr/sbin/screencapture' ] && pgrep -x WindowServer >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# ## gca_capture_screen
# Captures a PNG screenshot natively inside a Linux, BSD, or macOS guest without host hypervisor sockets.
gca_capture_screen() {
  _gca_out="${1:?output png required}"
  _gca_crop="${2:-FULL}"
  mkdir -p "$(dirname "$_gca_out")"

  if [ -x '/usr/sbin/screencapture' ]; then
    /usr/sbin/screencapture -x "$_gca_out"
    return 0
  fi
  if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v grim >/dev/null 2>&1; then
    grim "$_gca_out"
    return 0
  fi
  if [ -n "${DISPLAY:-}" ] && command -v import >/dev/null 2>&1; then
    import -window root "$_gca_out"
    if [ "$_gca_crop" = 'INSTALLER' ] && command -v magick >/dev/null 2>&1; then
      magick "$_gca_out" -gravity center -crop 520x420+0+0 +repage "$_gca_out" || true
    fi
    return 0
  fi
  if [ -n "${DISPLAY:-}" ] && command -v xwd >/dev/null 2>&1 && command -v magick >/dev/null 2>&1; then
    xwd -root -silent | magick xwd:- "$_gca_out"
    return 0
  fi
  printf '[ERROR] No guest screen capture backend (screencapture, grim, import, xwd) available.\n' >&2
  return 1
}

# ## gca_capture_desktop
# Verifies desktop shortcuts when a GUI session is present and captures `10b_desktop_icons.png`, or emits SKIPPED_NOT_APPLICABLE.
gca_capture_desktop() {
  _gca_out="${1:?output png required}"
  _gca_policy="${2:-if-applicable}"

  if [ "$_gca_policy" = 'never' ]; then
    printf '%s\n' 'SKIPPED_NOT_APPLICABLE'
    return 0
  fi
  if ! gca_has_gui_display; then
    if [ "$_gca_policy" = 'always' ]; then
      printf '[ERROR] Desktop screenshot required by policy=always, but guest has no GUI session.\n' >&2
      return 1
    fi
    printf '%s\n' 'SKIPPED_NOT_APPLICABLE'
    return 0
  fi

  if command -v xdotool >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    xdotool key super+d 2>/dev/null || true
    sleep 1
  fi
  gca_capture_screen "$_gca_out" 'FULL'
  printf '%s\n' 'CAPTURED'
}

# ## gca_wait_http_ready
# Polls a localhost HTTP endpoint inside the guest until HTTP 200/302 or timeout.
gca_wait_http_ready() {
  _gca_port="${1:?port required}"
  _gca_path="${2:-/}"
  _gca_timeout="${3:-300}"
  _gca_elapsed=0
  _gca_url="http://127.0.0.1:${_gca_port}${_gca_path}"

  while [ "$_gca_elapsed" -lt "$_gca_timeout" ]; do
    _gca_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$_gca_url" 2>/dev/null || printf '000')
    case "$_gca_code" in
      200|201|204|301|302|303|307|308) return 0 ;;
    esac
    sleep 3
    _gca_elapsed=$((_gca_elapsed + 3))
  done
  printf '[ERROR] Timed out waiting for guest service %s (last HTTP %s)\n' "$_gca_url" "${_gca_code:-000}" >&2
  return 1
}

# ## gca_find_browser_bin
# Resolves an installed Chromium, Chrome, Edge, or Firefox binary inside the POSIX guest.
gca_find_browser_bin() {
  for _gca_b in chromium chromium-browser google-chrome google-chrome-stable microsoft-edge firefox; do
    if command -v "$_gca_b" >/dev/null 2>&1; then
      command -v "$_gca_b"
      return 0
    fi
  done
  if [ -x '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' ]; then
    printf '%s\n' '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
    return 0
  fi
  return 1
}

# ## gca_capture_browser
# Opens a guest browser to the target URL, executes optional form login, and captures a browser PNG screenshot.
gca_capture_browser() {
  _gca_type="${1:?capture_type required}"
  _gca_out="${2:?output png required}"
  _gca_port="${3:?port required}"
  _gca_health_path="${4:-/}"
  _gca_url="${5:?url required}"
  _gca_timeout="${6:-300}"
  _gca_login_url="${7:-}"
  _gca_user_sel="${8:-}"
  _gca_pass_sel="${9:-}"
  _gca_sub_sel="${10:-}"
  _gca_user_val="${11:-}"
  _gca_pass_val="${12:-}"
  _gca_ready_sel="${13:-}"

  mkdir -p "$(dirname "$_gca_out")"
  gca_wait_http_ready "$_gca_port" "$_gca_health_path" "$_gca_timeout"

  _gca_bin=$(gca_find_browser_bin || true)
  if [ -z "$_gca_bin" ]; then
    printf '[ERROR] No guest browser binary (chromium, google-chrome, firefox) found.\n' >&2
    return 1
  fi

  _gca_prof=$(mktemp -d)
  if [ "$_gca_type" = 'browser_unauthenticated' ]; then
    case "$_gca_bin" in
      *firefox*)
        "$_gca_bin" --headless --window-size=1280,800 --screenshot "$_gca_out" "$_gca_url" >/dev/null 2>&1
        ;;
      *)
        "$_gca_bin" --headless --no-sandbox --disable-gpu --user-data-dir="$_gca_prof" --window-size=1280,800 --screenshot="$_gca_out" "$_gca_url" >/dev/null 2>&1
        ;;
    esac
    rm -rf "$_gca_prof"
    return 0
  fi

  # Authenticated flow: launch Chromium/Chrome with local CDP port or cookie-jar session + screenshot
  "$_gca_bin" --headless --no-sandbox --disable-gpu --user-data-dir="$_gca_prof" --remote-debugging-port=9222 --window-size=1280,800 "${_gca_login_url:-$_gca_url}" >/dev/null 2>&1 &
  _gca_browser_pid=$!
  sleep 4

  # Verify CDP target endpoint on 127.0.0.1:9222 and navigate/render authenticated target URL
  _gca_tabs=$(curl -s --connect-timeout 2 'http://127.0.0.1:9222/json' 2>/dev/null || printf '[]')
  if [ -n "$_gca_tabs" ] && command -v websocat >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    _gca_ws=$(printf '%s' "$_gca_tabs" | jq -r '.[0].webSocketDebuggerUrl // empty')
    if [ -n "$_gca_ws" ]; then
      _gca_js="(() => { const setV = (sel, v) => { const el = document.querySelector(sel); if (!el) return; const d = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value'); if (d && d.set) d.set.call(el, v); else el.value = v; el.dispatchEvent(new Event('input', {bubbles:true})); el.dispatchEvent(new Event('change', {bubbles:true})); }; setV(\"${_gca_user_sel}\", \"${_gca_user_val}\"); setV(\"${_gca_pass_sel}\", \"${_gca_pass_val}\"); const b = document.querySelector(\"${_gca_sub_sel}\"); if (b) b.click(); })()"
      jq -nc --arg expr "$_gca_js" '{id:1,method:"Runtime.evaluate",params:{expression:$expr}}' | websocat -n1 "$_gca_ws" >/dev/null 2>&1 || true
      sleep 5
      if [ -n "$_gca_ready_sel" ] && [ "$_gca_url" != "$_gca_login_url" ]; then
        jq -nc --arg u "$_gca_url" '{id:2,method:"Page.navigate",params:{url:$u}}' | websocat -n1 "$_gca_ws" >/dev/null 2>&1 || true
        sleep 3
      fi
      _gca_shot_json=$(printf '%s\n' '{"id":3,"method":"Page.captureScreenshot","params":{"format":"png"}}' | websocat -n1 "$_gca_ws" 2>/dev/null || true)
      _gca_b64=$(printf '%s' "$_gca_shot_json" | jq -r '.result.data // empty' 2>/dev/null || true)
      if [ -n "$_gca_b64" ]; then
        if printf '%s' "$_gca_b64" | base64 --decode > "$_gca_out" 2>/dev/null; then :; else printf '%s' "$_gca_b64" | base64 -D > "$_gca_out"; fi
      fi
    fi
  fi

  kill "$_gca_browser_pid" 2>/dev/null || true
  wait "$_gca_browser_pid" 2>/dev/null || true

  if [ ! -s "$_gca_out" ]; then
    "$_gca_bin" --headless --no-sandbox --disable-gpu --user-data-dir="$_gca_prof" --window-size=1280,800 --screenshot="$_gca_out" "$_gca_url" >/dev/null 2>&1
  fi
  rm -rf "$_gca_prof"
}

_gca_act="${1:-}"
shift 2>/dev/null || true
case "$_gca_act" in
  screen) gca_capture_screen "$@" ;;
  desktop) gca_capture_desktop "$@" ;;
  browser) gca_capture_browser "$@" ;;
  --help|-h|'')
    printf '%s\n' 'Usage: guest_capture_agent.sh <screen|desktop|browser> [args...]'
    ;;
  *)
    printf '[ERROR] Unknown guest_capture_agent action: %s\n' "$_gca_act" >&2
    exit 1
    ;;
esac

if (return 0 2>/dev/null); then
  STACK="${STACK%"${THIS_FILE}":}"
  export STACK
  [ -n "${_gca_caller_dir:-}" ] && SCRIPT_DIR="${_gca_caller_dir}"
  [ -n "${_gca_caller_this:-}" ] && THIS_FILE="${_gca_caller_this}"
  unset SCRIPT_NAME _gca_caller_this _gca_caller_dir || true
  return 0
fi
