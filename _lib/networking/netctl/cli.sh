#!/bin/sh
# ## Overview
# Network control utility for managing local services, reverse proxies, SPAs, WebSockets, and declarative ingress.
#
# ## Usage
# Execute this script to manage networking configurations or apply a libscript.json ingress definition.

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
NETCTL_DIR="${SCRIPT_DIR}"
export LIBSCRIPT_ROOT_DIR NETCTL_DIR

for LIB in "_lib/_common/log.sh" "_lib/_common/priv.sh" "_lib/networking/netctl/lib/prelude.sh" "_lib/networking/netctl/lib/state.sh" "_lib/networking/netctl/lib/nginx.sh" "_lib/networking/netctl/lib/caddy.sh" "_lib/networking/netctl/lib/apache.sh" "_lib/networking/netctl/lib/traefik.sh" "_lib/networking/netctl/lib/vagrantfile.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  if [ -f "${SCRIPT_NAME}" ]; then
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
done
unset SCRIPT_NAME || true
if ! command -v jq >/dev/null 2>&1 && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
  _nc_saved_this="${THIS_FILE}"
  _nc_saved_dir="${SCRIPT_DIR}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  THIS_FILE="${_nc_saved_this}"
  SCRIPT_DIR="${_nc_saved_dir}"
fi

# ## usage
# Displays command-line usage instructions and exit status 1.
usage() {
  cat <<EOF
netctl - Singular and Additive network config generator

Usage:
  netctl [COMMAND] [ARGS...]
  netctl [OPTIONS...]

Commands:
  init                           Initialize .netctl.json
  domain <server_name>           Set domain / server_name
  tls <mode>                     Set TLS mode (letsencrypt, self-signed)
  cert-store-dir <dir>           Set persistent certificate store directory
  acme-webroot <dir>             Set ACME HTTP-01 challenge webroot directory
  ensure-cert <domain> [store]   Ensure valid non-expired Let's Encrypt certificate
  listen <port>                  Add a listening port
  static <path> <target>         Add a static file route
  spa <path> <target>            Add a Single-Page Application static route with index.html fallback
  proxy <path> <target>          Add a reverse proxy route
  ws <path> <target>             Add a WebSocket reverse proxy route
  rewrite <path> <pattern>       Add a rewrite rule
  apply <libscript.json>         Generate and optionally reload reverse proxy from .ingress block
  emit <format>                  Emit the configuration for a given format
                                 Formats: nginx, caddy, apache, dockerfile, vagrantfile

Options (Singular mode):
  --domain <server_name>         Set domain / server_name
  --tls <mode>                   Set TLS mode (letsencrypt, self-signed)
  --cert-store-dir <dir>         Set persistent certificate store directory
  --acme-webroot <dir>           Set ACME HTTP-01 challenge webroot directory
  --proxy-connect-timeout <val>  Set upstream proxy connect timeout (e.g., 60s)
  --proxy-send-timeout <val>     Set upstream proxy send timeout (e.g., 300s)
  --proxy-read-timeout <val>     Set upstream proxy read timeout (e.g., 300s)
  --proxy-buffering <on|off>     Set upstream proxy response buffering (on|off)
  --listen <port>                Add a listening port
  --static <path> <target>       Add a static route
  --spa <path> <target>          Add a SPA static route
  --proxy <path> <target>        Add a proxy route
  --ws <path> <target>           Add a WebSocket proxy route
  --rewrite <path> <pattern>     Add a rewrite rule
  --emit <format>                Emit to specified format and exit
EOF
  exit 1
}

# ## netctl_restore_persisted_cert
# Restores a valid, non-expired CA-signed certificate from the persistent store and enforces read-only permissions.
netctl_restore_persisted_cert() {
  _rpc_dom="$1"
  _rpc_store="${2:-${CERT_STORE_DIR:-${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}/certs}}"
  _rpc_live="${_rpc_store}/live/${_rpc_dom}"
  _rpc_cert="${_rpc_live}/fullchain.pem"
  _rpc_key="${_rpc_live}/privkey.pem"

  if ! netctl_cert_is_valid_letsencrypt "$_rpc_dom" "$_rpc_cert" "$_rpc_key"; then
    return 1
  fi

  chmod 0755 "$_rpc_live" 2>/dev/null || priv chmod 0755 "$_rpc_live" 2>/dev/null || true
  for _rpc_f in fullchain.pem cert.pem chain.pem; do
    if [ -f "${_rpc_live}/${_rpc_f}" ]; then
      chmod 0444 "${_rpc_live}/${_rpc_f}" 2>/dev/null || priv chmod 0444 "${_rpc_live}/${_rpc_f}" 2>/dev/null || true
    fi
  done
  if [ -f "$_rpc_key" ]; then
    chmod 0400 "$_rpc_key" 2>/dev/null || priv chmod 0400 "$_rpc_key" 2>/dev/null || true
  fi
  chmod 0555 "$_rpc_live" 2>/dev/null || priv chmod 0555 "$_rpc_live" 2>/dev/null || true

  _le_etc="${LETSENCRYPT_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/letsencrypt}"
  _ngx_etc="${NGINX_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/nginx}"

  if [ -d "${_rpc_store}/letsencrypt" ]; then
    for _rpc_sub in accounts archive renewal; do
      if [ -d "${_rpc_store}/letsencrypt/${_rpc_sub}" ] && [ ! -d "${_le_etc}/${_rpc_sub}" ]; then
        mkdir -p "${_le_etc}" 2>/dev/null || priv mkdir -p "${_le_etc}" 2>/dev/null || true
        cp -a "${_rpc_store}/letsencrypt/${_rpc_sub}" "${_le_etc}/" 2>/dev/null || priv cp -a "${_rpc_store}/letsencrypt/${_rpc_sub}" "${_le_etc}/" 2>/dev/null || true
      fi
    done
  fi

  if [ -w "${_le_etc}" ] || [ -d "${_le_etc}" ] || [ "$(id -u 2>/dev/null || printf '1')" = "0" ]; then
    mkdir -p "${_le_etc}/live/${_rpc_dom}" 2>/dev/null || priv mkdir -p "${_le_etc}/live/${_rpc_dom}" 2>/dev/null || true
    if [ -d "${_le_etc}/live/${_rpc_dom}" ]; then
      for _rpc_f in fullchain.pem privkey.pem cert.pem chain.pem; do
        if [ -f "${_rpc_live}/${_rpc_f}" ] && [ "${_rpc_live}/${_rpc_f}" != "${_le_etc}/live/${_rpc_dom}/${_rpc_f}" ]; then
          cp -f "${_rpc_live}/${_rpc_f}" "${_le_etc}/live/${_rpc_dom}/${_rpc_f}" 2>/dev/null || priv cp -f "${_rpc_live}/${_rpc_f}" "${_le_etc}/live/${_rpc_dom}/${_rpc_f}" 2>/dev/null || true
        fi
      done
      chmod 0400 "${_le_etc}/live/${_rpc_dom}/privkey.pem" 2>/dev/null || priv chmod 0400 "${_le_etc}/live/${_rpc_dom}/privkey.pem" 2>/dev/null || true
    fi
  fi

  if [ -f "${_ngx_etc}/ssl/${_rpc_dom}.crt" ] || [ -f "${_ngx_etc}/ssl/${_rpc_dom}.key" ]; then
    rm -f "${_ngx_etc}/ssl/${_rpc_dom}.crt" "${_ngx_etc}/ssl/${_rpc_dom}.key" 2>/dev/null || priv rm -f "${_ngx_etc}/ssl/${_rpc_dom}.crt" "${_ngx_etc}/ssl/${_rpc_dom}.key" 2>/dev/null || true
  fi

  log_info "[REUSE] [TLS] Reusing valid non-expired Let's Encrypt certificate for '${_rpc_dom}' from read-only store '${_rpc_live}'."
  return 0
}

# ## netctl_persist_cert_readonly
# Copies issued Let's Encrypt certificates into the persistent store and locks files and directories to read-only permissions.
netctl_persist_cert_readonly() {
  _pcr_dom="$1"
  _pcr_store="${2:-${CERT_STORE_DIR:-${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}/certs}}"
  _pcr_le_etc="${LETSENCRYPT_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/letsencrypt}"
  _pcr_src="${3:-${_pcr_le_etc}/live/${_pcr_dom}}"
  _pcr_dst="${_pcr_store}/live/${_pcr_dom}"

  if [ -d "$_pcr_dst" ]; then
    chmod 0755 "$_pcr_dst" 2>/dev/null || priv chmod 0755 "$_pcr_dst" 2>/dev/null || true
    for _pcr_f in fullchain.pem privkey.pem cert.pem chain.pem; do
      if [ -f "${_pcr_dst}/${_pcr_f}" ]; then
        chmod 0600 "${_pcr_dst}/${_pcr_f}" 2>/dev/null || priv chmod 0600 "${_pcr_dst}/${_pcr_f}" 2>/dev/null || true
      fi
    done
  else
    mkdir -p "$_pcr_dst" 2>/dev/null || priv mkdir -p "$_pcr_dst" 2>/dev/null || true
  fi

  if [ -d "$_pcr_src" ] && [ "$_pcr_src" != "$_pcr_dst" ]; then
    for _pcr_f in fullchain.pem privkey.pem cert.pem chain.pem; do
      if [ -f "${_pcr_src}/${_pcr_f}" ]; then
        cp -L -f "${_pcr_src}/${_pcr_f}" "${_pcr_dst}/${_pcr_f}" 2>/dev/null || priv cp -L -f "${_pcr_src}/${_pcr_f}" "${_pcr_dst}/${_pcr_f}" 2>/dev/null || true
      fi
    done
  fi

  if [ -d "$_pcr_le_etc" ]; then
    mkdir -p "${_pcr_store}/letsencrypt" 2>/dev/null || priv mkdir -p "${_pcr_store}/letsencrypt" 2>/dev/null || true
    for _pcr_sub in accounts archive renewal; do
      if [ -d "${_pcr_le_etc}/${_pcr_sub}" ]; then
        cp -a "${_pcr_le_etc}/${_pcr_sub}" "${_pcr_store}/letsencrypt/" 2>/dev/null || priv cp -a "${_pcr_le_etc}/${_pcr_sub}" "${_pcr_store}/letsencrypt/" 2>/dev/null || true
      fi
    done
  fi

  chown -R root:root "$_pcr_dst" 2>/dev/null || priv chown -R root:root "$_pcr_dst" 2>/dev/null || true
  for _pcr_f in fullchain.pem cert.pem chain.pem; do
    if [ -f "${_pcr_dst}/${_pcr_f}" ]; then
      chmod 0444 "${_pcr_dst}/${_pcr_f}" 2>/dev/null || priv chmod 0444 "${_pcr_dst}/${_pcr_f}" 2>/dev/null || true
    fi
  done
  if [ -f "${_pcr_dst}/privkey.pem" ]; then
    chmod 0400 "${_pcr_dst}/privkey.pem" 2>/dev/null || priv chmod 0400 "${_pcr_dst}/privkey.pem" 2>/dev/null || true
  fi
  chmod 0555 "$_pcr_dst" 2>/dev/null || priv chmod 0555 "$_pcr_dst" 2>/dev/null || true
  log_info "[PERSIST] [TLS] Stored read-only Let's Encrypt certificate for '${_pcr_dom}' in '${_pcr_dst}'."
}

# ## netctl_install_nginx_vhost
# Installs an emitted Nginx configuration file into /etc/nginx/conf.d and reloads Nginx.
netctl_install_nginx_vhost() {
  _inv_dom="$1"
  _inv_out="$2"
  _inv_ngx_etc="${NGINX_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/nginx}"
  if command -v nginx >/dev/null 2>&1 && [ -d "${_inv_ngx_etc}/conf.d" ]; then
    if [ -n "$_inv_dom" ] && [ "$_inv_dom" != "_" ]; then
      _inv_dest="${_inv_ngx_etc}/conf.d/${_inv_dom}.conf"
    else
      _inv_dest="${_inv_ngx_etc}/conf.d/libscript_ingress.conf"
    fi
    if [ -f "$_inv_dest" ] && cmp -s "$_inv_out" "$_inv_dest" 2>/dev/null; then
      log_info "[ROUTES] [CONFIRM] nginx virtual host config ${_inv_dest} is up-to-date."
    elif [ -w "${_inv_ngx_etc}/conf.d" ]; then
      rm -f "${_inv_ngx_etc}/conf.d/libscript_ingress.conf" "${_inv_ngx_etc}/sites-enabled/default" 2>/dev/null || true
      cp "$_inv_out" "$_inv_dest"
      if [ -d "${_inv_ngx_etc}/sites-available" ] && [ -n "$_inv_dom" ] && [ "$_inv_dom" != "_" ]; then
        cp "$_inv_out" "${_inv_ngx_etc}/sites-available/${_inv_dom}.conf" 2>/dev/null || true
      fi
      log_info "[ROUTES] [WRITE] Installed nginx virtual host config -> ${_inv_dest}"
    else
      priv rm -f "${_inv_ngx_etc}/conf.d/libscript_ingress.conf" "${_inv_ngx_etc}/sites-enabled/default" 2>/dev/null || true
      priv cp "$_inv_out" "$_inv_dest" 2>/dev/null || true
      if [ -d "${_inv_ngx_etc}/sites-available" ] && [ -n "$_inv_dom" ] && [ "$_inv_dom" != "_" ]; then
        priv cp "$_inv_out" "${_inv_ngx_etc}/sites-available/${_inv_dom}.conf" 2>/dev/null || true
      fi
      log_info "[ROUTES] [WRITE] Installed nginx virtual host config -> ${_inv_dest}"
    fi
    netctl_reload_proxy 'nginx'
  else
    log_info "[ROUTES] [WRITE] Generated nginx virtual host config -> ${_inv_out}"
    netctl_reload_proxy 'nginx'
  fi
}

# ## netctl_ensure_letsencrypt_cert
# Ensures a valid, non-expired Let's Encrypt certificate exists for the domain, reusing persisted certs or running Certbot HTTP-01 validation when missing or expired.
netctl_ensure_letsencrypt_cert() {
  _elc_dom="$1"
  _elc_store="${2:-${CERT_STORE_DIR:-${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}/certs}}"
  _elc_webroot="${3:-${_elc_store}/acme-webroot}"
  _elc_email="${4:-${LETSENCRYPT_EMAIL:-}}"
  _elc_le_etc="${LETSENCRYPT_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/letsencrypt}"
  _elc_ngx_etc="${NGINX_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/nginx}"

  [ -n "$_elc_dom" ] && [ "$_elc_dom" != "_" ] || return 0

  if netctl_restore_persisted_cert "$_elc_dom" "$_elc_store"; then
    return 0
  fi

  if netctl_cert_is_valid_letsencrypt "$_elc_dom" "${_elc_le_etc}/live/${_elc_dom}/fullchain.pem" "${_elc_le_etc}/live/${_elc_dom}/privkey.pem"; then
    netctl_persist_cert_readonly "$_elc_dom" "$_elc_store" "${_elc_le_etc}/live/${_elc_dom}"
    if [ -f "${_elc_ngx_etc}/ssl/${_elc_dom}.crt" ] || [ -f "${_elc_ngx_etc}/ssl/${_elc_dom}.key" ]; then
      rm -f "${_elc_ngx_etc}/ssl/${_elc_dom}.crt" "${_elc_ngx_etc}/ssl/${_elc_dom}.key" 2>/dev/null || priv rm -f "${_elc_ngx_etc}/ssl/${_elc_dom}.crt" "${_elc_ngx_etc}/ssl/${_elc_dom}.key" 2>/dev/null || true
    fi
    return 0
  fi

  log_info "[ACME] [TLS] No valid non-expired Let's Encrypt certificate found for '${_elc_dom}'; provisioning via Certbot..."
  _cb_bin=$(command -v certbot 2>/dev/null || true)
  if [ -n "$_cb_bin" ] && [ -f "$_cb_bin" ] && [ "$(wc -l < "$_cb_bin" 2>/dev/null | tr -d ' ')" -lt 20 ] && grep -q "certbot 3.1.0" "$_cb_bin" 2>/dev/null && ! grep -q "openssl" "$_cb_bin" 2>/dev/null; then
    rm -f "$_cb_bin" 2>/dev/null || priv rm -f "$_cb_bin" 2>/dev/null || true
    rm -rf "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/certbot" 2>/dev/null || priv rm -rf "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/certbot" 2>/dev/null || true
    _cb_bin=""
  fi
  if [ -z "$_cb_bin" ] || ! command -v certbot >/dev/null 2>&1; then
    FORCE_REINSTALL=1 STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/security/certbot/setup.sh"
  fi

  mkdir -p "${_elc_webroot}/.well-known/acme-challenge" 2>/dev/null || priv mkdir -p "${_elc_webroot}/.well-known/acme-challenge" 2>/dev/null || true
  chmod -R 0755 "${_elc_webroot}" 2>/dev/null || priv chmod -R 0755 "${_elc_webroot}" 2>/dev/null || true

  if [ -n "${NETCTL_STATE_FILE:-}" ] && [ -f "${NETCTL_STATE_FILE:-}" ] && command -v nginx >/dev/null 2>&1; then
    _boot_conf="${LIBSCRIPT_DATA_DIR:-${TMP_DATA_DIR:-${TMPDIR:-/tmp}/data}}/ingress/nginx.bootstrap.conf"
    mkdir -p "$(dirname -- "$_boot_conf")"
    NETCTL_BOOTSTRAP_HTTP_ONLY=1 netctl_emit_nginx "$NETCTL_STATE_FILE" > "$_boot_conf"
    netctl_install_nginx_vhost "$_elc_dom" "$_boot_conf"
    rm -f "$_boot_conf" 2>/dev/null || true
  fi

  if [ -n "$_elc_email" ]; then
    _elc_email_arg="--email ${_elc_email}"
  else
    _elc_email_arg='--register-unsafely-without-email'
  fi

  # shellcheck disable=SC2086
  if ! certbot certonly --webroot -w "$_elc_webroot" -d "$_elc_dom" --non-interactive --agree-tos $_elc_email_arg --keep-until-expiring; then
    # shellcheck disable=SC2086
    priv certbot certonly --webroot -w "$_elc_webroot" -d "$_elc_dom" --non-interactive --agree-tos $_elc_email_arg --keep-until-expiring || \
      priv certbot certonly --standalone -d "$_elc_dom" --non-interactive --agree-tos $_elc_email_arg --keep-until-expiring || true
  fi

  if netctl_cert_is_valid_letsencrypt "$_elc_dom" "${_elc_le_etc}/live/${_elc_dom}/fullchain.pem" "${_elc_le_etc}/live/${_elc_dom}/privkey.pem"; then
    netctl_persist_cert_readonly "$_elc_dom" "$_elc_store" "${_elc_le_etc}/live/${_elc_dom}"
  elif netctl_cert_is_valid_letsencrypt "$_elc_dom" "${_elc_store}/live/${_elc_dom}/fullchain.pem" "${_elc_store}/live/${_elc_dom}/privkey.pem"; then
    netctl_persist_cert_readonly "$_elc_dom" "$_elc_store" "${_elc_store}/live/${_elc_dom}"
  else
    log_error "[ACME] [TLS] Failed to obtain a valid CA-signed Let's Encrypt certificate for '${_elc_dom}'."
    return 1
  fi

  if [ -f "${_elc_ngx_etc}/ssl/${_elc_dom}.crt" ] || [ -f "${_elc_ngx_etc}/ssl/${_elc_dom}.key" ]; then
    rm -f "${_elc_ngx_etc}/ssl/${_elc_dom}.crt" "${_elc_ngx_etc}/ssl/${_elc_dom}.key" 2>/dev/null || priv rm -f "${_elc_ngx_etc}/ssl/${_elc_dom}.crt" "${_elc_ngx_etc}/ssl/${_elc_dom}.key" 2>/dev/null || true
  fi
  return 0
}

# ## netctl_reload_proxy
# Reloads the active web proxy server abstractly via _lib/_common/service.sh.
netctl_reload_proxy() {
  _nrp_fmt="${1:-nginx}"
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
    unset SCRIPT_NAME || true
  fi
  log_info "[DAEMON] [RELOAD] Reloading ${_nrp_fmt} reverse proxy daemon..."
  case "$_nrp_fmt" in
    nginx)
      if command -v nginx >/dev/null 2>&1; then
        nginx -t >/dev/null 2>&1 || priv nginx -t >/dev/null 2>&1 || true
        if nginx -s reload >/dev/null 2>&1 || priv nginx -s reload >/dev/null 2>&1 || libscript_service reload nginx >/dev/null 2>&1; then
          log_info "[DAEMON] [ACTIVE] ${_nrp_fmt} reverse proxy reloaded successfully."
        else
          libscript_service restart nginx >/dev/null 2>&1 || true
          log_info "[DAEMON] [ACTIVE] ${_nrp_fmt} reverse proxy restarted."
        fi
      fi
      ;;
    caddy)
      if command -v caddy >/dev/null 2>&1; then
        libscript_service reload caddy >/dev/null 2>&1 || true
        log_info "[DAEMON] [ACTIVE] ${_nrp_fmt} reverse proxy reloaded successfully."
      fi
      ;;
    apache|apache2|httpd)
      libscript_service reload httpd >/dev/null 2>&1 || libscript_service reload apache2 >/dev/null 2>&1 || true
      log_info "[DAEMON] [ACTIVE] ${_nrp_fmt} reverse proxy reloaded successfully."
      ;;
  esac
}

# ## netctl_ensure_static_permissions
# Ensures parent home/application directories have o+x traverse permissions and static_dir has o+rX.
netctl_ensure_static_permissions() {
  _nes_state="$1"
  _nes_mdir="$2"
  [ -f "$_nes_state" ] || return 0
  if [ -n "${REMOTE_HOME:-}" ] && [ -d "${REMOTE_HOME}" ]; then
    chmod o+x "${REMOTE_HOME}" 2>/dev/null || priv chmod o+x "${REMOTE_HOME}" 2>/dev/null || true
  fi
  if [ -d "$_nes_mdir" ]; then
    chmod o+x "$_nes_mdir" 2>/dev/null || priv chmod o+x "$_nes_mdir" 2>/dev/null || true
    _parent_d=$(dirname -- "$_nes_mdir")
    [ -d "$_parent_d" ] && [ "$_parent_d" != "/" ] && { chmod o+x "$_parent_d" 2>/dev/null || priv chmod o+x "$_parent_d" 2>/dev/null || true; }
  fi
  _static_targets=$(jq -r '.routes // {} | to_entries[]? | select(.value.type == "static" or .value.type == "spa") | .value.target // empty' "$_nes_state" 2>/dev/null || true)
  if [ -n "$_static_targets" ]; then
    printf '%s\n' "$_static_targets" | while IFS= read -r _st_dir; do
      [ -n "$_st_dir" ] || continue
      if [ -d "$_st_dir" ]; then
        chmod -R o+rX "$_st_dir" 2>/dev/null || priv chmod -R o+rX "$_st_dir" 2>/dev/null || true
        _cur_p=$(dirname -- "$_st_dir")
        while [ -n "$_cur_p" ] && [ "$_cur_p" != "/" ] && [ "$_cur_p" != "." ]; do
          chmod o+x "$_cur_p" 2>/dev/null || priv chmod o+x "$_cur_p" 2>/dev/null || true
          _cur_p=$(dirname -- "$_cur_p")
        done
      fi
    done
  fi
}

# ## netctl_remove_manifest_ingress
# Removes managed reverse-proxy virtual host configs for a libscript.json manifest and reloads the proxy.
netctl_remove_manifest_ingress() {
  _rmi_arg="${1:-libscript.json}"
  _rmi_dom=""
  _rmi_fmt='nginx'
  if [ -f "$_rmi_arg" ] && command -v jq >/dev/null 2>&1; then
    _rmi_dom=$(jq -r '.ingress.domain // .domain // empty' "$_rmi_arg" 2>/dev/null || true)
    _rmi_fmt=$(jq -r '.ingress.provider // .ingress.engine // "nginx"' "$_rmi_arg" 2>/dev/null || printf 'nginx')
  else
    _rmi_dom="$_rmi_arg"
  fi
  if [ -n "$_rmi_dom" ] && [ "$_rmi_dom" != "libscript.json" ]; then
    _rmi_ngx_etc="${NGINX_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/nginx}"
    _rmi_httpd_etc="${HTTPD_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/httpd}"
    _rmi_apache_etc="${APACHE2_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/apache2}"
    for _vhost in "${_rmi_ngx_etc}/conf.d/${_rmi_dom}.conf" "${_rmi_ngx_etc}/sites-enabled/${_rmi_dom}" "${_rmi_ngx_etc}/sites-available/${_rmi_dom}" "${_rmi_httpd_etc}/conf.d/${_rmi_dom}.conf" "${_rmi_apache_etc}/sites-enabled/${_rmi_dom}.conf"; do
      if [ -f "$_vhost" ] || [ -L "$_vhost" ]; then
        log_info "[ROUTES] [REMOVE] Removing virtual host config ${_vhost}..."
        rm -f "$_vhost" 2>/dev/null || priv rm -f "$_vhost" 2>/dev/null || true
      fi
    done
  fi
  netctl_reload_proxy "$_rmi_fmt"
}

# ## emit_by_format
# Dispatches emission to the specified proxy format backend.
emit_by_format() {
  case "$1" in
    nginx) netctl_emit_nginx ;;
    caddy) netctl_emit_caddy ;;
    apache|apache2|httpd|iis) netctl_emit_apache ;;
    traefik) netctl_emit_traefik ;;
    dockerfile) netctl_emit_dockerfile ;;
    vagrantfile) netctl_emit_vagrantfile ;;
    *) printf '%s\n' "Unknown format: $1" >&2; exit 1 ;;
  esac
}

# ## netctl_log_state_routes
# Logs the configured domain, listen ports, and each route in NETCTL_STATE_FILE to stderr.
netctl_log_state_routes() {
  _nls_fmt="$1"
  _nls_state="$2"
  [ -f "$_nls_state" ] || return 0
  _nls_dom=$(jq -r '.domain // "_"' "$_nls_state" 2>/dev/null || printf '_')
  _nls_ports=$(jq -r '(.listen // ["80"]) | join(", ")' "$_nls_state" 2>/dev/null || printf '80')
  log_info "[ROUTES] Configuring ${_nls_fmt} ingress for domain '${_nls_dom}' (listen: ${_nls_ports})..."
  _nls_routes=$(jq -r --arg dom "$_nls_dom" '.routes // {} | to_entries[]? | "[ROUTE] [\((.value.type // "static") | ascii_upcase)] \($dom)\(.key) -> \(.value.target // .value.pattern // "")"' "$_nls_state" 2>/dev/null || true)
  if [ -n "$_nls_routes" ]; then
    printf '%s\n' "$_nls_routes" | while IFS= read -r _rline; do
      [ -n "$_rline" ] || continue
      log_info "$_rline"
    done
  fi
}

# ## netctl_apply_manifest
# Parses .ingress from a libscript.json manifest, emits reverse proxy configuration, and optionally reloads the web server.
netctl_apply_manifest() {
  _json_file="${1:-libscript.json}"
  shift || true
  _format=""
  _out_file=""
  _do_reload=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --format) _format="$2"; shift 2 ;;
      --out) _out_file="$2"; shift 2 ;;
      --reload) _do_reload=1; shift ;;
      --proxy-connect-timeout=*) NETCTL_PROXY_CONNECT_TIMEOUT="${1#*=}"; export NETCTL_PROXY_CONNECT_TIMEOUT; shift ;;
      --proxy-connect-timeout) NETCTL_PROXY_CONNECT_TIMEOUT="$2"; export NETCTL_PROXY_CONNECT_TIMEOUT; shift 2 ;;
      --proxy-send-timeout=*) NETCTL_PROXY_SEND_TIMEOUT="${1#*=}"; export NETCTL_PROXY_SEND_TIMEOUT; shift ;;
      --proxy-send-timeout) NETCTL_PROXY_SEND_TIMEOUT="$2"; export NETCTL_PROXY_SEND_TIMEOUT; shift 2 ;;
      --proxy-read-timeout=*) NETCTL_PROXY_READ_TIMEOUT="${1#*=}"; export NETCTL_PROXY_READ_TIMEOUT; shift ;;
      --proxy-read-timeout) NETCTL_PROXY_READ_TIMEOUT="$2"; export NETCTL_PROXY_READ_TIMEOUT; shift 2 ;;
      --proxy-buffering=*) NETCTL_PROXY_BUFFERING="${1#*=}"; export NETCTL_PROXY_BUFFERING; shift ;;
      --proxy-buffering) NETCTL_PROXY_BUFFERING="$2"; export NETCTL_PROXY_BUFFERING; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ ! -f "$_json_file" ]; then
    printf 'Error: Manifest file not found: %s\n' "$_json_file" >&2
    exit 1
  fi

  if ! jq -e '.ingress != null' "$_json_file" >/dev/null 2>&1; then
    exit 0
  fi

  _manifest_dir=$(cd -- "$(dirname -- "$_json_file")" && pwd)

  for _nc_ef in "${_manifest_dir}/.env" "${_manifest_dir}/.env.secrets" "${_manifest_dir}/.env.libscript"; do
    if [ -f "$_nc_ef" ]; then
      set -a
      set +u
      # shellcheck disable=SC1090,SC1091
      . "$_nc_ef" 2>/dev/null || true
      set -u
      set +a
    fi
  done

  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
    # shellcheck disable=SC1090,SC1091
    . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
    unset SCRIPT_NAME || true
    libscript_hydrate_manifest_env "$_json_file" || true
  fi

  if [ -z "$_format" ]; then
    _format=$(jq -r '.ingress.provider // .ingress.engine // "nginx"' "$_json_file" 2>/dev/null || printf 'nginx')
  fi

  NETCTL_STATE_FILE=$(mktemp "${TMPDIR:-/tmp}/netctl_apply.XXXXXX")
  export NETCTL_STATE_FILE
  trap 'rm -f "$NETCTL_STATE_FILE" "$NETCTL_STATE_FILE.tmp"' EXIT

  jq -n --arg mdir "$_manifest_dir" --slurpfile doc "$_json_file" '
    ($doc[0].ingress // {}) as $ing |
    def expand_env(s):
      if (s | type) != "string" then s
      else
        reduce range(3) as $_ (s;
          gsub("\\$\\{(?<k>[A-Za-z_][A-Za-z0-9_]*):-(?<d>[^}]*)\\}"; (env[.k] // "") | if . == "" then .d else . end) |
          gsub("\\$\\{(?<k>[A-Za-z_][A-Za-z0-9_]*)\\}"; env[.k] // "")
        )
      end;
    def resolve_path(p):
      (expand_env(p)) as $ep |
      if $ep == null or $ep == "" then ""
      elif ($ep | startswith("/")) then $ep
      elif ($ep | startswith("./")) then ($mdir + "/" + ($ep | ltrimstr("./")))
      else ($mdir + "/" + $ep) end;
    (expand_env($ing.tls // "")) as $tls_mode |
    ((env.DATA_DISK_MOUNT // env.DATA_MOUNT_DIR // "/mnt/data") + "/certs") as $def_cstore |
    (expand_env($ing.cert_store_dir // env.CERT_STORE_DIR // $def_cstore)) as $cstore |
    (expand_env($ing.acme_webroot // ($cstore + "/acme-webroot"))) as $webroot |
    (
      if ($ing.listen | type) == "array" then [ $ing.listen[] | tostring | expand_env(.) ]
      elif ($ing.listen != null) then [ ($ing.listen | tostring | expand_env(.)) ]
      elif ($tls_mode == "letsencrypt" or $tls_mode == "self-signed") then ["80", "443"]
      else ["80"] end
    ) as $raw_listen |
    {
      domain: expand_env($ing.domain // $ing.server_name // "_"),
      tls: $tls_mode,
      cert_store_dir: $cstore,
      acme_webroot: $webroot,
      email: expand_env($ing.email // env.LETSENCRYPT_EMAIL // ""),
      proxy_connect_timeout: (expand_env(($ing.proxy_connect_timeout // env.NETCTL_PROXY_CONNECT_TIMEOUT // "") | tostring)),
      proxy_send_timeout: (expand_env(($ing.proxy_send_timeout // env.NETCTL_PROXY_SEND_TIMEOUT // "") | tostring)),
      proxy_read_timeout: (expand_env(($ing.proxy_read_timeout // env.NETCTL_PROXY_READ_TIMEOUT // "") | tostring)),
      proxy_buffering: (expand_env(($ing.proxy_buffering // env.NETCTL_PROXY_BUFFERING // "") | tostring)),
      listen: (
        if $tls_mode == "letsencrypt" then (($raw_listen + ["80", "443"]) | unique)
        else $raw_listen end
      ),
      routes: (
        ($ing.routes // {}) |
        if type == "object" then
          with_entries(
            .key as $k | .value as $v |
            if ($v | type) == "string" then
              (expand_env($v)) as $ev |
              if ($ev | startswith("http://") or startswith("https://")) then
                {key: $k, value: {type: "proxy", target: $ev}}
              elif ($ev | startswith("ws://") or startswith("wss://")) then
                {key: $k, value: {type: "ws", target: ($ev | sub("^ws://"; "http://") | sub("^wss://"; "https://"))}}
              else
                {key: $k, value: {type: "static", target: resolve_path($ev)}}
              end
            elif ($v | type) == "object" then
              if $v.ws then
                {key: $k, value: {type: "ws", target: (expand_env($v.ws) | sub("^ws://"; "http://") | sub("^wss://"; "https://"))}}
              elif $v.proxy then
                {key: $k, value: {type: "proxy", target: expand_env($v.proxy)}}
              elif $v.spa == true or $v.type == "spa" then
                {key: $k, value: {type: "spa", target: resolve_path($v.static // $v.target // $v.root // ".")}}
              elif $v.static then
                {key: $k, value: {type: "static", target: resolve_path($v.static)}}
              elif $v.type == "ws" then
                {key: $k, value: {type: "ws", target: (expand_env($v.target) | sub("^ws://"; "http://") | sub("^wss://"; "https://"))}}
              elif $v.type == "proxy" then
                {key: $k, value: {type: "proxy", target: expand_env($v.target)}}
              elif $v.type == "static" then
                {key: $k, value: {type: "static", target: resolve_path($v.target)}}
              elif $v.type == "rewrite" then
                {key: $k, value: {type: "rewrite", pattern: expand_env($v.pattern)}}
              else
                {key: $k, value: {type: "static", target: resolve_path($v.target // ".")}}
              end
            else empty end
          )
        elif type == "array" then
          reduce .[] as $item ({};
            ($item.path // "/") as $k |
            if $item.type == "spa" or $item.spa == true then
              . + {($k): {type: "spa", target: resolve_path($item.target // $item.static // ".")}}
            elif $item.type == "ws" or $item.ws != null then
              . + {($k): {type: "ws", target: (expand_env($item.target // $item.ws) | sub("^ws://"; "http://") | sub("^wss://"; "https://"))}}
            elif $item.type == "proxy" or $item.proxy != null then
              . + {($k): {type: "proxy", target: expand_env($item.target // $item.proxy)}}
            elif $item.type == "rewrite" then
              . + {($k): {type: "rewrite", pattern: expand_env($item.pattern)}}
            else
              . + {($k): {type: "static", target: resolve_path($item.target // $item.static // ".")}}
            end
          )
        else {} end
      )
    }
  ' > "$NETCTL_STATE_FILE"

  _dom=$(jq -r '.domain // empty' "$NETCTL_STATE_FILE" 2>/dev/null || true)
  _tls_mode=$(jq -r '.tls // empty' "$NETCTL_STATE_FILE" 2>/dev/null || true)
  _cert_store=$(jq -r '.cert_store_dir // empty' "$NETCTL_STATE_FILE" 2>/dev/null || true)
  [ -n "$_cert_store" ] || _cert_store="${CERT_STORE_DIR:-${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}/certs}"
  _acme_webroot=$(jq -r '.acme_webroot // empty' "$NETCTL_STATE_FILE" 2>/dev/null || true)
  [ -n "$_acme_webroot" ] || _acme_webroot="${_cert_store}/acme-webroot"
  _le_email=$(jq -r '.email // empty' "$NETCTL_STATE_FILE" 2>/dev/null || true)
  [ -n "$_le_email" ] || _le_email="${LETSENCRYPT_EMAIL:-}"

  if [ -n "$_out_file" ]; then
    netctl_log_state_routes "$_format" "$NETCTL_STATE_FILE"
    if [ "$_tls_mode" = "letsencrypt" ] && [ -n "$_dom" ] && [ "$_dom" != "_" ]; then
      netctl_restore_persisted_cert "$_dom" "$_cert_store" || true
    fi
    mkdir -p "$(dirname -- "$_out_file")"
    emit_by_format "$_format" > "$_out_file"
    log_info "[ROUTES] [WRITE] Wrote ${_format} config -> ${_out_file}"
  elif [ "$_do_reload" -eq 1 ]; then
    netctl_log_state_routes "$_format" "$NETCTL_STATE_FILE"
    _conf_dir="${LIBSCRIPT_DATA_DIR:-${TMP_DATA_DIR:-${TMPDIR:-/tmp}/data}}/ingress"
    mkdir -p "$_conf_dir"
    netctl_ensure_static_permissions "$NETCTL_STATE_FILE" "$_manifest_dir"
    _am_le_etc="${LETSENCRYPT_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/letsencrypt}"
    _am_ngx_etc="${NGINX_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/nginx}"
    if [ "$_format" = "nginx" ] && [ -n "$_dom" ] && [ "$_dom" != "_" ]; then
      if [ "$_tls_mode" = "letsencrypt" ]; then
        netctl_ensure_letsencrypt_cert "$_dom" "$_cert_store" "$_acme_webroot" "$_le_email"
      elif [ -f "${_am_le_etc}/live/${_dom}/fullchain.pem" ]; then
        log_info "[ROUTES] [TLS] Confirmed SSL certificate for '${_dom}' at ${_am_le_etc}/live/${_dom}/fullchain.pem."
      elif [ -f "${_am_ngx_etc}/ssl/${_dom}.crt" ]; then
        log_info "[ROUTES] [TLS] Confirmed SSL certificate for '${_dom}' at ${_am_ngx_etc}/ssl/${_dom}.crt."
      elif command -v openssl >/dev/null 2>&1; then
        mkdir -p "${_am_ngx_etc}/ssl" 2>/dev/null || priv mkdir -p "${_am_ngx_etc}/ssl" 2>/dev/null || true
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "${_am_ngx_etc}/ssl/${_dom}.key" -out "${_am_ngx_etc}/ssl/${_dom}.crt" -subj "/CN=${_dom}" >/dev/null 2>&1 || \
          priv openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "${_am_ngx_etc}/ssl/${_dom}.key" -out "${_am_ngx_etc}/ssl/${_dom}.crt" -subj "/CN=${_dom}" >/dev/null 2>&1 || true
        log_info "[ROUTES] [TLS] Generated self-signed SSL certificate for '${_dom}' at ${_am_ngx_etc}/ssl/${_dom}.crt."
      fi
    fi
    _out_file="${_conf_dir}/${_format}.conf"
    emit_by_format "$_format" > "$_out_file"
    if [ "$_format" = "nginx" ]; then
      netctl_install_nginx_vhost "$_dom" "$_out_file"
    elif [ "$_format" = "caddy" ] && command -v caddy >/dev/null 2>&1; then
      log_info "[ROUTES] [WRITE] Installed Caddy config -> ${_out_file}"
      caddy reload --config "$_out_file" >/dev/null 2>&1 || netctl_reload_proxy "caddy"
    else
      log_info "[ROUTES] [WRITE] Generated ${_format} config -> ${_out_file}"
      netctl_reload_proxy "$_format"
    fi
  else
    if [ "$_tls_mode" = "letsencrypt" ] && [ -n "$_dom" ] && [ "$_dom" != "_" ]; then
      netctl_restore_persisted_cert "$_dom" "$_cert_store" || true
    fi
    emit_by_format "$_format"
  fi
}

[ $# -eq 0 ] && usage

SINGULAR_MODE=0
EMIT_FORMAT=""

case "$1" in
  install)
    if ! command -v jq >/dev/null 2>&1; then
      "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install jq >/dev/null 2>&1 || true
    fi
    printf '%s\n' 'netctl is a native shell module. No installation or daemon management required.'
    exit 0
    ;;
  download|ls|ls-remote|use|start|stop|restart|install-service|uninstall-service|env|logs|status|health)
    printf '%s\n' 'netctl is a native shell module. No installation or daemon management required.'
    exit 0
    ;;
  uninstall)
    exec "$NETCTL_DIR/uninstall.sh"
    ;;
  test)
    exec "$NETCTL_DIR/test.sh"
    ;;
  init) netctl_init; exit 0 ;;
  domain) netctl_set_domain "$2"; exit 0 ;;
  tls) netctl_set_tls "$2"; exit 0 ;;
  cert-store-dir|cert_store_dir) netctl_set_cert_store_dir "$2"; exit 0 ;;
  acme-webroot|acme_webroot) netctl_set_acme_webroot "$2"; exit 0 ;;
  proxy-connect-timeout|proxy_connect_timeout) netctl_set_proxy_connect_timeout "$2"; exit 0 ;;
  proxy-send-timeout|proxy_send_timeout) netctl_set_proxy_send_timeout "$2"; exit 0 ;;
  proxy-read-timeout|proxy_read_timeout) netctl_set_proxy_read_timeout "$2"; exit 0 ;;
  proxy-buffering|proxy_buffering) netctl_set_proxy_buffering "$2"; exit 0 ;;
  ensure-cert)
    shift
    netctl_ensure_letsencrypt_cert "${1:-}" "${2:-${CERT_STORE_DIR:-${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}/certs}}" "${3:-}" "${4:-${LETSENCRYPT_EMAIL:-}}"
    exit $?
    ;;
  listen) netctl_add_listen "$2"; exit 0 ;;
  static) netctl_add_static "$2" "$3"; exit 0 ;;
  spa) netctl_add_spa "$2" "$3"; exit 0 ;;
  proxy) netctl_add_proxy "$2" "$3"; exit 0 ;;
  ws) netctl_add_ws "$2" "$3"; exit 0 ;;
  rewrite) netctl_add_rewrite "$2" "$3"; exit 0 ;;
  apply)
    shift
    netctl_apply_manifest "$@"
    exit 0
    ;;
  ingress)
    shift
    _ing_file="${1:-libscript.json}"
    [ $# -gt 0 ] && shift
    netctl_apply_manifest "$_ing_file" --reload "$@"
    exit 0
    ;;
  remove-ingress|unroute)
    shift
    netctl_remove_manifest_ingress "${1:-libscript.json}"
    exit 0
    ;;
  reload)
    shift
    netctl_reload_proxy "${1:-nginx}"
    exit 0
    ;;
  emit)
    emit_by_format "$2"
    exit 0
    ;;
  -h|--help|-\?|/\?) usage ;;
  *) SINGULAR_MODE=1 ;;
esac

if [ "$SINGULAR_MODE" -eq 1 ]; then
  NETCTL_STATE_FILE=$(mktemp)
  export NETCTL_STATE_FILE

  trap 'rm -f "$NETCTL_STATE_FILE" "$NETCTL_STATE_FILE.tmp"' EXIT

  netctl_init

  while [ $# -gt 0 ]; do
    case "$1" in
      --domain)
        netctl_set_domain "$2"
        shift 2
        ;;
      --tls)
        netctl_set_tls "$2"
        shift 2
        ;;
      --cert-store-dir|--cert_store_dir)
        netctl_set_cert_store_dir "$2"
        shift 2
        ;;
      --acme-webroot|--acme_webroot)
        netctl_set_acme_webroot "$2"
        shift 2
        ;;
      --proxy-connect-timeout=*|--proxy_connect_timeout=*)
        NETCTL_PROXY_CONNECT_TIMEOUT="${1#*=}"
        export NETCTL_PROXY_CONNECT_TIMEOUT
        netctl_set_proxy_connect_timeout "${1#*=}"
        shift
        ;;
      --proxy-connect-timeout|--proxy_connect_timeout)
        NETCTL_PROXY_CONNECT_TIMEOUT="$2"
        export NETCTL_PROXY_CONNECT_TIMEOUT
        netctl_set_proxy_connect_timeout "$2"
        shift 2
        ;;
      --proxy-send-timeout=*|--proxy_send_timeout=*)
        NETCTL_PROXY_SEND_TIMEOUT="${1#*=}"
        export NETCTL_PROXY_SEND_TIMEOUT
        netctl_set_proxy_send_timeout "${1#*=}"
        shift
        ;;
      --proxy-send-timeout|--proxy_send_timeout)
        NETCTL_PROXY_SEND_TIMEOUT="$2"
        export NETCTL_PROXY_SEND_TIMEOUT
        netctl_set_proxy_send_timeout "$2"
        shift 2
        ;;
      --proxy-read-timeout=*|--proxy_read_timeout=*)
        NETCTL_PROXY_READ_TIMEOUT="${1#*=}"
        export NETCTL_PROXY_READ_TIMEOUT
        netctl_set_proxy_read_timeout "${1#*=}"
        shift
        ;;
      --proxy-read-timeout|--proxy_read_timeout)
        NETCTL_PROXY_READ_TIMEOUT="$2"
        export NETCTL_PROXY_READ_TIMEOUT
        netctl_set_proxy_read_timeout "$2"
        shift 2
        ;;
      --proxy-buffering=*|--proxy_buffering=*)
        NETCTL_PROXY_BUFFERING="${1#*=}"
        export NETCTL_PROXY_BUFFERING
        netctl_set_proxy_buffering "${1#*=}"
        shift
        ;;
      --proxy-buffering|--proxy_buffering)
        NETCTL_PROXY_BUFFERING="$2"
        export NETCTL_PROXY_BUFFERING
        netctl_set_proxy_buffering "$2"
        shift 2
        ;;
      --listen)
        netctl_add_listen "$2"
        shift 2
        ;;
      --static)
        netctl_add_static "$2" "$3"
        shift 3
        ;;
      --spa)
        netctl_add_spa "$2" "$3"
        shift 3
        ;;
      --proxy)
        netctl_add_proxy "$2" "$3"
        shift 3
        ;;
      --ws)
        netctl_add_ws "$2" "$3"
        shift 3
        ;;
      --rewrite)
        netctl_add_rewrite "$2" "$3"
        shift 3
        ;;
      --emit)
        EMIT_FORMAT="$2"
        shift 2
        ;;
      *)
        printf '%s\n' "Unknown option: $1" >&2
        usage
        ;;
    esac
  done

  if [ -n "$EMIT_FORMAT" ]; then
    emit_by_format "$EMIT_FORMAT"
  fi
fi
