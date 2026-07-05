#!/bin/sh
# ## Overview
# Lifecycle script for merge_location_into_server.sh.
#
# ## Usage
# Refer to the internal functions of merge_location_into_server.sh for implementation details.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

merge_location_into_server() {
  EXISTING_CONFIG="$1"
  NEW_LOCATION_BLOCK="$2"
  TARGET_SERVER_NAME="$3"
  TARGET_LISTEN_REGEX="${4:-443.*ssl}"

  if [ ! -f "$NEW_LOCATION_BLOCK" ]; then
    NEW_LOCATION_TMP=$(mktemp)
    printf '%s\n' "$NEW_LOCATION_BLOCK" > "$NEW_LOCATION_TMP"
    NEW_LOCATION_BLOCK="$NEW_LOCATION_TMP"
  else
    NEW_LOCATION_TMP=""
  fi

  if [ ! -f "$EXISTING_CONFIG" ]; then
    >&2 printf 'Error: Existing config file "%s" not found.\n' "$EXISTING_CONFIG"
    [ -n "$NEW_LOCATION_TMP" ] && rm -f -- "$NEW_LOCATION_TMP"
    return 1
  fi

  LOCK_FILE="${EXISTING_CONFIG}.lock.dir"
  while ! mkdir "$LOCK_FILE" 2>/dev/null; do
    sleep 0.1
  done

  AWK_SCRIPT_TMP=$(mktemp)
  TMP_CONFIG=$(mktemp)

  cat << 'AWKEOF' > "$AWK_SCRIPT_TMP"
function parse_tokens(file_lines, file_nr, dirs_out) {
    state = "NORMAL"; tok = ""; dir_idx = 1; tok_idx = 1; brace_level = 0
    for (l = 1; l <= file_nr; l++) {
        line = file_lines[l]; len = length(line); c = 1
        while (c <= len) {
            ch = substr(line, c, 1)
            if (state == "NORMAL") {
                if (ch == "\\") {
                    tok = tok ch; c++; if (c <= len) tok = tok substr(line, c, 1)
                } else if (ch == "\"") {
                    state = "DQUOTE"; tok = tok ch
                } else if (ch == "'") {
                    state = "SQUOTE"; tok = tok ch
                } else if (ch == "#") {
                    break
                } else if (ch == "{" || ch == "}" || ch == ";") {
                    if (tok != "") { dirs_out[dir_idx, tok_idx++] = tok; tok = "" }
                    dirs_out[dir_idx, tok_idx++] = ch
                    dirs_out[dir_idx, "line"] = l; dirs_out[dir_idx, "brace_level"] = brace_level; dirs_out[dir_idx, "len"] = tok_idx - 1
                    if (ch == "{") brace_level++
                    if (ch == "}") brace_level--
                    dir_idx++; tok_idx = 1
                } else if (ch == " " || ch == "\t" || ch == "\r" || ch == "\n") {
                    if (tok != "") { dirs_out[dir_idx, tok_idx++] = tok; tok = "" }
                } else { tok = tok ch }
            } else if (state == "DQUOTE") {
                tok = tok ch
                if (ch == "\\") { c++; if (c <= len) tok = tok substr(line, c, 1) }
                else if (ch == "\"") { state = "NORMAL" }
            } else if (state == "SQUOTE") {
                tok = tok ch
                if (ch == "\\") { c++; if (c <= len) tok = tok substr(line, c, 1) }
                else if (ch == "'") { state = "NORMAL" }
            }
            c++
        }
        if (tok != "" && state == "NORMAL") { dirs_out[dir_idx, tok_idx++] = tok; tok = "" }
    }
    return dir_idx - 1
}

{
    if (NR == FNR) { new_lines[FNR] = $0; new_nr = FNR }
    else { target_lines[FNR] = $0; target_nr = FNR }
}

END {
    num_new_dirs = parse_tokens(new_lines, new_nr, new_dirs)
    num_target_dirs = parse_tokens(target_lines, target_nr, target_dirs)
    
    new_sig = ""
    for (i = 1; i <= num_new_dirs; i++) {
        if (new_dirs[i, 1] == "location" && new_dirs[i, "brace_level"] == 0) {
            for (j = 1; j < new_dirs[i, "len"]; j++) new_sig = new_sig new_dirs[i, j] " "
            break
        }
    }
    
    target_server_end_line = 0
    in_server = 0
    server_match_name = 0
    server_match_listen = 0
    server_start_idx = 0
    
    for (i = 1; i <= num_target_dirs; i++) {
        level = target_dirs[i, "brace_level"]
        cmd = target_dirs[i, 1]
        
        if (level == 0 && cmd == "server" && target_dirs[i, 2] == "{") {
            in_server = 1
            server_match_name = 0
            server_match_listen = 0
            server_start_idx = i
        } else if (in_server && level == 1) {
            if (cmd == "}") {
                in_server = 0
                if (server_match_name && server_match_listen) {
                    target_server_end_line = target_dirs[i, "line"]
                    break
                }
            } else if (cmd == "server_name") {
                for (j = 2; j < target_dirs[i, "len"]; j++) {
                    name = target_dirs[i, j]
                    gsub(/^"|"$/, "", name)
                    gsub(/^'|'$/, "", name)
                    if (name == ENVIRON["TARGET_SERVER_NAME"]) server_match_name = 1
                }
            } else if (cmd == "listen") {
                lstr = ""
                for (j = 2; j < target_dirs[i, "len"]; j++) lstr = lstr target_dirs[i, j] " "
                if (lstr ~ ENVIRON["TARGET_LISTEN_REGEX"]) server_match_listen = 1
            }
        }
    }
    
    if (!target_server_end_line) {
        print "Error: Target server block not found." > "/dev/stderr"
        exit 1
    }
    
    replace_start = 0
    replace_end = 0
    for (i = server_start_idx + 1; target_dirs[i, "line"] <= target_server_end_line && i <= num_target_dirs; i++) {
        if (target_dirs[i, "brace_level"] == 1 && target_dirs[i, 1] == "location") {
            loc_sig = ""
            for (j = 1; j < target_dirs[i, "len"]; j++) loc_sig = loc_sig target_dirs[i, j] " "
            if (loc_sig == new_sig) {
                replace_start = target_dirs[i, "line"]
                for (k = i + 1; k <= num_target_dirs; k++) {
                    if (target_dirs[k, 1] == "}" && target_dirs[k, "brace_level"] == 2) {
                        replace_end = target_dirs[k, "line"]
                        break
                    }
                }
                break
            }
        }
    }
    
    for (l = 1; l <= target_nr; l++) {
        if (replace_start && l >= replace_start && l <= replace_end) {
            if (l == replace_start) {
                for (nl = 1; nl <= new_nr; nl++) print new_lines[nl]
            }
            continue
        }
        if (!replace_start && l == target_server_end_line) {
            print ""
            for (nl = 1; nl <= new_nr; nl++) {
                if (new_lines[nl] != "") {
                    print "    " new_lines[nl]
                } else {
                    print ""
                }
            }
        }
        print target_lines[l]
    }
}
AWKEOF

  if ! TARGET_SERVER_NAME="$TARGET_SERVER_NAME" TARGET_LISTEN_REGEX="$TARGET_LISTEN_REGEX" awk -f "$AWK_SCRIPT_TMP" "$NEW_LOCATION_BLOCK" "$EXISTING_CONFIG" > "$TMP_CONFIG"; then
    >&2 printf 'Error: Failed to process configuration.\n'
    rm -rf -- "${LOCK_FILE}"
    rm -f -- "${AWK_SCRIPT_TMP}" "${TMP_CONFIG}"
    [ -n "${NEW_LOCATION_TMP:-}" ] && rm -f -- "${NEW_LOCATION_TMP}" || true
    return 1
  fi

  if command -v nginx >/dev/null 2>&1; then 
    TMP_NGINX_CONF=$(mktemp) 
    printf "events {}\nhttp {\n    include %s;\n}\n" "$TMP_CONFIG" > "$TMP_NGINX_CONF" 
    if ! nginx -t -c "$TMP_NGINX_CONF" -q 2>/dev/null; then 
      >&2 printf "Error: Nginx syntax check failed for the modified configuration.\n" 
      rm -rf -- "${LOCK_FILE}"; rm -f -- "${AWK_SCRIPT_TMP}" "${TMP_CONFIG}" "${TMP_NGINX_CONF}" 
      [ -n "${NEW_LOCATION_TMP:-}" ] && rm -f -- "${NEW_LOCATION_TMP}" || true 
      return 1 
    fi 
    rm -f -- "$TMP_NGINX_CONF" 
  fi

  # Atomic replace
  cp "$TMP_CONFIG" "$EXISTING_CONFIG.tmp"
  mv "$EXISTING_CONFIG.tmp" "$EXISTING_CONFIG"

  rm -rf -- "${LOCK_FILE}"
  rm -f -- "${AWK_SCRIPT_TMP}" "${TMP_CONFIG}"
  [ -n "${NEW_LOCATION_TMP:-}" ] && rm -f -- "${NEW_LOCATION_TMP}" || true
}
