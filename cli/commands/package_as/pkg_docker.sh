#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
    base_image="debian:bookworm-slim"
    layer_filter=""
    artifact_type=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --layer|-l)
          layer_filter="$2"
          shift 2
          ;;
        --artifact|-a)
          artifact_type="$2"
          if [ "$artifact_type" = "deb" ]; then
            base_image="debian:bookworm-slim"
          elif [ "$artifact_type" = "rpm" ]; then
            base_image="almalinux:9"
          elif [ "$artifact_type" = "apk" ]; then
            base_image="alpine:latest"
          elif [ "$artifact_type" = "txz" ]; then
            base_image="freebsd"
          elif [ "$artifact_type" = "msi" ] || [ "$artifact_type" = "exe" ]; then
            base_image="mcr.microsoft.com/windows/servercore:ltsc2022"
          fi
          shift 2
          ;;
        --base|--base-image)
          base_image="$2"
          if [ "$base_image" = "debian" ]; then
    base_image="debian:bookworm-slim"
    layer_filter=""
          elif [ "$base_image" = "alpine" ]; then
            base_image="alpine:latest"
          fi
          shift 2
          ;;
        *)
          break
          ;;
      esac
    done

    echo "FROM $base_image"
    echo "ARG TARGETOS=linux"
    echo "ARG TARGETARCH=amd64"
    echo "ENV LC_ALL=C.UTF-8 LANG=C.UTF-8"
    echo "ENV LIBSCRIPT_ROOT_DIR=\"/opt/libscript\""
    echo "ENV LIBSCRIPT_BUILD_DIR=\"/opt/libscript_build\""
    echo "ENV LIBSCRIPT_DATA_DIR=\"/opt/libscript_data\""
    echo "ENV LIBSCRIPT_CACHE_DIR=\"/opt/libscript_cache\""
    
    tmp_env_add=$(mktemp)
    tmp_add=$(mktemp)
    tmp_run=$(mktemp)
    
    OUT_DIR="$(cd "$OUT_DIR" && pwd)"
    deps_list=""
    if [ $# -gt 0 ]; then
      while [ $# -gt 0 ]; do
        pkg="$1"
        ver="${2:-latest}"
        if echo "$3" | grep -q "^http"; then
          override="$3"
          shift 3
        elif [ "$2" != "" ]; then
          override=""
          shift 2
        else
          override=""
          shift
        fi
        deps_list="${deps_list}cli ${pkg} ${ver} ${override}\n"
      done
    elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
      deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.layer // "deps") \(.name) \(.version // "latest") \(.override // "")"' 2>/dev/null || true)
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
    fi

    if [ -n "$deps_list" ]; then
      gen_script=$(printf '%b\n' "$deps_list" | awk -v l_filter="$layer_filter" -v artifact_type="$artifact_type" '

      BEGIN {
         if (l_filter != "") {
            split(l_filter, f_arr, ",")
            for (f in f_arr) {
               allowed_layers[f_arr[f]] = 1
               allowed_layers[f_arr[f] "s"] = 1
            }
         }
      }
      NF > 0 {
         layer = $1
         pkg = $2
         ver = $3
         url = $4
         
         if (l_filter != "" && !(layer in allowed_layers) && layer != "cli") next;
         
         if (seen[pkg]) next;
         seen[pkg] = 1;

         pkg_up = toupper(pkg)
         sub(/^.*\//, "", pkg_up); gsub(/-/, "_", pkg_up)

         if (url != "" && url != "null") {
             extracted_ver = ""
             if (match(url, /[0-9]+\.[0-9]+(\.[0-9]+)?/)) {
                 extracted_ver = substr(url, RSTART, RLENGTH)
             }

             if ((ver == "" || ver == "latest" || ver == "null") && extracted_ver != "") {
                 ver = extracted_ver
             }
             
             if (ver == "" || ver == "null") ver = "latest"

             if (ver != "latest") {
                 escaped_ver = ver
                 temp_url = ""
                 remaining = url
                 while (i = index(remaining, ver)) {
                     temp_url = temp_url substr(remaining, 1, i - 1) "${" pkg_up "_VERSION}"
                     remaining = substr(remaining, i + length(ver))
                 }
                 url = temp_url remaining
             }
             
             if (match(url, /(amd64|arm64|x86_64|aarch64|386|armv7l|x64)/)) {
                 arch_str = substr(url, RSTART, RLENGTH)
                 gsub(arch_str, "${TARGETARCH}", url)
             }
             if (match(url, /(linux|darwin|windows)/)) {
                 os_str = substr(url, RSTART, RLENGTH)
                 gsub(os_str, "${TARGETOS}", url)
             }

             n = split(url, parts, "/")
             filename = parts[n]
             sub(/\?.*$/, "", filename)

             print "echo '\''ENV " pkg_up "_VERSION=\"" ver "\"'\'' >> \"$tmp_env_add\""
             print "echo '\''ENV " pkg_up "_URL=\"" url "\"'\'' >> \"$tmp_env_add\""
             if (artifact_type == "deb") {
                 print "echo '\''RUN apt-get update && apt-get install -y /opt/libscript/*-" pkg "_*.deb'\'' >> \"$tmp_run\""
             } else if (artifact_type == "rpm") {
                 print "echo '\''RUN dnf install -y /opt/libscript/*-" pkg "-*.rpm'\'' >> \"$tmp_run\""
             } else if (artifact_type == "apk") {
                 print "echo '\''RUN apk add --allow-untrusted /opt/libscript/*-" pkg "-*.apk'\'' >> \"$tmp_run\""
             } else if (artifact_type == "txz") {
                 print "echo '\''RUN pkg install -y /opt/libscript/*-" pkg "*.txz /opt/libscript/*-" pkg "*.pkg || true'\'' >> \"$tmp_run\""
             } else if (artifact_type == "msi") {
                 print "echo '\''RUN for %I in (C:\\opt\\libscript\\*-" pkg "-*.msi) do msiexec /i \"%I\" /qn /norestart'\'' >> \"$tmp_run\""
             } else if (artifact_type == "exe") {
                 print "echo '\''RUN for %I in (C:\\opt\\libscript\\*-" pkg "-*.exe) do \"%I\" /SILENT /VERYSILENT'\'' >> \"$tmp_run\""
             } else {
                 print "echo '\''ADD ${" pkg_up "_URL} /opt/libscript_cache/" pkg "/" filename "'\'' >> \"$tmp_add\""
                 print "echo '\''RUN ./libscript.sh install " pkg " ${" pkg_up "_VERSION}'\'' >> \"$tmp_run\""
             }
             print "PREFIX=\"/opt/libscript/installed/" pkg "\" \"'${this_file}'\" env \"" pkg "\" \"" ver "\" --format=docker | grep -vE \"^(ENV STACK=|ENV SCRIPT_NAME=)\" >> \"$tmp_run\" || true"
         } else {
             if (ver == "" || ver == "null") ver = "latest"
             print "echo '\''ENV " pkg_up "_VERSION=\"" ver "\"'\'' >> \"$tmp_env_add\""
             if (artifact_type == "deb") {
                 print "echo '\''RUN apt-get update && apt-get install -y /opt/libscript/*-" pkg "_*.deb'\'' >> \"$tmp_run\""
             } else if (artifact_type == "rpm") {
                 print "echo '\''RUN dnf install -y /opt/libscript/*-" pkg "-*.rpm'\'' >> \"$tmp_run\""
             } else if (artifact_type == "apk") {
                 print "echo '\''RUN apk add --allow-untrusted /opt/libscript/*-" pkg "-*.apk'\'' >> \"$tmp_run\""
             } else if (artifact_type == "txz") {
                 print "echo '\''RUN pkg install -y /opt/libscript/*-" pkg "*.txz /opt/libscript/*-" pkg "*.pkg || true'\'' >> \"$tmp_run\""
             } else if (artifact_type == "msi") {
                 print "echo '\''RUN for %I in (C:\\opt\\libscript\\*-" pkg "-*.msi) do msiexec /i \"%I\" /qn /norestart'\'' >> \"$tmp_run\""
             } else if (artifact_type == "exe") {
                 print "echo '\''RUN for %I in (C:\\opt\\libscript\\*-" pkg "-*.exe) do \"%I\" /SILENT /VERYSILENT'\'' >> \"$tmp_run\""
             } else {
                 print "echo '\''RUN ./libscript.sh install " pkg " ${" pkg_up "_VERSION}'\'' >> \"$tmp_run\""
             }
             print "PREFIX=\"/opt/libscript/installed/" pkg "\" \"'${this_file}'\" env \"" pkg "\" \"" ver "\" --format=docker | grep -vE \"^(ENV STACK=|ENV SCRIPT_NAME=)\" >> \"$tmp_run\" || true"
         }
      }')
      eval "$gen_script"
    else
      echo "RUN ./install_gen.sh" >> "$tmp_run"
    fi
    
    cat "$tmp_env_add"
    cat "$tmp_add"
    echo "COPY . /opt/libscript"
    echo "WORKDIR /opt/libscript"
    cat "$tmp_run"
    
    rm -f "$tmp_env_add" "$tmp_add" "$tmp_run"
    exit 0
