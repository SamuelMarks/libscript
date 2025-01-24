if [ -z "${SERVER_NAME+x}" ]; then
  >&2 printf 'SERVER_NAME must be set for nginx sites-available to work'
  exit 3
fi

site_conf="${LIBSCRIPT_DATA_DIR}"'/'"$(mktemp 'nginx_sites_'"${SERVER_NAME}"'_XXX')"
printf '%s' "${site_conf}" > "${SITE_CONF_FILENAME}"

# guess which template is correct
if [ ! -z "${WWWROOT+x}" ]; then
  conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_location_wwwroot.conf'
fi

if [ -z "${conf_child_tpl+x}" ]; then
  >&2 printf 'Could not determine which template to interpolate for nginx'
  exit 3
fi

if [ -z "${HTTPS_ALWAYS+x}" ] && { [ "${HTTPS_ALWAYS}" -eq 1 ] || [ "${HTTPS_ALWAYS}" = 'true' ]; }; then
  conf_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_secure.conf'
else
  export LISTEN="${LISTEN:-80}"
  conf_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_insecure.conf'
fi


LOCATIONS=$(envsubst_safe < "${conf_child_tpl}")
export LOCATIONS

envsubst_safe < "${conf_tpl}" > "${site_conf}"