#!/bin/sh
# ## Overview
# Implements packaging logic for the 'docker_compose' format.
# 
# ## Usage
# This script is called by the packaging system and should not be executed manually.


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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
    base_image="debian:bookworm-slim"
    while [ $# -gt 0 ]; do
      case "$1" in
        --base|--base-image)
          base_image="$2"
          if [ "$base_image" = "debian" ]; then
            base_image="debian:bookworm-slim"
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
      deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.layer // "deps") \(.name) \(.version // "latest") \(.override // "")"' 2>/dev/null || true)
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
    fi

    if [ -n "$deps_list" ]; then
      printf '%s\n' "version: '3.8'"
      printf '%s\n' "services:"

      sorted_deps=$(printf '%b\n' "$deps_list" | awk '
      function get_priority(pkg) {
          if (pkg ~ /^(fluentbit|docker|etcd|openvpn|kubernetes-k0s|kubernetes-thw)$/) return 10;
          if (pkg ~ /^(postgres|mysql|mariadb|mongodb|redis|valkey|sqlite|rabbitmq|celery)$/) return 20;
          if (pkg ~ /^(php|python|nodejs|ruby|java|go|rust|c|cpp|csharp|bun|deno|elixir|jq|kotlin|swift|wait4x|zig|sh|cc)$/) return 30;
          if (pkg ~ /^(nginx|caddy|httpd|firecrawl|jupyterhub)$/) return 40;
          return 50;
      }
      NF > 0 {
          if (seen[$2]) next;
          seen[$2] = 1;
          lines[++count] = $0;
          priorities[count] = get_priority($2);
      }
      END {
          for (i = 1; i <= count; i++) {
              for (j = i + 1; j <= count; j++) {
                  if (priorities[i] > priorities[j]) {
                      temp = lines[i]; lines[i] = lines[j]; lines[j] = temp;
                      temp_p = priorities[i]; priorities[i] = priorities[j]; priorities[j] = temp_p;
                  }
              }
          }
          for (i = 1; i <= count; i++) {
              print lines[i];
          }
      }')

      prev_pkg=""
      printf '%s\n' "$sorted_deps" | while read -r layer pkg ver override; do
        if [ -n "$pkg" ]; then
          if [ "$ver" = "null" ]; then ver="latest"; fi

          df="Dockerfile.$pkg"
          printf '%s\n' "FROM $base_image" > "$df"
          printf '%s\n' "ARG TARGETOS=linux" >> "$df"
          printf '%s\n' "ARG TARGETARCH=amd64" >> "$df"
          printf '%s\n' "ENV LC_ALL=C.UTF-8 LANG=C.UTF-8" >> "$df"
          printf '%s\n' "ENV LIBSCRIPT_ROOT_DIR=\"/opt/libscript\"" >> "$df"
          printf '%s\n' "ENV LIBSCRIPT_BUILD_DIR=\"/opt/libscript_build\"" >> "$df"
          printf '%s\n' "ENV LIBSCRIPT_DATA_DIR=\"/opt/libscript_data\"" >> "$df"
          printf '%s\n' "ENV LIBSCRIPT_CACHE_DIR=\"/opt/libscript_cache\"" >> "$df"

          pkg_up=$(printf '%s\n' "$pkg" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
          printf '%s\n' "ENV ${pkg_up}_VERSION=\"$ver\"" >> "$df"
          if [ -n "$override" ] && [ "$override" != "null" ]; then
              printf '%s\n' "ENV ${pkg_up}_URL=\"$override\"" >> "$df"
              filename=$(basename "${override%%\?*}")
              printf '%s\n' "ADD \${${pkg_up}_URL} /opt/libscript_cache/$pkg/$filename" >> "$df"
          fi
          printf '%s\n' "COPY . /opt/libscript" >> "$df"
          printf '%s\n' "WORKDIR /opt/libscript" >> "$df"
          printf '%s\n' "RUN ./libscript.sh install $pkg \${${pkg_up}_VERSION}" >> "$df"

          healthcheck="[\"CMD-SHELL\", \"echo '$pkg is ok' || exit 1\"]"
          if [ "$pkg" = "postgres" ]; then healthcheck="[\"CMD\", \"pg_isready\", \"-U\", \"postgres\"]"; fi
          if [ "$pkg" = "mysql" ] || [ "$pkg" = "mariadb" ]; then healthcheck="[\"CMD\", \"mysqladmin\", \"ping\", \"-h\", \"localhost\"]"; fi
          if [ "$pkg" = "redis" ] || [ "$pkg" = "valkey" ]; then healthcheck="[\"CMD\", \"redis-cli\", \"ping\"]"; fi
          if [ "$pkg" = "mongodb" ]; then healthcheck="[\"CMD\", \"mongosh\", \"--eval\", \"db.adminCommand('ping')\"]"; fi
          if [ "$pkg" = "rabbitmq" ]; then healthcheck="[\"CMD\", \"rabbitmq-diagnostics\", \"ping\"]"; fi
          if [ "$pkg" = "nginx" ] || [ "$pkg" = "caddy" ] || [ "$pkg" = "httpd" ]; then healthcheck="[\"CMD-SHELL\", \"curl -f http://localhost/ || exit 1\"]"; fi
          if [ "$pkg" = "php" ]; then healthcheck="[\"CMD-SHELL\", \"php -v || exit 1\"]"; fi
          if [ "$pkg" = "python" ]; then healthcheck="[\"CMD-SHELL\", \"python3 --version || exit 1\"]"; fi
          if [ "$pkg" = "nodejs" ]; then healthcheck="[\"CMD-SHELL\", \"node -v || exit 1\"]"; fi
          if [ "$pkg" = "fluentbit" ]; then healthcheck="[\"CMD-SHELL\", \"wget -qO- http://127.0.0.1:2020/api/v1/health || exit 1\"]"; fi

          if [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
              custom_hc=$(jq -r ".deps[\"$pkg\"].healthcheck // .servers[\"$pkg\"].healthcheck // .databases[\"$pkg\"].healthcheck // .third_party[\"$pkg\"].healthcheck // .storage[\"$pkg\"].healthcheck // .toolchains[\"$pkg\"].healthcheck // empty | if type == \"object\" then .test | tojson elif type == \"string\" then \"[\\\"CMD-SHELL\\\", \\\"\" + . + \"\\\"]\" else empty end" libscript.json 2>/dev/null || true)
              if [ -n "$custom_hc" ] && [ "$custom_hc" != "null" ]; then
                  healthcheck="$custom_hc"
              fi
          fi

          printf '%s\n' "  $pkg:"
          printf '%s\n' "    build:"
          printf '%s\n' "      context: ."
          printf '%s\n' "      dockerfile: $df"
          printf '%s\n' "    healthcheck:"
          printf '%s\n' "      test: $healthcheck"
          printf '%s\n' "      interval: 5s"
          printf '%s\n' "      retries: 5"
          printf '%s\n' "      start_period: 5s"

          if [ -n "$prev_pkg" ]; then
              printf '%s\n' "    depends_on:"
              printf '%s\n' "      $prev_pkg:"
              printf '%s\n' "        condition: service_healthy"
          fi

          printf '%s\n' "    environment:"
          if [ -n "$override" ] && [ "$override" != "null" ]; then
            printf '%s\n' "      - ${pkg_up}_URL=\"$override\""
          fi
          if env_out=$(PREFIX="/opt/libscript/installed/$pkg" "${THIS_FILE}" env "$pkg" "$ver" --format=docker_compose 2>/dev/null); then
            printf '%s\n' "$env_out" | grep -vE '^(STACK=|SCRIPT_NAME=)' | sed 's/^/      - /g'
          fi

          prev_pkg="$pkg"
        fi
      done
    fi
    exit 0
