#!/bin/sh
# ## Overview
# Provides a unified interface for managing service states (start, stop, restart,
# status, health, logs, down, uninstall-service, deprovision-db, export-state, import-state).
#
# ## Usage
# Execute this script to perform lifecycle actions on background services.

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
unset SCRIPT_NAME || true
if [ "$CMD" = "deprovision-db" ]; then
  json_file="${1:-libscript.json}"
  exec "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/deprovision_db.sh" "$json_file"
elif [ "$CMD" = "export-state" ]; then
  json_file="${1:-libscript.json}"
  stage_dir="${2:-}"
  exec "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/export_db.sh" "$json_file" "$stage_dir"
elif [ "$CMD" = "import-state" ]; then
  json_file="${1:-libscript.json}"
  stage_dir="${2:-}"
  exec "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/import_db.sh" "$json_file" "$stage_dir"
elif [ "$CMD" = "prepare-storage" ]; then
  json_file="${1:-libscript.json}"
  if [ -f "$json_file" ] && command -v jq >/dev/null 2>&1; then
    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
      # shellcheck disable=SC1090,SC1091
      . "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
      unset SCRIPT_NAME || true
      libscript_hydrate_manifest_env "$json_file" || true
    fi
    _ps_def_mount="${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}"
    _ps_mounts=$(jq -r --arg def "$_ps_def_mount" '(.infrastructure.node.data_disks // [])[]? | "\(.mount_path // $def) \(.fstype // "ext4")"' "$json_file" 2>/dev/null || true)
    if [ -n "$_ps_mounts" ]; then
      printf '%s\n' "$_ps_mounts" | while read -r _mp _fs; do
        [ -n "$_mp" ] || continue
        if type libscript_expand_manifest_vars >/dev/null 2>&1; then
          _mp=$(libscript_expand_manifest_vars "$_mp")
        fi
        case "$_mp" in
          \$\{*) _mp="$_ps_def_mount" ;;
        esac
        printf '[STORAGE] Ensuring persistent disk mount "%s" (fstype: %s, owner: %s)...\n' "$_mp" "${_fs:-ext4}" "${SERVICE_USER:-${REMOTE_USER:-root}}"
        "${LIBSCRIPT_ROOT_DIR:-.}/traits/storage/mount.sh" --auto-data-disk "$_mp" "${_fs:-ext4}"
      done
    fi
    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/service_install.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/service_install.sh"
      # shellcheck disable=SC1090,SC1091
      . "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/service_install.sh"
      unset SCRIPT_NAME || true
    fi
    _ps_overrides=$(jq -r '((.infrastructure.service_overrides // {}) * (.service_overrides // {})) | to_entries[]? | "\(.key) \(.value | to_entries | map("\(.key)=\(.value)") | join(" "))"' "$json_file" 2>/dev/null || true)
    if [ -n "$_ps_overrides" ] && type libscript_service_override_env >/dev/null 2>&1; then
      printf '%s\n' "$_ps_overrides" | while read -r _ovr_svc _ovr_pairs; do
        if [ -z "$_ovr_svc" ] || [ -z "$_ovr_pairs" ]; then
          continue
        fi
        if type libscript_expand_manifest_vars >/dev/null 2>&1; then
          _ovr_pairs=$(libscript_expand_manifest_vars "$_ovr_pairs")
        fi
        printf '[DAEMON] Applying service_overrides for "%s" (%s)...\n' "$_ovr_svc" "$_ovr_pairs"
        # shellcheck disable=SC2086
        libscript_service_override_env "$_ovr_svc" $_ovr_pairs || true
      done
    fi
    _ps_dir=$(cd -- "$(dirname -- "$json_file")" && pwd)
    if [ -f "${_ps_dir}/.env.libscript" ] && { [ -n "${OLLAMA_MODEL_LIST:-}" ] || grep -q '^OLLAMA_MODEL_LIST=' "${_ps_dir}/.env" "${_ps_dir}/.env.secrets" "${_ps_dir}/.env.libscript" 2>/dev/null || jq -e '.. | objects | has("OLLAMA_MODEL_LIST")' "$json_file" >/dev/null 2>&1; }; then
      if grep -qE '^OLLAMA_MODELS=(/|[A-Za-z]:[\\/])' "${_ps_dir}/.env.libscript" 2>/dev/null; then
        _tmp_ps_env=$(mktemp "${TMPDIR:-/tmp}/libscript_ps_env.XXXXXX")
        grep -vE '^OLLAMA_MODELS=(/|[A-Za-z]:[\\/])' "${_ps_dir}/.env.libscript" > "$_tmp_ps_env" 2>/dev/null || true
        cat "$_tmp_ps_env" > "${_ps_dir}/.env.libscript"
        rm -f "$_tmp_ps_env"
      fi
    fi
    _ol_ovr_dir=$(jq -r '.service_overrides.ollama.OLLAMA_MODELS_DIR // .service_overrides.ollama.OLLAMA_MODELS // .infrastructure.service_overrides.ollama.OLLAMA_MODELS_DIR // .infrastructure.service_overrides.ollama.OLLAMA_MODELS // empty' "$json_file" 2>/dev/null || true)
    if [ -n "$_ol_ovr_dir" ] && [ "$_ol_ovr_dir" != "null" ] && type libscript_expand_manifest_vars >/dev/null 2>&1; then
      _ol_ovr_dir=$(libscript_expand_manifest_vars "$_ol_ovr_dir")
    fi
    _has_ollama=$(jq -r 'if (.deps.ollama != null) or (.dependencies.ollama != null) or ([.dependencies.runtime[]? | select(.name == "ollama")] | length > 0) then "1" else "0" end' "$json_file" 2>/dev/null || printf '0')
    if [ "$_has_ollama" = "1" ] || [ -n "${_ol_ovr_dir:-}" ] || [ -n "${OLLAMA_MODELS_DIR:-}" ]; then
      _ol_models="${_ol_ovr_dir:-${OLLAMA_MODELS_DIR:-${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}/ollama_models}}"
      if [ -x "${LIBSCRIPT_ROOT_DIR:-.}/_lib/app-servers/ollama/service.sh" ]; then
        _ol_ovr_kvs=$(jq -r '((.infrastructure.service_overrides.ollama // {}) * (.service_overrides.ollama // {})) | to_entries[]? | "\(.key)=\(.value)"' "$json_file" 2>/dev/null || true)
        if [ -n "$_ol_ovr_kvs" ]; then
          OIFS_OL_OVR="$IFS"
          IFS='
'
          for _ol_kv in $_ol_ovr_kvs; do
            IFS="$OIFS_OL_OVR"
            _ol_k="${_ol_kv%%=*}"
            _ol_v="${_ol_kv#*=}"
            if type libscript_expand_manifest_vars >/dev/null 2>&1; then
              _ol_v=$(libscript_expand_manifest_vars "$_ol_v")
            fi
            case "$_ol_k" in
              OLLAMA_*|GGML_*)
                export "${_ol_k}=${_ol_v}"
                ;;
            esac
          done
          IFS="$OIFS_OL_OVR"
        fi
        printf '[DAEMON] Configuring ollama model storage at "%s" and restarting/reloading daemon if needed...\n' "$_ol_models"
        OLLAMA_MODELS_DIR="$_ol_models" OLLAMA_MODELS="$_ol_models" "${LIBSCRIPT_ROOT_DIR:-.}/_lib/app-servers/ollama/service.sh" configure || true
      fi
    fi
    _pg_ovr_dir=$(jq -r '.service_overrides.postgres.POSTGRES_DATA_DIR // .service_overrides.postgres.PGDATA // .service_overrides.postgresql.POSTGRES_DATA_DIR // .service_overrides.postgresql.PGDATA // .infrastructure.service_overrides.postgres.POSTGRES_DATA_DIR // .infrastructure.service_overrides.postgres.PGDATA // .infrastructure.service_overrides.postgresql.POSTGRES_DATA_DIR // .infrastructure.service_overrides.postgresql.PGDATA // .vars.POSTGRES_DATA_DIR // .vars.PGDATA // empty' "$json_file" 2>/dev/null || true)
    if [ -n "$_pg_ovr_dir" ] && [ "$_pg_ovr_dir" != "null" ] && type libscript_expand_manifest_vars >/dev/null 2>&1; then
      _pg_ovr_dir=$(libscript_expand_manifest_vars "$_pg_ovr_dir")
    fi
    _pg_target_dir="${_pg_ovr_dir:-${POSTGRES_DATA_DIR:-${PGDATA:-}}}"
    if [ -n "$_pg_target_dir" ] && [ -x "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/postgres/service.sh" ]; then
      printf '[DAEMON] Configuring PostgreSQL persistent storage at "%s"...\n' "$_pg_target_dir"
      POSTGRES_DATA_DIR="$_pg_target_dir" PGDATA="$_pg_target_dir" "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/postgres/service.sh" configure "$_pg_target_dir" || true
    fi
    _vk_ovr_dir=$(jq -r '.service_overrides.valkey.VALKEY_DATA_DIR // .service_overrides.valkey.REDIS_DATA_DIR // .service_overrides.redis.REDIS_DATA_DIR // .service_overrides.redis.VALKEY_DATA_DIR // .infrastructure.service_overrides.valkey.VALKEY_DATA_DIR // .infrastructure.service_overrides.valkey.REDIS_DATA_DIR // .infrastructure.service_overrides.redis.REDIS_DATA_DIR // .infrastructure.service_overrides.redis.VALKEY_DATA_DIR // .vars.VALKEY_DATA_DIR // .vars.REDIS_DATA_DIR // empty' "$json_file" 2>/dev/null || true)
    if [ -n "$_vk_ovr_dir" ] && [ "$_vk_ovr_dir" != "null" ] && type libscript_expand_manifest_vars >/dev/null 2>&1; then
      _vk_ovr_dir=$(libscript_expand_manifest_vars "$_vk_ovr_dir")
    fi
    _vk_target_dir="${_vk_ovr_dir:-${VALKEY_DATA_DIR:-${REDIS_DATA_DIR:-}}}"
    if [ -n "$_vk_target_dir" ] && [ -x "${LIBSCRIPT_ROOT_DIR:-.}/_lib/caches/valkey/service.sh" ]; then
      printf '[DAEMON] Configuring Valkey/Redis persistent storage at "%s"...\n' "$_vk_target_dir"
      VALKEY_DATA_DIR="$_vk_target_dir" REDIS_DATA_DIR="$_vk_target_dir" "${LIBSCRIPT_ROOT_DIR:-.}/_lib/caches/valkey/service.sh" configure "$_vk_target_dir" || true
    fi
    _ps_cert_store=$(jq -r '.ingress.cert_store_dir // empty' "$json_file" 2>/dev/null || true)
    if [ -n "$_ps_cert_store" ] && [ "$_ps_cert_store" != "null" ] && type libscript_expand_manifest_vars >/dev/null 2>&1; then
      _ps_cert_store=$(libscript_expand_manifest_vars "$_ps_cert_store")
    fi
    if [ -z "$_ps_cert_store" ] || [ "$_ps_cert_store" = "null" ]; then
      _ps_cert_store="${CERT_STORE_DIR:-${_ps_def_mount}/certs}"
    fi
    mkdir -p "${_ps_cert_store}/live" "${_ps_cert_store}/letsencrypt" "${_ps_cert_store}/acme-webroot/.well-known/acme-challenge" 2>/dev/null || \
      sudo -n mkdir -p "${_ps_cert_store}/live" "${_ps_cert_store}/letsencrypt" "${_ps_cert_store}/acme-webroot/.well-known/acme-challenge" 2>/dev/null || true
    chmod -R 0755 "${_ps_cert_store}/acme-webroot" 2>/dev/null || sudo -n chmod -R 0755 "${_ps_cert_store}/acme-webroot" 2>/dev/null || true
    _ps_le_etc="${LETSENCRYPT_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/letsencrypt}"
    if [ -d "${_ps_cert_store}/letsencrypt" ]; then
      for _ps_le_sub in accounts archive renewal; do
        if [ -d "${_ps_cert_store}/letsencrypt/${_ps_le_sub}" ] && [ ! -d "${_ps_le_etc}/${_ps_le_sub}" ]; then
          mkdir -p "$_ps_le_etc" 2>/dev/null || sudo -n mkdir -p "$_ps_le_etc" 2>/dev/null || true
          cp -a "${_ps_cert_store}/letsencrypt/${_ps_le_sub}" "${_ps_le_etc}/" 2>/dev/null || sudo -n cp -a "${_ps_cert_store}/letsencrypt/${_ps_le_sub}" "${_ps_le_etc}/" 2>/dev/null || true
        fi
      done
    fi
    if [ -d "${_ps_cert_store}/live" ]; then
      for _ps_dom_dir in "${_ps_cert_store}/live"/*; do
        [ -d "$_ps_dom_dir" ] || continue
        _ps_dom=$(basename "$_ps_dom_dir")
        if [ -s "${_ps_dom_dir}/fullchain.pem" ] && [ -s "${_ps_dom_dir}/privkey.pem" ]; then
          _ps_valid=1
          if command -v openssl >/dev/null 2>&1; then
            _ps_iss=$(openssl x509 -noout -issuer -in "${_ps_dom_dir}/fullchain.pem" 2>/dev/null || true)
            _ps_sub=$(openssl x509 -noout -subject -in "${_ps_dom_dir}/fullchain.pem" 2>/dev/null || true)
            if [ -z "$_ps_iss" ] || [ "${_ps_iss#*=}" = "${_ps_sub#*=}" ] || ! openssl x509 -checkend "${LETSENCRYPT_RENEW_BEFORE_SECONDS:-0}" -noout -in "${_ps_dom_dir}/fullchain.pem" >/dev/null 2>&1; then
              _ps_valid=0
            fi
          fi
          if [ "$_ps_valid" -eq 1 ]; then
            chmod 0755 "$_ps_dom_dir" 2>/dev/null || sudo -n chmod 0755 "$_ps_dom_dir" 2>/dev/null || true
            for _ps_cf in fullchain.pem cert.pem chain.pem; do
              if [ -f "${_ps_dom_dir}/${_ps_cf}" ]; then
                chmod 0444 "${_ps_dom_dir}/${_ps_cf}" 2>/dev/null || sudo -n chmod 0444 "${_ps_dom_dir}/${_ps_cf}" 2>/dev/null || true
              fi
            done
            chmod 0400 "${_ps_dom_dir}/privkey.pem" 2>/dev/null || sudo -n chmod 0400 "${_ps_dom_dir}/privkey.pem" 2>/dev/null || true
            chmod 0555 "$_ps_dom_dir" 2>/dev/null || sudo -n chmod 0555 "$_ps_dom_dir" 2>/dev/null || true
            mkdir -p "${_ps_le_etc}/live/${_ps_dom}" 2>/dev/null || sudo -n mkdir -p "${_ps_le_etc}/live/${_ps_dom}" 2>/dev/null || true
            for _ps_cf in fullchain.pem privkey.pem cert.pem chain.pem; do
              if [ -f "${_ps_dom_dir}/${_ps_cf}" ]; then
                cp -f "${_ps_dom_dir}/${_ps_cf}" "${_ps_le_etc}/live/${_ps_dom}/${_ps_cf}" 2>/dev/null || sudo -n cp -f "${_ps_dom_dir}/${_ps_cf}" "${_ps_le_etc}/live/${_ps_dom}/${_ps_cf}" 2>/dev/null || true
              fi
            done
            printf '[STORAGE] [TLS] Restored valid non-expired Let'\''s Encrypt certificate for "%s" from "%s".\n' "$_ps_dom" "$_ps_dom_dir"
          fi
        fi
      done
    fi
  fi
  exit 0
fi

if [ "$CMD" = "start" ] || [ "$CMD" = "stop" ] || [ "$CMD" = "status" ] || [ "$CMD" = "health" ] || [ "$CMD" = "logs" ] || [ "$CMD" = "restart" ] || [ "$CMD" = "up" ] || [ "$CMD" = "down" ] || [ "$CMD" = "uninstall-service" ]; then
  action="$CMD"
  if [ "$action" = "up" ]; then action="start"; fi
  if [ "$action" = "down" ]; then action="stop"; fi
  if [ "$action" = "uninstall-service" ]; then action="uninstall"; fi

  # ## perform_health_check
  # Executes runtime health checks for the given package and version by delegating to component scripts.
  perform_health_check() {
    _pkg="$1"
    _ver="$2"

    for _comp_dir in "${LIBSCRIPT_ROOT_DIR:-.}"/_lib/*/"$_pkg"; do
      if [ -f "${_comp_dir}/env.sh" ]; then
        SCRIPT_NAME="${_comp_dir}/env.sh"
        # shellcheck disable=SC1090
        . "$SCRIPT_NAME" >/dev/null 2>&1 || true
        unset SCRIPT_NAME || true
      fi
    done

    case "$_pkg" in
        postgres|postgresql)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            if command -v pg_isready >/dev/null 2>&1; then
              pg_isready >/dev/null 2>&1
            elif command -v psql >/dev/null 2>&1; then
              psql -U postgres -c 'SELECT 1;' >/dev/null 2>&1 || su - postgres -c "psql -c 'SELECT 1;'" >/dev/null 2>&1
            fi
            ;;
        mariadb|mysql)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            if command -v mysql >/dev/null 2>&1; then
              mysql -u root -e 'SELECT 1;' >/dev/null 2>&1
            fi
            ;;
        mongodb)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            mongosh --eval 'db.runCommand({ ping: 1 })' >/dev/null 2>&1 || mongo --eval 'db.runCommand({ ping: 1 })' >/dev/null 2>&1
            ;;
        etcd)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            etcdctl version >/dev/null 2>&1
            ;;
        valkey|redis)
            if command -v valkey-cli >/dev/null 2>&1 && valkey-cli ping 2>/dev/null | grep -qi "PONG"; then
              true
            elif command -v redis-cli >/dev/null 2>&1 && redis-cli ping 2>/dev/null | grep -qi "PONG"; then
              true
            else
              "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            fi
            ;;
        nginx|ollama)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            ;;
        *)
            _hc_handled=0
            for _comp_dir in "${LIBSCRIPT_ROOT_DIR:-.}"/_lib/*/"$_pkg"; do
              if [ -f "${_comp_dir}/test.sh" ]; then
                sh "${_comp_dir}/test.sh" >/dev/null 2>&1 || true
                _hc_handled=1
                break
              fi
            done
            if [ "$_hc_handled" -eq 0 ]; then
              "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver" || true
              if command -v "$_pkg" >/dev/null 2>&1; then
                "$_pkg" --version || true
              fi
            fi
            ;;
    esac
  }

  # ## normalize_service_data_ownership
  # Ensures data directories and DuckDB files are owned by the configured service user before daemon startup.
  normalize_service_data_ownership() {
    _nsd_json="$1"
    _nsd_dir=$(cd -- "$(dirname -- "$_nsd_json")" && pwd)
    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
      # shellcheck disable=SC1090,SC1091
      . "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
      unset SCRIPT_NAME || true
      libscript_hydrate_manifest_env "$_nsd_json" || true
    fi
    _nsd_user=$(jq -r '((.services // .infrastructure.services) | if type == "object" then [to_entries[].value] elif type == "array" then . else [] end) | .[0].user // empty' "$_nsd_json" 2>/dev/null || true)
    if type libscript_expand_manifest_vars >/dev/null 2>&1; then
      _nsd_user=$(libscript_expand_manifest_vars "$_nsd_user")
    fi
    if [ -z "$_nsd_user" ]; then
      _nsd_user="${SERVICE_USER:-${REMOTE_USER:-${SUDO_USER:-}}}"
    fi
    if [ -n "$_nsd_user" ] && id "$_nsd_user" >/dev/null 2>&1; then
      _nsd_group="${SERVICE_GROUP:-${REMOTE_GROUP:-$_nsd_user}}"
      for _nsd_ef in "${_nsd_dir}/.env.libscript" "${_nsd_dir}/.env" "${_nsd_dir}/.env.secrets"; do
        if [ -f "$_nsd_ef" ]; then
          chown "${_nsd_user}:${_nsd_group}" "$_nsd_ef" 2>/dev/null || sudo -n chown "${_nsd_user}:${_nsd_group}" "$_nsd_ef" 2>/dev/null || true
          chmod 0644 "$_nsd_ef" 2>/dev/null || sudo -n chmod 0644 "$_nsd_ef" 2>/dev/null || true
        fi
      done
      for _nsd_target in "${DATA_DISK_MOUNT:-/mnt/data}" "${DATA_MOUNT_DIR:-/mnt/data}" "${TMP_DATA_DIR:-/tmp/data}" "${_nsd_dir}/data"; do
        if [ -n "$_nsd_target" ] && [ -d "$_nsd_target" ]; then
          chown "${_nsd_user}:${_nsd_group}" "$_nsd_target" 2>/dev/null || sudo -n chown "${_nsd_user}:${_nsd_group}" "$_nsd_target" 2>/dev/null || true
          chmod 0755 "$_nsd_target" 2>/dev/null || sudo -n chmod 0755 "$_nsd_target" 2>/dev/null || true
          for _nsd_sub in "${_nsd_target}"/* "${_nsd_target}"/.[!.]* "${_nsd_target}"/..*; do
            [ -e "$_nsd_sub" ] || continue
            case "${_nsd_sub##*/}" in
              ollama_models|postgres|postgresql|valkey|redis|certs|lost+found) continue ;;
            esac
            chown -R "${_nsd_user}:${_nsd_group}" "$_nsd_sub" 2>/dev/null || sudo -n chown -R "${_nsd_user}:${_nsd_group}" "$_nsd_sub" 2>/dev/null || true
            chmod -R u+rwX,go+rX "$_nsd_sub" 2>/dev/null || sudo -n chmod -R u+rwX,go+rX "$_nsd_sub" 2>/dev/null || true
          done
          if id ollama >/dev/null 2>&1 && [ -d "${_nsd_target}/ollama_models" ]; then
            usermod -aG ollama "$_nsd_user" 2>/dev/null || sudo -n usermod -aG ollama "$_nsd_user" 2>/dev/null || true
            usermod -aG "$_nsd_group" ollama 2>/dev/null || sudo -n usermod -aG "$_nsd_group" ollama 2>/dev/null || true
            chown -R ollama:ollama "${_nsd_target}/ollama_models" 2>/dev/null || sudo -n chown -R ollama:ollama "${_nsd_target}/ollama_models" 2>/dev/null || true
            chmod 02775 "${_nsd_target}/ollama_models" 2>/dev/null || sudo -n chmod 02775 "${_nsd_target}/ollama_models" 2>/dev/null || true
            chmod -R u+rwX,g+rwXs,o+rX "${_nsd_target}/ollama_models" 2>/dev/null || sudo -n chmod -R u+rwX,g+rwXs,o+rX "${_nsd_target}/ollama_models" 2>/dev/null || true
          fi
          if id postgres >/dev/null 2>&1 && [ -d "${_nsd_target}/postgres" ]; then
            chown -R postgres:postgres "${_nsd_target}/postgres" 2>/dev/null || sudo -n chown -R postgres:postgres "${_nsd_target}/postgres" 2>/dev/null || true
            chmod 0700 "${_nsd_target}/postgres" 2>/dev/null || sudo -n chmod 0700 "${_nsd_target}/postgres" 2>/dev/null || true
          fi
          if [ -d "${_nsd_target}/valkey" ]; then
            if id valkey >/dev/null 2>&1; then
              chown -R valkey:valkey "${_nsd_target}/valkey" 2>/dev/null || sudo -n chown -R valkey:valkey "${_nsd_target}/valkey" 2>/dev/null || true
            elif id redis >/dev/null 2>&1; then
              chown -R redis:redis "${_nsd_target}/valkey" 2>/dev/null || sudo -n chown -R redis:redis "${_nsd_target}/valkey" 2>/dev/null || true
            fi
            chmod 0750 "${_nsd_target}/valkey" 2>/dev/null || sudo -n chmod 0750 "${_nsd_target}/valkey" 2>/dev/null || true
          fi
        fi
      done
      if id ollama >/dev/null 2>&1; then
        for _nsd_ol_dir in "${OLLAMA_MODELS_DIR:-${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}/ollama_models}" "${OLLAMA_MODELS:-}"; do
          case "$_nsd_ol_dir" in
            /*) ;;
            *) continue ;;
          esac
          if [ -d "$_nsd_ol_dir" ]; then
            mkdir -p "${_nsd_ol_dir}/manifests" "${_nsd_ol_dir}/blobs" 2>/dev/null || sudo -n mkdir -p "${_nsd_ol_dir}/manifests" "${_nsd_ol_dir}/blobs" 2>/dev/null || true
            chown -R ollama:ollama "$_nsd_ol_dir" 2>/dev/null || sudo -n chown -R ollama:ollama "$_nsd_ol_dir" 2>/dev/null || true
            chmod 02775 "$_nsd_ol_dir" "${_nsd_ol_dir}/manifests" "${_nsd_ol_dir}/blobs" 2>/dev/null || sudo -n chmod 02775 "$_nsd_ol_dir" "${_nsd_ol_dir}/manifests" "${_nsd_ol_dir}/blobs" 2>/dev/null || true
            chmod -R u+rwX,g+rwXs,o+rX "$_nsd_ol_dir" 2>/dev/null || sudo -n chmod -R u+rwX,g+rwXs,o+rX "$_nsd_ol_dir" 2>/dev/null || true
          fi
        done
      fi
    fi
  }

  # ## check_manifest_health_once
  # Runs database, daemon, and hook health checks once and returns 0 if all succeed.
  check_manifest_health_once() {
    _cmh_json="$1"
    shift
    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/health_db.sh" ]; then
      if ! "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/health_db.sh" "$_cmh_json" "$@"; then
        return 1
      fi
    fi
    if ! "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "health" "$_cmh_json" "$@"; then
      return 1
    fi
    if [ "$skip_hooks" -eq 0 ]; then
      if ! "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$_cmh_json" "health"; then
        return 1
      fi
      _cmh_models="${OLLAMA_MODEL_LIST:-${OLLAMA_DEFAULT_MODEL:-}}"
      if [ -n "$_cmh_models" ] && command -v ollama >/dev/null 2>&1; then
        _cmh_installed=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' || true)
        for _cmh_m in $(printf '%s\n' "$_cmh_models" | tr ',' ' '); do
          [ -n "$_cmh_m" ] || continue
          _cmh_alt="$_cmh_m"
          case "$_cmh_m" in *:*) ;; *) _cmh_alt="${_cmh_m}:latest" ;; esac
          if ! printf '%s\n' "$_cmh_installed" | grep -Fxq "$_cmh_m" && ! printf '%s\n' "$_cmh_installed" | grep -Fxq "$_cmh_alt"; then
            printf '[ERROR] Health check failed: configured Ollama model "%s" is not present in ollama list.\n' "$_cmh_m" >&2
            return 1
          fi
        done
      fi
    fi
    return 0
  }

  follow_logs=0
  skip_hooks=0
  skip_db_init="${LIBSCRIPT_SKIP_DB_INIT:-0}"
  remove_service=0
  purge_data=0
  remediate=0
  verify_ingress=0
  public_url=""
  _orig_argc=$#
  _arg_idx=0
  while [ "$_arg_idx" -lt "$_orig_argc" ]; do
    _cur_arg="$1"
    shift
    case "$_cur_arg" in
      -f|--follow) follow_logs=1 ;;
      --no-hooks) skip_hooks=1 ;;
      --skip-db-init|--skip-migrate) skip_db_init=1 ;;
      --remove|--uninstall) remove_service=1 ;;
      --purge-data) purge_data=1 ;;
      --remediate) remediate=1 ;;
      --verify-ingress) verify_ingress=1 ;;
      --public-url=*) public_url="${_cur_arg#*=}"; verify_ingress=1 ;;
      *) set -- "$@" "$_cur_arg" ;;
    esac
    _arg_idx=$((_arg_idx + 1))
  done

  if [ "$action" = "stop" ] && [ "$remove_service" -eq 1 ]; then
    action='uninstall'
  fi

  if [ $# -eq 0 ] || [ "$1" = "libscript.json" ] || [ "${1##*.}" = "json" ]; then
    json_file="${1:-libscript.json}"
    if [ ! -f "$json_file" ]; then
      printf '%s\n' "Error: $json_file not found." >&2
      exit 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
      if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/utilities/jq/setup.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/utilities/jq/setup.sh"
      fi
    fi
    if ! command -v jq >/dev/null 2>&1; then
      printf '%s\n' "Error: jq is required to parse $json_file." >&2
      exit 1
    fi

    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
      # shellcheck disable=SC1090,SC1091
      . "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
      unset SCRIPT_NAME || true
      libscript_hydrate_manifest_env "$json_file" || true
    fi

    if [ "$skip_hooks" -eq 0 ]; then
      if [ "$action" = "start" ] || [ "$action" = "up" ]; then
        if [ "$skip_db_init" -eq 0 ]; then
          "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "build"
        fi
      elif [ "$action" = "stop" ] || [ "$action" = "down" ] || [ "$action" = "uninstall" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "pre_stop" || true
      fi
    fi

    if [ "$action" != "uninstall" ]; then
      unset SCRIPT_NAME || true
      deps=$("${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/resolve_stack.sh" "$json_file" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null || true)
      if [ -n "$deps" ]; then
        printf '%s\n' "$deps" > "$json_file.tmpdeps"
        while read -r pkg ver; do
          if [ -n "$pkg" ]; then
            if [ "$ver" = "null" ]; then ver="latest"; fi
            if [ "$action" = "logs" ] && [ "$follow_logs" = "1" ]; then
              "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "$ver" -f 2>&1 | awk -v prefix="$pkg" '{print "\033[36m" prefix " |\033[0m " $0; fflush()}' &
            elif [ "$action" = "health" ]; then
              printf '%s\n' "=== $pkg ==="
              perform_health_check "$pkg" "$ver"
            elif [ "$action" = "status" ] || [ "$action" = "logs" ]; then
              printf '%s\n' "=== $pkg ==="
              "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "$ver"
            elif [ "$action" = "start" ] || [ "$action" = "up" ]; then
              case "$pkg" in
                postgres|postgresql|mariadb|mysql|valkey|redis|mongodb|etcd)
                  "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "$ver"
                  ;;
                python|nodejs|uv|duckdb|sqlite|certbot|ruby|java|csharp|go|rust|php|elixir|swift|zig|deno|bun|c|cc|cpp|sh|bazel|cmake|coursier|gradle|huggingface-cli|just|maven|xpk)
                  ;;
                *)
                  "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "$ver" &
                  ;;
              esac
            else
              case "$pkg" in
                python|nodejs|uv|duckdb|sqlite|certbot|ruby|java|csharp|go|rust|php|elixir|swift|zig|deno|bun|c|cc|cpp|sh|bazel|cmake|coursier|gradle|huggingface-cli|just|maven|xpk)
                  ;;
                *)
                  "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "$ver" &
                  ;;
              esac
            fi
          fi
        done < "$json_file.tmpdeps"
        rm -f "$json_file.tmpdeps"
      fi
    fi

    if [ "$action" = "start" ] || [ "$action" = "up" ]; then
      if [ "$skip_hooks" -eq 0 ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "stop" "$json_file" >/dev/null 2>&1 || true
        if [ "$skip_db_init" -eq 0 ]; then
          if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/provision_db.sh" ]; then
            "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/provision_db.sh" "$json_file"
          fi
          "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "db_migrate"
        fi
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "pre_start"
      fi
      normalize_service_data_ownership "$json_file"
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "$action" "$json_file"
      if [ "$skip_db_init" -eq 0 ] && jq -e '.ingress != null' "$json_file" >/dev/null 2>&1; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/component_core.sh" --synchronize-ingress "$json_file" --reload || true
      fi
      if [ "$skip_hooks" -eq 0 ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "post_start"
      fi
    elif [ "$action" = "stop" ] || [ "$action" = "down" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "$action" "$json_file"
      if [ "$purge_data" -eq 1 ] && [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/deprovision_db.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/deprovision_db.sh" "$json_file"
      fi
      if [ "$skip_hooks" -eq 0 ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "post_stop"
      fi
    elif [ "$action" = "uninstall" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "uninstall" "$json_file"
      if jq -e '.ingress != null' "$json_file" >/dev/null 2>&1; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/networking/netctl/cli.sh" remove-ingress "$json_file" --reload || true
      fi
      if [ "$purge_data" -eq 1 ] && [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/deprovision_db.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/deprovision_db.sh" "$json_file"
      fi
      if [ "$skip_hooks" -eq 0 ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "post_stop" || true
      fi
    elif [ "$action" = "health" ]; then
      set --
      [ "$verify_ingress" -eq 1 ] && set -- "$@" "--verify-ingress"
      [ -n "$public_url" ] && set -- "$@" "--public-url=${public_url}"
      if ! check_manifest_health_once "$json_file" "$@"; then
        if [ "$remediate" -eq 1 ]; then
          printf '[INFO] Health check failed for %s; running auto-remediation...\n' "$json_file"
          "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "stop" "$json_file" >/dev/null 2>&1 || true
          if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/provision_db.sh" ]; then
            LIBSCRIPT_FORCE_SEED=1 "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/provision_db.sh" "$json_file"
          fi
          "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "db_migrate" || true
          "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "pre_start" || true
          normalize_service_data_ownership "$json_file"
          "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "start" "$json_file"
          if jq -e '.ingress != null' "$json_file" >/dev/null 2>&1; then
            "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/component_core.sh" --synchronize-ingress "$json_file" --reload || true
          fi
          check_manifest_health_once "$json_file" "$@"
        else
          exit 1
        fi
      fi
    elif [ "$action" = "status" ] || [ "$action" = "logs" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "$action" "$json_file"
    elif [ "$action" = "restart" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "stop" "$json_file"
      normalize_service_data_ownership "$json_file"
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "start" "$json_file"
      if jq -e '.ingress != null' "$json_file" >/dev/null 2>&1; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/component_core.sh" --synchronize-ingress "$json_file" --reload || true
      fi
    fi

    wait
    exit 0
  else
    for pkg in "$@"; do
      if [ "$action" = "logs" ] && [ "$follow_logs" = "1" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "latest" -f 2>&1 | awk -v prefix="$pkg" '{print "\033[36m" prefix " |\033[0m " $0; fflush()}' &
      elif [ "$action" = "health" ]; then
        printf '%s\n' "=== $pkg ==="
        perform_health_check "$pkg" "latest"
      elif [ "$action" = "status" ] || [ "$action" = "logs" ]; then
        printf '%s\n' "=== $pkg ==="
        "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "latest"
      else
        "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "latest" &
      fi
    done
    wait
    exit 0
  fi
fi
