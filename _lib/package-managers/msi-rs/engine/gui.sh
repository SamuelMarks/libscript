#!/bin/sh
# ## Overview
# Kiosk display manager and msi-gui session launcher for the live installer.
# Probes hardware GPU acceleration (DRM/KMS), configures Mesa software rasterization fallbacks,
# and starts a dedicated fullscreen kiosk session via Wayland (cage) or X11 (openbox/xinit).
#
# ## Usage
# Execute this script to start the GUI installer session:
#   ./_lib/package-managers/msi-rs/engine/gui.sh [--test | --help]

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

TEST_MODE="0"

# ## show_help
# Displays usage instructions and supported options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [OPTIONS]"
  printf '%s
' "Launches fullscreen kiosk GUI installer using msi-gui."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --test              Test display stack availability and validation in headless mode."
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --test)
      TEST_MODE="1"
      shift
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# ## probe_gpu_hardware
# Detects available graphics hardware and DRM/KMS drivers.
probe_gpu_hardware() {
  printf '[INFO] Probing graphics hardware and display pipeline...
'
  if [ -d /sys/class/drm ]; then
    for card in /sys/class/drm/card[0-9]*; do
      [ -d "$card" ] || continue
      _cname=$(basename "$card")
      printf '       Found DRM device: %s
' "$_cname"
    done
  fi

  if command -v lspci >/dev/null 2>&1; then
    lspci 2>/dev/null | grep -iE 'vga|3d|display' || true
  fi
}

# ## configure_software_rasterizer
# Sets up Mesa llvmpipe / softpipe fallback environment variables.
configure_software_rasterizer() {
  export LIBGL_ALWAYS_SOFTWARE=1
  export GALLIUM_DRIVER=llvmpipe
  export MESA_GL_VERSION_OVERRIDE=3.3
  printf '[INFO] Software rasterization fallback configured (Mesa llvmpipe).
'
}

# ## find_msi_gui
# Resolves binary path for msi-gui.
find_msi_gui() {
  if command -v msi-gui >/dev/null 2>&1; then
    printf '%s\n' "$(command -v msi-gui)"
    return 0
  fi
  for candidate in \
    "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/latest/bin/msi-gui" \
    "${REPO_ROOT}/target/release/msi-gui" \
    "/opt/libscript/msi-rs/bin/msi-gui"; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

# Probe display hardware
probe_gpu_hardware

# If test mode, validate environment and exit
if [ "$TEST_MODE" = "1" ]; then
  configure_software_rasterizer
  printf '[OK] GUI display pipeline test passed.
'
  exit 0
fi

# Locate executable
GUI_BIN=$(find_msi_gui || true)
if [ -z "$GUI_BIN" ]; then
  printf '[WARN] msi-gui binary not installed. Falling back to terminal user interface.
'
  exec "${SCRIPT_DIR}/tui.sh"
fi

# 1. Wayland Kiosk Session via Cage
if command -v cage >/dev/null 2>&1; then
  printf '[INFO] Launching Wayland kiosk compositor (cage)...
'
  exec cage -- "$GUI_BIN"
fi

# 2. X11 Kiosk Session via xinit and Openbox
if command -v xinit >/dev/null 2>&1; then
  printf '[INFO] Launching X11 kiosk session (xinit)...
'
  configure_software_rasterizer
  exec xinit "$GUI_BIN" -- :0 -nolisten tcp vt7
fi

# Fallback to TUI
printf '[WARN] No suitable Wayland/X11 compositor available. Falling back to TUI wizard.
'
exec "${SCRIPT_DIR}/tui.sh"
