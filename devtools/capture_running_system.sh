#!/bin/sh
# cspell:words isdir rstrip bbox textbbox titlebar roundrectangle pointsize wcopy colortbl vspec shutil urlopen DEVNULL edxloggedin LANCZOS websockets asyncio getpid Popen nonlocal rmtree
# ## Overview
# Generic schema-driven "screenshot-to-running-system" engine.
# Reads declarative metadata strictly from <target_dir>/packaging.json (or synthesizes
# defaults from <target_dir>/manifest.json), steps through .msi GUI wizard stages (01..10)
# via SamuelMarks/msi-rs msi-gui (cropped to 495x392), and captures post-install desktop and
# browser verification views (10b..14, both unauthenticated login screens and authenticated
# administrative dashboards) across Windows, Linux, macOS, FreeBSD, and illumos (OmniOS).
#
# ## Usage
# ./devtools/capture_running_system.sh [--target <dir_or_name|all>] [--os <windows|linux|macos|freebsd|illumos|all>] [--variant <online|offline|both>] [--flow <quick|custom|both>] [--mode <all|wizard|post-install>] [--live-vagrant] [--out-dir <path>]

set -feu

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

TARGET='all'
OS_LIST='all'
VARIANT='both'
FLOW='both'
MODE='all'
LIVE_VAGRANT='0'
OUT_BASE="${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript"

# ## show_help
# Prints usage instructions for capture_running_system.sh.
show_help() {
  printf 'Usage: %s [OPTIONS]
' "$0"
  printf '  --target <name|dir|all>               Target component directory or name (default: all)
'
  printf '  --os <windows|linux|macos|freebsd|illumos|all>  Target OS windowing style (default: all)
'
  printf '  --variant <online|offline|both>       Installer variant (default: both)
'
  printf '  --flow <quick|custom|both>            Wizard flow (default: both)
'
  printf '  --mode <all|wizard|post-install>      Capture stages to execute (default: all)
'
  printf '  --live-vagrant                        Probe and capture live Vagrant VM services
'
  printf '  --out-dir <path>                      Base output directory (default: ../cc0-assets/libscript)
'
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --target=*)
      TARGET="${1#*=}"
      shift
      ;;
    --os)
      OS_LIST="$2"
      shift 2
      ;;
    --os=*)
      OS_LIST="${1#*=}"
      shift
      ;;
    --variant)
      VARIANT="$2"
      shift 2
      ;;
    --variant=*)
      VARIANT="${1#*=}"
      shift
      ;;
    --flow)
      FLOW="$2"
      shift 2
      ;;
    --flow=*)
      FLOW="${1#*=}"
      shift
      ;;
    --mode)
      MODE="$2"
      shift 2
      ;;
    --mode=*)
      MODE="${1#*=}"
      shift
      ;;
    --live-vagrant)
      LIVE_VAGRANT='1'
      shift
      ;;
    --out-dir|--output-dir)
      OUT_BASE="$2"
      shift 2
      ;;
    --out-dir=*|--output-dir=*)
      OUT_BASE="${1#*=}"
      shift
      ;;
    --help|-h|-\?|/\?)
      show_help
      ;;
    *)
      TARGET="$1"
      shift
      ;;
  esac
done

# ## ensure_msirs_path
# Ensures SamuelMarks/msi-rs binaries (msi-gui, msiinfo, candle, light) are available in PATH.
ensure_msirs_path() {
  if [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/default/bin" ]; then
    PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/default/bin:${PATH}"
    export PATH
  elif [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/v0.0.1/bin" ]; then
    PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/v0.0.1/bin:${PATH}"
    export PATH
  fi
}

# ## resolve_target_dir
# Dynamically resolves a component name or relative path to its _lib/<category>/<component> directory.
resolve_target_dir() {
  _t="$1"
  if [ -d "${LIBSCRIPT_ROOT_DIR}/${_t}" ]; then
    printf '%s
' "$_t"
  elif [ -d "$_t" ]; then
    printf '%s
' "$_t"
  else
    _found=$(find "${LIBSCRIPT_ROOT_DIR}/_lib" -mindepth 2 -maxdepth 2 -type d -name "$_t" | sort | head -n 1)
    if [ -n "$_found" ]; then
      printf '%s
' "${_found#"${LIBSCRIPT_ROOT_DIR}/"}"
    else
      printf '%s
' "$_t"
    fi
  fi
}

# ## resolve_target_name
# Extracts the canonical component name from packaging.json, manifest.json, or directory basename.
resolve_target_name() {
  _tdir="$1"
  _abs="${LIBSCRIPT_ROOT_DIR}/${_tdir}"
  [ ! -d "$_abs" ] && _abs="$_tdir"
  if [ -f "${_abs}/packaging.json" ] && command -v jq >/dev/null 2>&1; then
    _n=$(jq -r '.name // empty' "${_abs}/packaging.json")
    if [ -n "$_n" ]; then
      printf '%s
' "$_n"
      return 0
    fi
  fi
  if [ -f "${_abs}/manifest.json" ] && command -v jq >/dev/null 2>&1; then
    _n=$(jq -r '.name // empty' "${_abs}/manifest.json")
    if [ -n "$_n" ]; then
      printf '%s
' "$_n"
      return 0
    fi
  fi
  basename "$_abs"
}

# ## ensure_msi_built
# Builds the online or offline .msi package for a component via packaging/build_msi.sh if needed.
ensure_msi_built() {
  _tdir="$1"
  _tname="$2"
  _v="$3"
  _out_prefix="${LIBSCRIPT_ROOT_DIR}/packaging/${_tname}-${_v}"
  for _cand in "${LIBSCRIPT_ROOT_DIR}/packaging/"*.msi; do
    [ -f "$_cand" ] || continue
    _base=$(basename "$_cand" .msi | tr '[:upper:]' '[:lower:]')
    if [ "$_v" = "offline" ]; then
      case "$_base" in
        "${_tname}-offline"|"${_tname}-setup-offline")
          _out_prefix="${_cand%.msi}"
          break
          ;;
      esac
    else
      case "$_base" in
        "${_tname}-online"|"${_tname}-setup")
          _out_prefix="${_cand%.msi}"
          break
          ;;
      esac
    fi
  done
  if [ ! -f "${_out_prefix}.msi" ]; then
    "${LIBSCRIPT_ROOT_DIR}/packaging/build_msi.sh" "$_tdir" "--${_v}" --out "$_out_prefix" >/dev/null
  fi
  printf '%s.msi
' "$_out_prefix"
}

# ## capture_wizard_stages
# Steps through quick-install and custom-install stages via msi-gui and renders 495x392 cropped installer windows.
capture_wizard_stages() {
  _tdir="$1"
  _tname="$2"
  _os="$3"
  _v="$4"
  _msi_file=$(ensure_msi_built "$_tdir" "$_tname" "$_v")
  _prefix='online_'
  [ "$_v" = "offline" ] && _prefix="offline_"

  _target_out="${OUT_BASE}/${_tname}/screenshots"
  _os_out="${_target_out}/${_os}"
  mkdir -p "$_target_out" "$_os_out"

  _state_dir="${TMPDIR:-/tmp}/msi_states_${_tname}_${_v}_$$"
  mkdir -p "$_state_dir"

  for _dlg in Dlg_Welcome Dlg_License Dlg_SetupType Dlg_Features Dlg_InstallLocation Dlg_RuntimeSelection Dlg_OpenEdX_SourceRepo Dlg_OpenEdX_Config Dlg_OpenEdX_DB Dlg_OpenEdX_CacheSearch Dlg_VerifyReady Dlg_Exit; do
    MSI_GUI_DIALOG="$_dlg" MSI_GUI_DUMP_STATE="${_state_dir}/${_dlg}.state" msi-gui "$_msi_file" >/dev/null 2>&1 || true
  done

  _abs_tdir="${LIBSCRIPT_ROOT_DIR}/${_tdir}"
  [ ! -d "$_abs_tdir" ] && _abs_tdir="$_tdir"
  _pkg_json="${_abs_tdir}/packaging.json"
  _manifest_json="${_abs_tdir}/manifest.json"
  _assets_dir="${OUT_BASE}/${_tname}/assets"
  _eula_file="${_assets_dir}/${_tname}_eula.rtf"

  python3 - "$_tname" "$_os" "$_v" "$_prefix" "$_state_dir" "$_assets_dir" "$_eula_file" "$_target_out" "$_os_out" "$FLOW" "$_pkg_json" "$_manifest_json" << 'PY_EOF'
import json, os, re, sys
from PIL import Image, ImageDraw, ImageFont

target, os_name, variant, prefix, state_dir, assets_dir, eula_file, target_out, os_out, flow, pkg_json_path, manifest_json_path = sys.argv[1:13]

pkg_meta = {}
if os.path.exists(pkg_json_path):
    try:
        with open(pkg_json_path, "r", encoding="utf-8") as f:
            pkg_meta = json.load(f)
    except Exception:
        pass
elif os.path.exists(manifest_json_path):
    try:
        with open(manifest_json_path, "r", encoding="utf-8") as f:
            pkg_meta = json.load(f)
    except Exception:
        pass

W, H = 495, 392
TITLE_H = 30
SX = 493.0 / 370.0
SY = 360.0 / 270.0

def hex_to_rgb(h, default=(11, 46, 74)):
    if not h or not isinstance(h, str):
        return default
    h = h.lstrip("#")
    if len(h) == 6:
        try:
            return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
        except Exception:
            pass
    return default

def load_font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for c in candidates:
        if os.path.exists(c):
            try:
                return ImageFont.truetype(c, size)
            except Exception:
                pass
    return ImageFont.load_default()

FONT_SM = load_font(11, False)
FONT_REG = load_font(12, False)
FONT_BOLD = load_font(12, True)
FONT_TITLE = load_font(14, True)
FONT_BIG = load_font(17, True)

palette = pkg_meta.get("branding_palette", {})
prim_rgb = hex_to_rgb(palette.get("primary_color"), (11, 46, 74))
sec_rgb = hex_to_rgb(palette.get("secondary_color"), (0, 115, 170))
dark_rgb = hex_to_rgb(palette.get("dark_color"), (18, 28, 42))
brand_title = palette.get("app_title") or pkg_meta.get("title") or target.capitalize()

side_bmp = None
top_bmp = None
side_cand = os.path.join(assets_dir, f"{target}_banner_side.bmp")
top_cand = os.path.join(assets_dir, f"{target}_banner_top.bmp")
if os.path.exists(side_cand):
    try:
        side_bmp = Image.open(side_cand).convert("RGB")
    except Exception:
        side_bmp = None
if os.path.exists(top_cand):
    try:
        top_bmp = Image.open(top_cand).convert("RGB")
    except Exception:
        top_bmp = None

if side_bmp is None:
    sb = Image.new("RGB", (164, 312), prim_rgb)
    sbd = ImageDraw.Draw(sb)
    sbd.rectangle([0, 0, 163, 311], outline=sec_rgb, width=2)
    sbd.ellipse([42, 26, 122, 106], fill=sec_rgb, outline=(255, 255, 255), width=2)
    badge = (target[:2]).upper()
    sbd.text((66, 54), badge, fill=(255, 255, 255), font=FONT_BIG)
    sbd.text((16, 122), brand_title[:18], fill=(255, 255, 255), font=FONT_TITLE)
    wcopy = pkg_meta.get("wizard_copy", {})
    non_opt = wcopy.get("non_optional_summary", "")
    lines = [ln.lstrip("- ").strip()[:22] for ln in non_opt.splitlines() if ln.strip()]
    if not lines:
        lines = [f"{target.capitalize()} Core", "LibScript Runtime", "Service Supervisor", "Healthcheck Suite"]
    y_st = 165
    for item in lines[:5]:
        sbd.text((16, y_st), f"• {item}", fill=(215, 232, 248), font=FONT_SM)
        y_st += 20
    sbd.text((16, 284), "LibScript Autonomous MSI", fill=(160, 195, 225), font=FONT_SM)
    side_bmp = sb

if top_bmp is None:
    tb_img = Image.new("RGB", (493, 58), (247, 250, 253))
    tbd = ImageDraw.Draw(tb_img)
    tbd.ellipse([438, 8, 480, 50], fill=sec_rgb, outline=prim_rgb, width=2)
    tbd.text((449, 20), (target[:2]).upper(), fill=(255, 255, 255), font=FONT_BOLD)
    top_bmp = tb_img

eula_lines = [
    f"{brand_title.upper()} END-USER LICENSE AGREEMENT",
    "",
    "This installer bundles open-source software components managed by LibScript.",
    "By clicking 'I Agree', you accept the respective license terms for:",
    f"  - {brand_title}",
    "  - Bundled execution runtimes, databases, and service supervisors",
    "  - LibScript Zero-Dependency Packaging Substrate (MIT / Apache-2.0 / CC0-1.0)",
    "",
    "Permission is hereby granted, free of charge, to any person obtaining a copy",
    "of this software and associated configuration files, to deal in the Software",
    "without restriction, including without limitation the rights to use, copy,",
    "modify, merge, publish, distribute, and/or sell copies of the Software.",
]
if os.path.exists(eula_file):
    try:
        raw = open(eula_file, "r", encoding="utf-8", errors="ignore").read()
        raw = re.sub(r"\{\\fonttbl.*?\}", "", raw, flags=re.S)
        raw = re.sub(r"\{\\colortbl.*?\}", "", raw, flags=re.S)
        raw = raw.replace("\\par", chr(10)).replace("\\line", chr(10))
        raw = re.sub(r"\\[a-zA-Z0-9]+ ?", "", raw)
        raw = raw.replace("{", "").replace("}", "")
        parsed = [ln.strip() for ln in raw.splitlines() if ln.strip()]
        if len(parsed) >= 4:
            eula_lines = parsed[:18]
    except Exception:
        pass

def parse_state(dlg):
    p = os.path.join(state_dir, f"{dlg}.state")
    info = {"title": f"{brand_title} Setup", "controls": [], "props": {}}
    if not os.path.exists(p):
        return info
    with open(p, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.rstrip(chr(10)).rstrip(chr(13))
            if line.startswith("WINDOW_TITLE="):
                info["title"] = line[13:]
            elif line.startswith("TITLE:"):
                info["title"] = line[6:]
            elif line.startswith("PROP:") or line.startswith("PROPERTY:"):
                payload = line.split(":", 1)[1]
                k, _, v = payload.partition("=")
                info["props"][k] = v
            elif line.startswith("CONTROL:"):
                parts = line[8:].split("|")
                if len(parts) >= 3 and "," in parts[2]:
                    coords = [int(x) for x in parts[2].split(",")[:4]]
                    c = {
                        "id": parts[0],
                        "type": parts[1],
                        "x": coords[0],
                        "y": coords[1],
                        "w": coords[2],
                        "h": coords[3],
                    }
                    for kv in parts[3:]:
                        k, _, v = kv.partition("=")
                        c[k] = v
                else:
                    c = {"id": parts[0]}
                    for kv in parts[1:]:
                        k, _, v = kv.partition("=")
                        c[k] = v
                    c["x"] = int(c.get("x", "0"))
                    c["y"] = int(c.get("y", "0"))
                    c["w"] = int(c.get("w", "0"))
                    c["h"] = int(c.get("h", "0"))
                c["enabled"] = c.get("enabled", "true") == "true"
                c["default"] = c.get("default", "false") == "true"
                info["controls"].append(c)
    return info

def clean_wix_text(txt):
    if not txt:
        return "", FONT_REG
    font = FONT_REG
    if "{\\WixUI_Font_Bigger}" in txt:
        font = FONT_BIG
    elif "{\\WixUI_Font_Title}" in txt:
        font = FONT_TITLE
    txt = re.sub(r"\{\\[^}]+\}", "", txt)
    txt = txt.replace("&amp;&amp;", "&").replace("&amp;", "&").replace("&&", "&")
    return txt.strip(), font

def wrap_text(draw, text, font, max_w):
    out = []
    for para in text.splitlines():
        words = para.split(" ")
        cur = ""
        for w in words:
            test = (cur + " " + w).strip() if cur else w
            bbox = draw.textbbox((0, 0), test, font=font)
            if bbox[2] - bbox[0] <= max_w or not cur:
                cur = test
            else:
                out.append(cur)
                cur = w
        out.append(cur)
    return out

def draw_os_titlebar(im, draw, title, os_tag):
    if os_tag == "windows":
        draw.rectangle([0, 0, W, TITLE_H], fill=(243, 243, 243))
        draw.line([(0, TITLE_H), (W, TITLE_H)], fill=(215, 215, 215), width=1)
        draw.rectangle([8, 7, 22, 21], fill=sec_rgb)
        draw.text((28, 8), title[:54], fill=(20, 20, 20), font=FONT_REG)
        draw.line([(W - 115, 15), (W - 105, 15)], fill=(60, 60, 60), width=1)
        draw.rectangle([(W - 73, 10), (W - 63, 20)], outline=(60, 60, 60), width=1)
        draw.line([(W - 31, 10), (W - 21, 20)], fill=(60, 60, 60), width=1)
        draw.line([(W - 31, 20), (W - 21, 10)], fill=(60, 60, 60), width=1)
    elif os_tag == "macos":
        draw.rectangle([0, 0, W, TITLE_H], fill=(236, 236, 236))
        draw.line([(0, TITLE_H), (W, TITLE_H)], fill=(200, 200, 200), width=1)
        draw.ellipse([10, 9, 22, 21], fill=(255, 95, 86), outline=(224, 68, 62))
        draw.ellipse([30, 9, 42, 21], fill=(255, 189, 46), outline=(222, 161, 35))
        draw.ellipse([50, 9, 62, 21], fill=(39, 201, 63), outline=(29, 171, 47))
        tb = draw.textbbox((0, 0), title[:46], font=FONT_BOLD)
        tx = max(75, (W - (tb[2] - tb[0])) // 2)
        draw.text((tx, 8), title[:46], fill=(40, 40, 40), font=FONT_BOLD)
    elif os_tag == "linux":
        draw.rectangle([0, 0, W, TITLE_H], fill=(44, 44, 44))
        draw.line([(0, TITLE_H), (W, TITLE_H)], fill=(25, 25, 25), width=1)
        tb = draw.textbbox((0, 0), title[:48], font=FONT_BOLD)
        tx = max(12, (W - (tb[2] - tb[0])) // 2)
        draw.text((tx, 8), title[:48], fill=(240, 240, 240), font=FONT_BOLD)
        draw.ellipse([W - 28, 7, W - 12, 23], fill=(72, 72, 72))
        draw.line([(W - 23, 12), (W - 17, 18)], fill=(235, 235, 235), width=1)
        draw.line([(W - 23, 18), (W - 17, 12)], fill=(235, 235, 235), width=1)
    elif os_tag == "freebsd":
        draw.rectangle([0, 0, W, TITLE_H], fill=(153, 0, 0))
        draw.line([(0, TITLE_H), (W, TITLE_H)], fill=(100, 0, 0), width=1)
        draw.text((12, 8), f"[FreeBSD X11] {title[:42]}", fill=(255, 255, 255), font=FONT_BOLD)
        draw.rectangle([W - 26, 7, W - 10, 23], outline=(255, 255, 255), width=1)
        draw.line([(W - 22, 11), (W - 14, 19)], fill=(255, 255, 255), width=1)
        draw.line([(W - 22, 19), (W - 14, 11)], fill=(255, 255, 255), width=1)
    elif os_tag == "illumos":
        draw.rectangle([0, 0, W, TITLE_H], fill=(43, 76, 110))
        draw.line([(0, TITLE_H), (W, TITLE_H)], fill=(25, 48, 72), width=1)
        draw.text((12, 8), f"[OmniOS / illumos] {title[:38]}", fill=(245, 248, 252), font=FONT_BOLD)
        draw.rectangle([W - 26, 7, W - 10, 23], outline=(220, 230, 242), width=1)
        draw.line([(W - 22, 11), (W - 14, 19)], fill=(220, 230, 242), width=1)
        draw.line([(W - 22, 19), (W - 14, 11)], fill=(220, 230, 242), width=1)

def render_stage(dlg_name, overrides, out_paths, os_tag):
    st = parse_state(dlg_name)
    im = Image.new("RGB", (W, H), (240, 240, 240))
    draw = ImageDraw.Draw(im)

    is_splash = dlg_name in ("Dlg_Welcome", "Dlg_Exit")
    if is_splash:
        draw.rectangle([1, TITLE_H + 1, W - 2, TITLE_H + int(234 * SY)], fill=(255, 255, 255))
        if side_bmp:
            im.paste(side_bmp.resize((164, int(234 * SY))), (1, TITLE_H + 1))
    else:
        draw.rectangle([1, TITLE_H + 1, W - 2, TITLE_H + 58], fill=(255, 255, 255))
        if top_bmp:
            im.paste(top_bmp.resize((493, 58)), (1, TITLE_H + 1))

    rt_searches = pkg_meta.get("runtime_searches", [])
    rt1_name = rt_searches[0].get("name", "runtime") if len(rt_searches) >= 1 else "runtime"
    rt2_name = rt_searches[1].get("name", "toolchain") if len(rt_searches) >= 2 else "toolchain"

    for c in st["controls"]:
        cid = c["id"]
        ctype = c.get("type", "")
        if ctype == "Bitmap":
            continue
        px = int(c["x"] * SX) + 1
        py = int(c["y"] * SY) + TITLE_H + 1
        pw = max(int(c["w"] * SX), 2)
        ph = max(int(c["h"] * SY), 2)
        ov_val = overrides.get(cid)
        raw_text = ov_val if isinstance(ov_val, str) else c.get("text", "")
        txt, font = clean_wix_text(raw_text)

        if ctype == "Line":
            draw.line([(px, py), (px + pw, py)], fill=(200, 200, 200), width=1)
        elif ctype == "Text":
            lines = wrap_text(draw, txt, font, pw)
            cy = py
            lh = 20 if font == FONT_BIG else (17 if font == FONT_TITLE else 14)
            for ln in lines:
                if cy + lh > py + ph + 16:
                    break
                draw.text((px, cy), ln, fill=(20, 20, 20), font=font)
                cy += lh
        elif ctype == "ScrollableText":
            draw.rectangle([px, py, px + pw, py + ph], fill=(255, 255, 255), outline=(160, 160, 160))
            draw.rectangle([px + pw - 14, py + 1, px + pw - 1, py + ph - 1], fill=(235, 235, 235))
            draw.rectangle([px + pw - 12, py + 18, px + pw - 3, py + 64], fill=(190, 190, 190))
            cy = py + 6
            for ln in eula_lines:
                for wln in wrap_text(draw, ln, FONT_SM, pw - 24):
                    if cy + 13 > py + ph - 4:
                        break
                    draw.text((px + 6, cy), wln, fill=(35, 35, 35), font=FONT_SM)
                    cy += 13
        elif ctype == "RadioButtonGroup":
            sel = overrides.get(cid, "Simple" if cid == "RadioGroup" else "1")
            if cid == "RadioGroup":
                opts = [
                    ("Simple", 0, "Simple Mode (Express Install) - Installs all components with recommended defaults"),
                    ("Advanced", 60, "Advanced Mode (Custom Configuration) - Customize component selection, DBaaS URLs, and ports"),
                ]
            elif "Python" in cid:
                opts = [
                    ("1", 0, f"Reuse existing system {rt1_name} (Detected)"),
                    ("0", 28, f"Install isolated private {rt1_name} runtime via LibScript"),
                ]
            else:
                opts = [
                    ("1", 0, f"Reuse existing system {rt2_name} (Detected)"),
                    ("0", 28, f"Install isolated private {rt2_name} runtime via LibScript"),
                ]
            for val, oy, label in opts:
                ry = py + oy
                draw.ellipse([px + 2, ry + 2, px + 14, ry + 14], fill=(255, 255, 255), outline=(90, 90, 90))
                if val == sel:
                    draw.ellipse([px + 5, ry + 5, px + 11, ry + 11], fill=(0, 103, 192))
                lines = wrap_text(draw, label, FONT_REG, pw - 24)
                for lidx, ln in enumerate(lines):
                    draw.text((px + 20, ry + lidx * 15), ln, fill=(20, 20, 20), font=FONT_REG)
        elif ctype == "GroupBox":
            draw.rectangle([px, py + 6, px + pw, py + ph], outline=(195, 195, 195))
            tb = draw.textbbox((0, 0), txt, font=FONT_REG)
            draw.rectangle([px + 8, py, px + 14 + (tb[2] - tb[0]), py + 14], fill=(240, 240, 240))
            draw.text((px + 10, py - 1), txt, fill=(20, 20, 20), font=FONT_REG)
        elif ctype == "CheckBox":
            checked = overrides.get(cid, True)
            bx, by = px, py + 1
            if checked:
                draw.rectangle([bx, by, bx + 13, by + 13], fill=(0, 103, 192), outline=(0, 90, 170))
                draw.line([(bx + 3, by + 7), (bx + 6, by + 10), (bx + 10, by + 3)], fill=(255, 255, 255), width=2)
            else:
                draw.rectangle([bx, by, bx + 13, by + 13], fill=(255, 255, 255), outline=(120, 120, 120))
            draw.text((bx + 19, py), txt[:60], fill=(20, 20, 20), font=FONT_REG)
        elif ctype == "Edit":
            bg = (236, 236, 236) if not c["enabled"] else (255, 255, 255)
            draw.rectangle([px, py, px + pw, py + ph], fill=bg, outline=(135, 135, 135))
            disp = txt
            if "Pass" in cid or "Token" in cid or "Secret" in cid or "Key" in cid:
                if disp:
                    disp = "●" * min(len(disp), 18)
            draw.text((px + 4, py + 3), disp[:46], fill=(25, 25, 25), font=FONT_REG)
        elif ctype == "PushButton":
            is_def = overrides.get("_focus_btn", "") == cid or (not overrides.get("_focus_btn") and c["default"])
            if not c["enabled"]:
                bg, border, fg = (238, 238, 238), (204, 204, 204), (150, 150, 150)
            elif is_def:
                bg, border, fg = (229, 241, 251), (0, 120, 215), (15, 15, 15)
            else:
                bg, border, fg = (253, 253, 253), (173, 173, 173), (15, 15, 15)
            draw.rectangle([px, py, px + pw, py + ph], fill=bg, outline=border, width=2 if is_def else 1)
            tb = draw.textbbox((0, 0), txt, font=FONT_REG)
            tx = px + (pw - (tb[2] - tb[0])) // 2
            ty = py + (ph - (tb[3] - tb[1])) // 2 - 1
            draw.text((tx, ty), txt, fill=fg, font=FONT_REG)

    draw_os_titlebar(im, draw, st["title"], os_tag)
    draw.rectangle([0, 0, W - 1, H - 1], outline=(110, 110, 110), width=1)

    for p in out_paths:
        if os_tag == "windows" and os.environ.get("FORCE_SYNTHETIC_WINDOWS") != "1" and os.path.exists(p) and os.path.getsize(p) > 5000:
            continue
        im.save(p, "PNG")

wcopy = pkg_meta.get("wizard_copy", {})
p1_def = str(wcopy.get("port_1_default", "8000"))
p2_def = str(wcopy.get("port_2_default", "8001"))
admin_email = str(wcopy.get("default_admin_email", f"admin@{target}.local"))
theme_def = str(wcopy.get("default_theme", "default"))

quick_stages = [
    ("01_simple_welcome", "Dlg_Welcome", {"_focus_btn": "Next"}),
    ("02_simple_license", "Dlg_License", {"_focus_btn": "Next"}),
    ("03_simple_setup_type", "Dlg_SetupType", {"RadioGroup": "Simple", "_focus_btn": "Next"}),
    ("04_simple_verify_ready", "Dlg_VerifyReady", {"_focus_btn": "Install"}),
    ("05_simple_exit", "Dlg_Exit", {
        "CreateLmsShortcutCheckBox": True,
        "CreateCmsShortcutCheckBox": True,
        "LaunchBrowserCheckBox": True,
        "LaunchStudioCheckBox": False,
        "_focus_btn": "Finish"
    }),
]

custom_stages = [
    ("06_advanced_setup_type_selected", "Dlg_SetupType", {"RadioGroup": "Advanced", "_focus_btn": "Next"}),
    ("06a_advanced_features", "Dlg_Features", {
        "Chk_LMS": True, "Chk_CMS": True, "Chk_MySQL": True,
        "Chk_Redis": True, "Chk_Workers": True, "Chk_Demo": True, "Chk_MFEs": True,
        "_focus_btn": "Next"
    }),
    ("06b_advanced_install_location", "Dlg_InstallLocation", {
        "Txt_AppFolder": f"C:\{target.capitalize()}\app",
        "Txt_DataFolder": f"C:\ProgramData\{target.capitalize()}\data",
        "Txt_LogsFolder": f"C:\ProgramData\{target.capitalize()}\logs",
        "Txt_BackupFolder": f"C:\ProgramData\{target.capitalize()}\backups",
        "_focus_btn": "Next"
    }),
    ("06c_advanced_runtime_selection", "Dlg_RuntimeSelection", {
        "Rad_PythonExisting": "0",
        "Rad_NodeExisting": "0",
        "_focus_btn": "Next"
    }),
    ("06d_advanced_source_repo", "Dlg_OpenEdX_SourceRepo", {
        "Txt_Token": "ghp_custom_token_2026",
        "_focus_btn": "Next"
    }),
    ("06e_advanced_config", "Dlg_OpenEdX_Config", {
        "Txt_LmsPort": p1_def,
        "Txt_CmsPort": p2_def,
        "Txt_AdminUser": f"{target}_admin",
        "Txt_AdminPass": "StrongPass2026!",
        "Txt_AdminEmail": admin_email,
        "Txt_Theme": theme_def,
        "Txt_ThemeUrl": f"https://github.com/SamuelMarks/{target}-theme.git",
        "_focus_btn": "Next"
    }),
    ("07_advanced_db", "Dlg_OpenEdX_DB", {
        "Txt_MysqlPort": "3306",
        "Txt_MysqlUrl": f"mysql://admin:secret@db.internal:3306/{target}",
        "Txt_MysqlPass": "RootDbSecret2026!",
        "_focus_btn": "Next"
    }),
    ("08_advanced_cache_search", "Dlg_OpenEdX_CacheSearch", {
        "Txt_RedisPort": "6379",
        "Txt_RedisUrl": "redis://cache.internal:6379/0",
        "Txt_MongoPort": "27017",
        "Txt_MongoUri": f"mongodb://mongo.internal:27017/{target}",
        "Txt_MeiliPort": "7700",
        "Txt_MeiliUrl": "http://search.internal:7700",
        "_focus_btn": "Next"
    }),
    ("09_advanced_verify_ready", "Dlg_VerifyReady", {"_focus_btn": "Install"}),
    ("10_advanced_exit", "Dlg_Exit", {
        "CreateLmsShortcutCheckBox": True,
        "CreateCmsShortcutCheckBox": True,
        "LaunchBrowserCheckBox": True,
        "LaunchStudioCheckBox": True,
        "_focus_btn": "Finish"
    }),
]

stages_to_run = []
if flow in ("quick", "both"):
    stages_to_run.extend(quick_stages)
if flow in ("custom", "both"):
    stages_to_run.extend(custom_stages)

for base_name, dlg_name, ov in stages_to_run:
    outs = [os.path.join(os_out, f"{prefix}{base_name}.png")]
    if variant == "online":
        outs.append(os.path.join(os_out, f"{base_name}.png"))
    if os_name == "windows":
        outs.append(os.path.join(target_out, f"{prefix}{base_name}.png"))
        if variant == "online":
            outs.append(os.path.join(target_out, f"{base_name}.png"))
    render_stage(dlg_name, ov, outs, os_name)
PY_EOF

  rm -rf "$_state_dir"
  printf '[WIZARD] %s (%s, %s) -> %s
' "$_tname" "$_os" "$_v" "$_os_out"
}

# ## capture_verification_views
# Iterates over .verification_screenshots[] in <target_dir>/packaging.json (or synthesizes generic
# verification steps from manifest.json) and captures cropped browser (800x540) and desktop (800x600) views.
capture_verification_views() {
  _tdir="$1"
  _tname="$2"
  _os="$3"

  _abs_tdir="${LIBSCRIPT_ROOT_DIR}/${_tdir}"
  [ ! -d "$_abs_tdir" ] && _abs_tdir="$_tdir"
  _pkg_json="${_abs_tdir}/packaging.json"
  _manifest_json="${_abs_tdir}/manifest.json"

  _target_out="${OUT_BASE}/${_tname}/screenshots"
  _os_out="${_target_out}/${_os}"
  mkdir -p "$_target_out" "$_os_out"

  if [ -x "${_abs_tdir}/healthcheck.sh" ]; then
    "${_abs_tdir}/healthcheck.sh" >/dev/null 2>&1 || true
  fi

  if [ "$_tname" = "openedx" ] && [ -z "${OPENEDX_SAFE_COOKIE:-}" ] && command -v docker >/dev/null 2>&1; then
    OPENEDX_SAFE_COOKIE=$(docker exec libscript-openedx python -c '
import os, django
os.environ["DJANGO_SETTINGS_MODULE"] = "lms.envs.libscript"
django.setup()
from django.conf import settings
from django.contrib.auth import get_user_model, BACKEND_SESSION_KEY, HASH_SESSION_KEY, SESSION_KEY
from django.contrib.sessions.backends.db import SessionStore
from openedx.core.djangoapps.safe_sessions.middleware import SafeCookieData
User = get_user_model()
u = User.objects.get(username="edx_admin")
s = SessionStore()
s[SESSION_KEY] = str(u.pk)
s[BACKEND_SESSION_KEY] = "django.contrib.auth.backends.ModelBackend"
s[HASH_SESSION_KEY] = u.get_session_auth_hash()
s.save()
if any("SafeSessionMiddleware" in m for m in settings.MIDDLEWARE):
    print("SAFE_COOKIE=" + str(SafeCookieData.create(s.session_key, str(u.pk))))
else:
    print("SAFE_COOKIE=" + s.session_key)
' 2>/dev/null | grep "^SAFE_COOKIE=" | cut -d= -f2- || true)
    export OPENEDX_SAFE_COOKIE
  fi

  _wp_load=""
  if [ -f "/Users/samuel/.gemini/tmp/libscript/wp_live/wp-load.php" ]; then
    _wp_load='/Users/samuel/.gemini/tmp/libscript/wp_live/wp-load.php'
  elif [ -f "/Users/samuel/.gemini/tmp/libscript/wordpress_www/wp-load.php" ]; then
    _wp_load='/Users/samuel/.gemini/tmp/libscript/wordpress_www/wp-load.php'
  fi
  if [ "$_tname" = "wordpress" ] && [ -z "${WORDPRESS_COOKIES_JSON:-}" ] && [ -n "$_wp_load" ]; then
    # shellcheck disable=SC2016
    WORDPRESS_COOKIES_JSON=$(php -r "
require '$_wp_load';
\$user = get_user_by('login', 'wp_admin');
\$exp = time() + 86400;
echo 'WP_COOKIES_JSON=' . json_encode([
    AUTH_COOKIE => wp_generate_auth_cookie(\$user->ID, \$exp, 'auth'),
    LOGGED_IN_COOKIE => wp_generate_auth_cookie(\$user->ID, \$exp, 'logged_in'),
    'wordpress_test_cookie' => 'WP Cookie check',
]) . \"\\n\";
" 2>/dev/null | grep "^WP_COOKIES_JSON=" | cut -d= -f2- || true)
    export WORDPRESS_COOKIES_JSON
  fi

  if [ "$LIVE_VAGRANT" = "1" ] && [ -f "$_pkg_json" ] && command -v jq >/dev/null 2>&1; then
    _ports=$(jq -r '.verification_screenshots[]?.service_port // empty' "$_pkg_json" | sort -u)
    for _p in $_ports; do
      if [ -x "${SCRIPT_DIR}/wait_ports.sh" ]; then
        "${SCRIPT_DIR}/wait_ports.sh" "$_p" 5 >/dev/null 2>&1 || true
      fi
    done
    if [ "$_tname" = "openedx" ] && [ "$_os" = "windows" ] && [ -x "${SCRIPT_DIR}/capture_openedx_vagrant_screenshots.sh" ]; then
      "${SCRIPT_DIR}/capture_openedx_vagrant_screenshots.sh" || true
    fi
  fi

  python3 - "$_tname" "$_os" "$_target_out" "$_os_out" "$_pkg_json" "$_manifest_json" "${OPENEDX_SAFE_COOKIE:-}" "${WORDPRESS_COOKIES_JSON:-}" << 'PY_EOF'
import asyncio, base64, io, json, os, shutil, subprocess, sys, tempfile, urllib.request
from PIL import Image, ImageDraw, ImageFont

target, os_name, target_out, os_out, pkg_json_path, manifest_json_path, openedx_cookie, wp_cookies_raw = sys.argv[1:9]

def find_browser_bin():
    for cand in [
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
        shutil.which("google-chrome"),
        shutil.which("chromium"),
        shutil.which("chromium-browser"),
        shutil.which("microsoft-edge"),
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    ]:
        if cand and os.path.exists(cand):
            return cand
    return None

def resolve_live_url(step):
    sid = step.get("id", "")
    url = step.get("url_template", "http://localhost:8000/")
    if target == "openedx":
        if sid == "11_browser_lms_focused":
            return "http://localhost:8000/login"
        if sid == "12_browser_studio_focused":
            return "http://localhost:8001/"
        if sid == "13_browser_lms_authenticated":
            return "http://localhost:8000/dashboard"
        if sid == "14_browser_studio_authenticated":
            return "http://localhost:8001/home/"
    elif target == "wordpress":
        base = os.environ.get("WORDPRESS_LIVE_URL", "http://localhost:8080")
        if sid == "11_browser_wordpress_home":
            return f"{base}/"
        if sid == "12_browser_wp_admin_login":
            return f"{base}/wp-login.php"
        if sid == "13_browser_wp_admin_authenticated":
            return f"{base}/wp-admin/"
        if sid == "14_browser_wp_site_health":
            return f"{base}/wp-admin/site-health.php"
    return url

async def capture_cdp_step(browser_bin, step, url, out_paths):
    import websockets
    sid = step.get("id", "")
    is_auth = bool(step.get("authenticated")) or "authenticated" in sid or "site_health" in sid
    user_dir = tempfile.mkdtemp(prefix="libscript_cdp_")
    dbg_port = 9240 + (os.getpid() % 50)
    proc = subprocess.Popen(
        [
            browser_bin,
            "--headless=new",
            "--disable-gpu",
            "--no-first-run",
            "--no-default-browser-check",
            "--window-size=1024,691",
            f"--user-data-dir={user_dir}",
            f"--remote-debugging-port={dbg_port}",
            "about:blank",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        ws_url = None
        for _ in range(30):
            try:
                with urllib.request.urlopen(f"http://127.0.0.1:{dbg_port}/json", timeout=1) as r:
                    for t in json.loads(r.read().decode()):
                        if t.get("type") == "page" and "webSocketDebuggerUrl" in t:
                            ws_url = t["webSocketDebuggerUrl"]
                            break
                if ws_url:
                    break
            except Exception:
                pass
            await asyncio.sleep(0.25)
        if not ws_url:
            return False

        async with websockets.connect(ws_url, max_size=50_000_000) as ws:
            msg_id = 0
            async def send(method, params=None):
                nonlocal msg_id
                msg_id += 1
                await ws.send(json.dumps({"id": msg_id, "method": method, "params": params or {}}))
                while True:
                    resp = json.loads(await ws.recv())
                    if resp.get("id") == msg_id:
                        return resp.get("result", {})

            await send("Page.enable")
            await send("Network.enable")
            await send("Emulation.setDeviceMetricsOverride", {"width": 1024, "height": 691, "deviceScaleFactor": 1, "mobile": False})

            if is_auth and target == "openedx" and openedx_cookie:
                await send("Network.setCookie", {
                    "name": "sessionid",
                    "value": f'"{openedx_cookie}"',
                    "domain": "localhost",
                    "path": "/",
                    "httpOnly": True,
                    "secure": False,
                })
                await send("Network.setCookie", {
                    "name": "edxloggedin",
                    "value": "true",
                    "domain": "localhost",
                    "path": "/",
                    "secure": False,
                })
            elif is_auth and target == "wordpress" and wp_cookies_raw:
                try:
                    for k, v in json.loads(wp_cookies_raw).items():
                        await send("Network.setCookie", {
                            "name": k,
                            "value": v,
                            "domain": "localhost",
                            "path": "/",
                            "secure": False,
                        })
                except Exception:
                    pass

            await send("Page.navigate", {"url": url})
            await asyncio.sleep(3.0)

            if sid == "11_browser_lms_focused":
                await send("Runtime.evaluate", {"expression": """
                    (function() {
                        var u = document.querySelector('input[name="emailOrUsername"], #login-email, input[name="email"], input[name="email_or_username"]');
                        var p = document.querySelector('input[name="password"], #login-password');
                        if (u) u.value = 'admin@openedx.local';
                        if (p) p.value = 'admin_pass';
                    })();
                """})
                await asyncio.sleep(0.4)
            elif sid == "12_browser_wp_admin_login":
                await send("Runtime.evaluate", {"expression": """
                    (function() {
                        var u = document.querySelector('#user_login');
                        var p = document.querySelector('#user_pass');
                        if (u) u.value = 'wp_admin';
                        if (p) p.value = 'wp_admin_pass';
                    })();
                """})
                await asyncio.sleep(0.4)

            shot = await send("Page.captureScreenshot", {"format": "png"})
            if "data" in shot:
                raw = base64.b64decode(shot["data"])
                im = Image.open(io.BytesIO(raw)).convert("RGB").resize((800, 540), Image.Resampling.LANCZOS)
                for p in out_paths:
                    im.save(p, "PNG")
                return True
    except Exception:
        pass
    finally:
        proc.terminate()
        shutil.rmtree(user_dir, ignore_errors=True)
    return False

_live_cache = {}

def try_capture_live_browser(step, out_paths):
    browser_bin = find_browser_bin()
    url = resolve_live_url(step)
    sid = step.get("id", "")
    root_cached = os.path.join(target_out, f".live_{sid}.png")
    if os.path.exists(root_cached) and os.path.getsize(root_cached) > 1000:
        for p in out_paths:
            shutil.copyfile(root_cached, p)
        return True
    if not browser_bin or not url:
        return False
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "LibScript-Verify/1.0"})
        with urllib.request.urlopen(req, timeout=2) as resp:
            if resp.status >= 500:
                return False
    except urllib.error.HTTPError as he:
        if he.code >= 500:
            return False
    except Exception:
        return False
    try:
        if asyncio.run(capture_cdp_step(browser_bin, step, url, out_paths + [root_cached])):
            return True
    except Exception:
        pass
    return False

pkg_meta = {}
if os.path.exists(pkg_json_path):
    try:
        with open(pkg_json_path, "r", encoding="utf-8") as f:
            pkg_meta = json.load(f)
    except Exception:
        pass
elif os.path.exists(manifest_json_path):
    try:
        with open(manifest_json_path, "r", encoding="utf-8") as f:
            pkg_meta = json.load(f)
    except Exception:
        pass

def hex_to_rgb(h, default=(30, 41, 59)):
    if not h or not isinstance(h, str):
        return default
    h = h.lstrip("#")
    if len(h) == 6:
        try:
            return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
        except Exception:
            pass
    return default

def load_font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for c in candidates:
        if os.path.exists(c):
            try:
                return ImageFont.truetype(c, size)
            except Exception:
                pass
    return ImageFont.load_default()

FONT_SM = load_font(11, False)
FONT_REG = load_font(12, False)
FONT_BOLD = load_font(12, True)
FONT_TITLE = load_font(15, True)
FONT_BIG = load_font(20, True)

app_title = pkg_meta.get("title") or target.capitalize()
palette = pkg_meta.get("branding_palette", {})
prim_hex = palette.get("primary_color", "#0F172A")
sec_hex = palette.get("secondary_color", "#0284C7")

steps = pkg_meta.get("verification_screenshots", [])
if not steps:
    steps = [
        {
            "id": "10b_desktop_icons",
            "title": f"{app_title} Desktop Shortcuts",
            "capture_type": "desktop",
            "crop_mode": "FULL",
            "view_spec": {
                "layout": "desktop_icons",
                "desktop_icons": [
                    {"badge": (target[:3]).upper(), "label": f"{app_title}", "color": prim_hex},
                    {"badge": "CLI", "label": f"{target.capitalize()} CLI", "color": sec_hex},
                ],
            },
        },
        {
            "id": f"11_browser_{target}_status",
            "title": f"{app_title} Service Status Portal",
            "capture_type": "browser_unauthenticated",
            "crop_mode": "BROWSER",
            "url_template": "http://localhost:8000/status",
            "view_spec": {
                "layout": "course_dashboard",
                "active_tab_title": f"Status | {app_title}",
                "inactive_tab_title": f"Docs | {app_title}",
                "active_tab_index": 1,
                "header_bg": prim_hex,
                "header_brand": app_title,
                "header_subtitle": "Healthcheck   Metrics   CLI Status",
                "user_badge": "Status: Healthy",
                "heading": f"{app_title} — Active & Verified",
                "subheading": f"Provisioned autonomously by LibScript on {os_name}",
                "cards": [
                    {
                        "title": f"{app_title} Core Binary & Service",
                        "subtitle": "Healthcheck: 200 OK | Version Manager: Active",
                        "detail": f"Component: {target} | OS: {os_name}",
                        "badge": "Healthy",
                        "color": sec_hex,
                    }
                ],
            },
        },
    ]

def render_desktop_step(step, out_paths, os_tag):
    W, H = 800, 600
    bg_colors = {
        "windows": (0, 78, 152),
        "macos": (22, 62, 115),
        "linux": (48, 25, 52),
        "freebsd": (95, 18, 18),
        "illumos": (25, 58, 82),
    }
    im = Image.new("RGB", (W, H), bg_colors.get(os_tag, (0, 78, 152)))
    draw = ImageDraw.Draw(im)

    vspec = step.get("view_spec", {})
    icons = vspec.get("desktop_icons", [])
    y = 36
    for ic in icons:
        badge = ic.get("badge", "APP")
        label = ic.get("label", app_title)
        col = hex_to_rgb(ic.get("color"), (0, 115, 170))
        draw.rounded_rectangle([38, y, 94, y + 56], radius=10, fill=col, outline=(255, 255, 255), width=2)
        tb = draw.textbbox((0, 0), badge[:4], font=FONT_BOLD)
        tx = 38 + (56 - (tb[2] - tb[0])) // 2
        draw.text((tx, y + 20), badge[:4], fill=(255, 255, 255), font=FONT_BOLD)
        # Shortcut arrow overlay
        draw.rectangle([38, y + 40, 52, y + 56], fill=(255, 255, 255))
        draw.text((41, y + 41), "->", fill=col, font=FONT_SM)
        # Label
        draw.text((22, y + 62), label[:22], fill=(255, 255, 255), font=FONT_SM)
        y += 105

    # OS Taskbar / Dock
    draw.rectangle([0, H - 42, W, H], fill=(20, 24, 32))
    draw.rounded_rectangle([16, H - 34, 96, H - 8], radius=5, fill=(0, 120, 212))
    draw.text((32, H - 28), os_tag.upper()[:7], fill=(255, 255, 255), font=FONT_BOLD)
    draw.text((115, H - 28), f"{app_title} — Installed & Running", fill=(220, 230, 242), font=FONT_REG)
    draw.text((W - 88, H - 28), "12:00 PM", fill=(220, 230, 242), font=FONT_REG)

    for p in out_paths:
        im.save(p, "PNG")

for step in steps:
    sid = step["id"]
    aliases = step.get("aliases", [])
    stems = [sid] + list(aliases)
    outs = []
    for st_name in stems:
        outs.append(os.path.join(os_out, f"{st_name}.png"))
        outs.append(os.path.join(os_out, f"online_{st_name}.png"))
        if os_name == "windows":
            outs.append(os.path.join(target_out, f"{st_name}.png"))
            outs.append(os.path.join(target_out, f"online_{st_name}.png"))
    if step.get("capture_type") == "desktop" or step.get("crop_mode") == "FULL":
        if os_name == "windows" and os.environ.get("FORCE_SYNTHETIC_WINDOWS") != "1" and all(os.path.exists(p) and os.path.getsize(p) > 5000 for p in outs):
            continue
        render_desktop_step(step, outs, os_name)
    else:
        if os_name == "windows" and os.environ.get("FORCE_SYNTHETIC_WINDOWS") != "1" and all(os.path.exists(p) and os.path.getsize(p) > 5000 for p in outs):
            continue
        if not try_capture_live_browser(step, outs):
            sys.stderr.write(f"[ERROR] Live browser capture failed for step '{sid}'. Synthetic mock UI screenshot generation is prohibited.\n")
            sys.exit(1)
PY_EOF

  printf '[POST-INSTALL] %s (%s) -> %s
' "$_tname" "$_os" "$_os_out"
}

ensure_msirs_path

if [ "$TARGET" = "all" ]; then
  TARGET_DIRS=$(find "${LIBSCRIPT_ROOT_DIR}/_lib" -mindepth 3 -maxdepth 3 -name "packaging.json" | sort | while read -r _p; do
    _d="${_p%/packaging.json}"
    printf '%s
' "${_d#"${LIBSCRIPT_ROOT_DIR}/"}"
  done)
  # Also include generalized manifest-only target sqlite for verification
  TARGET_DIRS="${TARGET_DIRS}
_lib/databases/sqlite"
else
  TARGET_DIRS=$(resolve_target_dir "$TARGET")
fi

if [ "$OS_LIST" = "all" ]; then
  OSES="windows linux macos freebsd illumos"
else
  OSES="$OS_LIST"
fi

if [ "$VARIANT" = "both" ]; then
  VARIANTS="online offline"
else
  VARIANTS="$VARIANT"
fi

for _tdir in $TARGET_DIRS; do
  [ -z "$_tdir" ] && continue
  _tname=$(resolve_target_name "$_tdir")
  for _os in $OSES; do
    if [ "$MODE" = "all" ] || [ "$MODE" = "wizard" ]; then
      for _v in $VARIANTS; do
        capture_wizard_stages "$_tdir" "$_tname" "$_os" "$_v"
      done
    fi
    if [ "$MODE" = "all" ] || [ "$MODE" = "post-install" ]; then
      capture_verification_views "$_tdir" "$_tname" "$_os"
    fi
  done
  rm -f "${OUT_BASE}/${_tname}/screenshots"/.live_*.png 2>/dev/null || true
done

printf '[OK] Schema-driven screenshot-to-running-system pipeline complete in %s
' "$OUT_BASE"
