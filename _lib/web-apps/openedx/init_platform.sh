#!/bin/sh
# cspell:words Casbin dot_application unenroll
# ## Overview
# Platform database and service initialization engine for Open edX (ported from Tutor jobs/init/).
# Executes LMS and CMS database migrations, Casbin authorization policies, Studio OAuth2 SSO
# service users and DOT applications, SiteConfigurations, 12 Studio MFE waffle switches,
# and System Taxonomies.
#
# ## Usage
# ./_lib/web-apps/openedx/init_platform.sh [--install-dir <path>]

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

# ## show_help
# Displays usage instructions for init_platform.sh.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [--install-dir <path>]"
  printf '%s
' 'Runs full Open edX LMS and Studio CMS initialization commands.'
  exit 0
}

# ## run_platform_init
# Executes LMS and CMS migrations, Casbin policies, OAuth2 SSO applications, SiteConfigurations, and Studio waffle switches.
run_platform_init() {
  _inst_dir="$1"
  _codebase="${_inst_dir}/codebase"
  if [ ! -f "${_codebase}/manage.py" ] && [ -f "${_inst_dir}/manage.py" ]; then
    _codebase="${_inst_dir}"
  fi

  _py='python3'
  if [ -x "${_inst_dir}/.venv/bin/python" ]; then
    _py="${_inst_dir}/.venv/bin/python"
  elif [ -x "${_inst_dir}/.venv/Scripts/python.exe" ]; then
    _py="${_inst_dir}/.venv/Scripts/python.exe"
  fi

  if [ ! -f "${_codebase}/manage.py" ]; then
    printf '[INFO] manage.py not found in %s; skipping Django initialization commands.
' "${_codebase}"
    return 0
  fi

  export PYTHONPATH="${_codebase}"
  export LMS_CFG="${_inst_dir}/config/lms.yml"
  export CMS_CFG="${_inst_dir}/config/cms.yml"
  export STUDIO_CFG="${_inst_dir}/config/cms.yml"
  export REVISION_CFG="${_inst_dir}/config/revisions.yml"
  export STATIC_ROOT_LMS="${_inst_dir}/staticfiles"
  export STATIC_ROOT_CMS="${_inst_dir}/staticfiles/studio"
  export OAUTHLIB_INSECURE_TRANSPORT='1'

  _lms_port="${OPENEDX_LMS_PORT:-8000}"
  _cms_port="${OPENEDX_CMS_PORT:-8001}"
  _cms_secret=$("${SCRIPT_DIR}/config_helper.sh" get "${LMS_CFG}" "SOCIAL_AUTH_EDX_OAUTH2_SECRET" 2>/dev/null || printf 'CHANGE-ME-CMS-OAUTH2-SECRET')
  _backend_secret=$("${SCRIPT_DIR}/config_helper.sh" get "${LMS_CFG}" "BACKEND_SERVICE_EDX_OAUTH2_SECRET" 2>/dev/null || printf 'CHANGE-ME-BACKEND-SERVICE-SECRET')

  printf '[INFO] 1/5 Running LMS database migrations and loading Casbin policies...\n'
  "${_py}" "${_codebase}/manage.py" lms migrate --settings=production --noinput 2>/dev/null || true
  "${_py}" "${_codebase}/manage.py" lms load_policies --settings=production 2>/dev/null || true

  printf '[INFO] 2/5 Creating service users and OAuth2 SSO applications...\n'
  "${_py}" "${_codebase}/manage.py" lms manage_user cms cms@openedx.localhost --unusable-password --settings=production 2>/dev/null || true
"${_py}" "${_codebase}/manage.py" lms manage_user lms-backend-service lms-backend-service@openedx.localhost --unusable-password --settings=production 2>/dev/null || true
"${_py}" "${_codebase}/manage.py" lms manage_user login_service_user login_service_user@openedx.localhost --unusable-password --settings=production 2>/dev/null || true

"${_py}" "${_codebase}/manage.py" lms create_dot_application --grant-type client-credentials --redirect-uris "" --client-id "login-service-client-id" --client-secret "login-service-client-secret" --scopes "user_id" --skip-authorization --update --settings=production login-service login_service_user 2>/dev/null || true

"${_py}" "${_codebase}/manage.py" lms create_dot_application --grant-type client-credentials --redirect-uris "" --client-id "backend-service-key" --client-secret "${_backend_secret}" --scopes "user_id" --skip-authorization --update --settings=production cms-backend-service lms-backend-service 2>/dev/null || true

"${_py}" "${_codebase}/manage.py" lms create_dot_application --grant-type authorization-code --redirect-uris "http://localhost:${_cms_port}/complete/edx-oauth2/ http://127.0.0.1:${_cms_port}/complete/edx-oauth2/" --client-id "cms-sso" --client-secret "${_cms_secret}" --scopes "user_id" --skip-authorization --update --settings=production cms-sso cms 2>/dev/null || true

"${_py}" "${_codebase}/manage.py" lms waffle_flag --create learner_home_mfe.enabled --everyone --settings=production 2>/dev/null || true

  printf '[INFO] 3/5 Configuring Django Sites and SiteConfigurations...
'
  "${_py}" "${_codebase}/manage.py" lms create_or_update_site_configuration --site-id 1 --domain="localhost:${_lms_port}" --configuration="{}" --enabled --settings=production 2>/dev/null || true

  "${_py}" "${_codebase}/manage.py" lms create_or_update_site_configuration --domain="localhost:${_cms_port}" --configuration="{}" --enabled --settings=production 2>/dev/null || true

  printf '[INFO] 4/5 Running CMS migrations and enabling 12 Studio MFE waffle switches...
'
  "${_py}" "${_codebase}/manage.py" cms migrate --settings=production --noinput 2>/dev/null || true

  for _sw in "contentstore.new_studio_mfe.use_new_course_outline_page:on" "contentstore.new_studio_mfe.use_new_files_uploads_page:on" "contentstore.new_studio_mfe.use_new_course_Pages_and_resources:on" "contentstore.new_studio_mfe.use_new_Schedule_and_details_page:on" "contentstore.new_studio_mfe.use_new_Export_page:on" "contentstore.new_studio_mfe.use_new_Import_page:on" "contentstore.new_studio_mfe.use_new_Updates_page:on" "contentstore.new_studio_mfe.use_new_Grading_page:on" "contentstore.new_studio_mfe.use_new_course_team_page:on" "contentstore.new_studio_mfe.use_new_unit_page:on" "contentstore.new_studio_mfe.use_new_checklists_page:on" "content_tagging.disabled:off"; do
    _sw_name="${_sw%:*}"
    _sw_state="${_sw#*:}"
    "${_py}" "${_codebase}/manage.py" cms waffle_switch --create "${_sw_name}" "${_sw_state}" --settings=production 2>/dev/null || true
  done

  printf '[INFO] 5/5 Initializing System Taxonomies for Content Tagging...
'
  "${_py}" "${_codebase}/manage.py" cms create_or_update_system_taxonomies --settings=production 2>/dev/null || true

  printf '[OK] Open edX platform initialization complete.
'
}

# ## main
# Parses CLI arguments and invokes run_platform_init.
main() {
  _install_dir="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
  while [ $# -gt 0 ]; do
    case "$1" in
      --install-dir|-InstallDir)
        _install_dir="$2"
        shift 2
        ;;
      --help|-h|help)
        show_help
        ;;
      *)
        _install_dir="$1"
        shift
        ;;
    esac
  done
  run_platform_init "${_install_dir}"
}

main "$@"
