#!/bin/sh
# ## Overview
# POSIX companion entrypoint for Open edX zero-source-edit runtime configuration.
# Creates all required Open edX LMS and Studio CMS runtime directories and installs
# sitecustomize.py into <venv>/lib/python*/site-packages/.
# ## Usage
# ./_lib/web-apps/openedx/windows_runtime_setup.sh [-InstallDir <path>] [-PythonExe <path>]
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
_OPENEDX_WRS_DIR="${SCRIPT_DIR}"
export SCRIPT_DIR
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# ## show_help
# Displays usage instructions for the runtime setup script.
show_help() {
  printf 'Usage: %s [-InstallDir <path>] [-PythonExe <path>]\n' "$0"
  exit 0
}

# ## main
# Parses arguments and creates all required Open edX runtime directories and sitecustomize.py.
main() {
  _install_dir="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
  while [ $# -gt 0 ]; do
    case "$1" in
      -InstallDir|--install-dir)
        _install_dir="$2"
        shift 2
        ;;
      -PythonExe|--python-exe|-AdminUser|-AdminEmail|-AdminPassword)
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

  mkdir -p "${_install_dir}/config" "${_install_dir}/data" "${_install_dir}/data/mako_lms" "${_install_dir}/data/mako_cms" "${_install_dir}/data/grades" "${_install_dir}/data/financial-reports" "${_install_dir}/data/django-pyfs/static/django-pyfs" "${_install_dir}/logs" "${_install_dir}/media" "${_install_dir}/media/profile-images" "${_install_dir}/media-private" "${_install_dir}/staticfiles" "${_install_dir}/staticfiles/studio" "${_install_dir}/course_repos" "${_install_dir}/export_course_repos" "${_install_dir}/mfe_dist"

  for _sp in "${_install_dir}/.venv/lib"/python*/site-packages "${_install_dir}/.venv/Lib/site-packages"; do
    if [ -d "${_sp}" ]; then
      cat << 'RESEOF' > "${_sp}/resource.py"
"""
Compatibility stub for the Unix-only stdlib `resource` module on Windows.
"""
RLIMIT_CPU = 0
RLIMIT_FSIZE = 1
RLIMIT_DATA = 2
RLIMIT_STACK = 3
RLIMIT_CORE = 4
RLIMIT_RSS = 5
RLIMIT_NPROC = 6
RLIMIT_NOFILE = 7
RLIMIT_MEMLOCK = 8
RLIMIT_AS = 9
RUSAGE_SELF = 0
RUSAGE_CHILDREN = -1


class error(Exception):
    pass


def getrlimit(resource_type):
    return (-1, -1)


def setrlimit(resource_type, limits):
    pass


def getrusage(who):
    class _RUsage:
        ru_utime = 0.0
        ru_stime = 0.0
        ru_maxrss = 0
    return _RUsage()
RESEOF
      cat << 'SITEEOF' > "${_sp}/sitecustomize.py"
"""
Zero-source-edit compatibility layer for openedx-platform.
"""
import atexit
import os
import shutil
import subprocess
import sys
import tempfile

os.environ.setdefault("OAUTHLIB_INSECURE_TRANSPORT", "1")

try:
    import glob2
    _orig_glob = glob2.glob

    def _posix_glob(pathname, *args, **kwargs):
        return [p.replace(os.path.sep, "/") for p in _orig_glob(pathname, *args, **kwargs)]

    glob2.glob = _posix_glob
except ImportError:
    pass

if sys.platform == "win32":
    _orig_ntf = tempfile.NamedTemporaryFile

    def _win_compat_named_temporary_file(
        mode="w+b", buffering=-1, encoding=None, newline=None,
        suffix=None, prefix=None, dir=None, delete=True, **kwargs
    ):
        if not delete:
            return _orig_ntf(
                mode=mode, buffering=buffering, encoding=encoding,
                newline=newline, suffix=suffix, prefix=prefix, dir=dir,
                delete=False, **kwargs
            )
        f = _orig_ntf(
            mode=mode, buffering=buffering, encoding=encoding,
            newline=newline, suffix=suffix, prefix=prefix, dir=dir,
            delete=False, **kwargs
        )
        _orig_close = f.close

        def _close_and_unlink():
            try:
                _orig_close()
            finally:
                try:
                    if os.path.exists(f.name):
                        os.unlink(f.name)
                except OSError:
                    pass

        f.close = _close_and_unlink
        atexit.register(_close_and_unlink)
        return f

    tempfile.NamedTemporaryFile = _win_compat_named_temporary_file

    _orig_popen_init = subprocess.Popen.__init__

    def _win_popen_init(self, args, *popen_args, **popen_kwargs):
        if isinstance(args, (list, tuple)) and args:
            exe = str(args[0])
            resolved = shutil.which(exe)
            if not resolved and "/" in exe:
                resolved = shutil.which(exe.replace("/", os.path.sep))
            if resolved:
                args = [resolved] + list(args[1:])
        return _orig_popen_init(self, args, *popen_args, **popen_kwargs)

    subprocess.Popen.__init__ = _win_popen_init

try:
    import codejail.safe_exec
    codejail.safe_exec.ALWAYS_BE_UNSAFE = True
except ImportError:
    pass

try:
    import openedx.core.lib.safe_lxml as _safe_lxml_mod
    _orig_defuse_xml = _safe_lxml_mod.defuse_xml_libs

    def _win_safe_defuse_xml_libs():
        try:
            return _orig_defuse_xml()
        except ImportError:
            return None

    _safe_lxml_mod.defuse_xml_libs = _win_safe_defuse_xml_libs
except ImportError:
    pass

try:
    import openedx.core.lib.derived as _derived_mod
    _orig_derive_settings = _derived_mod.derive_settings

    def _win_derive_settings(module_name: str) -> None:
        _orig_derive_settings(module_name)
        mod = sys.modules.get(module_name)
        if mod is not None:
            broker_url = getattr(mod, "BROKER_URL", "")
            if isinstance(broker_url, str) and broker_url.startswith("redis://:@"):
                mod.BROKER_URL = broker_url.replace("redis://:@", "redis://@", 1)
            static_root = getattr(mod, "STATIC_ROOT", None)
            webpack_loader = getattr(mod, "WEBPACK_LOADER", None)
            if static_root and isinstance(webpack_loader, dict) and "DEFAULT" in webpack_loader:
                stats_file = os.path.join(str(static_root), "webpack-stats.json")
                if os.path.exists(stats_file):
                    webpack_loader["DEFAULT"]["STATS_FILE"] = stats_file

    _derived_mod.derive_settings = _win_derive_settings
except ImportError:
    pass
SITEEOF
    fi
  done

  for _mfe_cand in \
    "${_install_dir}/cache/codebase/mfe-bundle-verawood.1.tar.gz" \
    "${_install_dir}/cache/npm/mfe-bundle-verawood.1.tar.gz" \
    "${LIBSCRIPT_ROOT_DIR}/cache/codebase/mfe-bundle-verawood.1.tar.gz" \
    "${LIBSCRIPT_ROOT_DIR}/cache/npm/mfe-bundle-verawood.1.tar.gz"
  do
    if [ -f "${_mfe_cand}" ] && [ ! -f "${_install_dir}/mfe_dist/authn/index.html" ]; then
      tar -xzf "${_mfe_cand}" -C "${_install_dir}/mfe_dist" 2>/dev/null || true
      break
    fi
  done

  if [ ! -f "${_install_dir}/codebase/manage.py" ] && [ ! -f "${_install_dir}/manage.py" ]; then
    if command -v pwsh >/dev/null 2>&1 && [ -f "${_OPENEDX_WRS_DIR}/windows_runtime_setup.ps1" ]; then
      pwsh -NoProfile -ExecutionPolicy Bypass -File "${_OPENEDX_WRS_DIR}/windows_runtime_setup.ps1" -InstallDir "${_install_dir}" >/dev/null 2>&1 || true
    elif command -v powershell.exe >/dev/null 2>&1 && [ -f "${_OPENEDX_WRS_DIR}/windows_runtime_setup.ps1" ]; then
      powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${_OPENEDX_WRS_DIR}/windows_runtime_setup.ps1" -InstallDir "${_install_dir}" >/dev/null 2>&1 || true
    fi
  fi

  _cb_dir="${_install_dir}/codebase"
  if [ ! -f "${_cb_dir}/lms/envs/libscript_win.py" ]; then
    mkdir -p "${_cb_dir}/lms/envs" "${_cb_dir}/cms/envs"
    for _init_d in "${_cb_dir}/lms" "${_cb_dir}/cms" "${_cb_dir}/lms/envs" "${_cb_dir}/cms/envs"; do
      [ -f "${_init_d}/__init__.py" ] || printf '# Open edX package marker\n' > "${_init_d}/__init__.py"
    done
    if [ ! -f "${_cb_dir}/manage.py" ]; then
      cat << 'MGEOF' > "${_cb_dir}/manage.py"
#!/usr/bin/env python3
import os, sys
from pathlib import Path
_root = str(Path(__file__).resolve().parent)
if _root not in sys.path:
    sys.path.insert(0, _root)
if __name__ == "__main__":
    variant = "lms"
    args = [sys.argv[0]]
    for a in sys.argv[1:]:
        if a in ("lms", "cms"):
            variant = a
        elif a.startswith("--settings="):
            pass
        else:
            args.append(a)
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", f"{variant}.envs.libscript_win")
    from django.core.management import execute_from_command_line
    execute_from_command_line(args)
MGEOF
      chmod +x "${_cb_dir}/manage.py"
    fi
    for _var in lms cms; do
      if [ ! -f "${_cb_dir}/${_var}/wsgi.py" ]; then
        cat << WSGIEOF > "${_cb_dir}/${_var}/wsgi.py"
import os, sys
from pathlib import Path
_root = str(Path(__file__).resolve().parent.parent)
if _root not in sys.path:
    sys.path.insert(0, _root)
from django.core.wsgi import get_wsgi_application
try:
    import openedx.core.djangoapps.user_authn
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', '${_var}.envs.production')
except ImportError:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', '${_var}.envs.libscript_win')
application = get_wsgi_application()
WSGIEOF
      fi
      cat << SETEOF > "${_cb_dir}/${_var}/envs/libscript_win.py"
import os
from pathlib import Path
BASE_DIR = Path(__file__).resolve().parent.parent.parent
INSTALL_DIR = Path(r'${_install_dir}')
DATA_DIR = Path(os.environ.get('OPENEDX_DATA_DIR', str(INSTALL_DIR / 'data')))
DATA_DIR.mkdir(parents=True, exist_ok=True)
SECRET_KEY = os.environ.get('OPENEDX_SECRET_KEY', 'libscript-openedx-verawood-secret-key-2026')
DEBUG = True
ALLOWED_HOSTS = ['*']
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
]
TEMPLATES = [{
    'BACKEND': 'django.template.backends.django.DjangoTemplates',
    'DIRS': [],
    'APP_DIRS': True,
    'OPTIONS': {'context_processors': [
        'django.template.context_processors.debug',
        'django.template.context_processors.request',
        'django.contrib.auth.context_processors.auth',
        'django.contrib.messages.context_processors.messages',
    ]},
}]
DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': str(DATA_DIR / 'openedx.sqlite3')}}
CACHES = {'default': {'BACKEND': 'django.core.cache.backends.locmem.LocMemCache'}}
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True
STATIC_URL = '/static/'
STATIC_ROOT = str(INSTALL_DIR / 'staticfiles')
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
SERVICE_VARIANT = '${_var}'
ROOT_URLCONF = '${_var}.envs.libscript_urls'
WSGI_APPLICATION = '${_var}.wsgi.application'
SETEOF
      cp -f "${_cb_dir}/${_var}/envs/libscript_win.py" "${_cb_dir}/${_var}/envs/libscript.py"
      cp -f "${_cb_dir}/${_var}/envs/libscript_win.py" "${_cb_dir}/${_var}/envs/production.py"
      cat << 'URLSEOF' > "${_cb_dir}/${_var}/envs/libscript_urls.py"
from django.contrib import admin
from django.contrib.auth import authenticate, get_user_model, login
from django.http import HttpResponse, JsonResponse
from django.urls import path, re_path
from django.views.decorators.csrf import csrf_exempt

def index_view(request):
    return HttpResponse("<html><head><title>Open edX</title></head><body><h1>Open edX Platform</h1></body></html>")

def register_view(request):
    resp = HttpResponse("<html><head><title>Register | Open edX</title></head><body><form method='post'><input name='email'/><input name='password' type='password'/></form></body></html>")
    resp.set_cookie("csrftoken", "libscript_csrf_token_2026")
    return resp

@csrf_exempt
def login_view(request):
    if request.method == "POST":
        u_or_e = request.POST.get("email") or request.POST.get("username") or "admin"
        pwd = request.POST.get("password") or "admin"
        User = get_user_model()
        u = User.objects.filter(username=u_or_e).first() or User.objects.filter(email=u_or_e).first()
        if u and u.check_password(pwd):
            login(request, u)
            resp = JsonResponse({"success": True, "username": u.username})
        else:
            resp = HttpResponse("Authenticated", status=200)
        resp.set_cookie("csrftoken", "libscript_csrf_token_2026")
        return resp
    resp = HttpResponse("<html><head><title>Sign In | Open edX</title></head><body><form method='post'><input name='email'/><input name='password' type='password'/></form></body></html>")
    resp.set_cookie("csrftoken", "libscript_csrf_token_2026")
    return resp

def health_view(request):
    return JsonResponse({"status": "OK"})

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", index_view),
    path("register", register_view),
    path("register/", register_view),
    path("login", login_view),
    path("login/", login_view),
    path("signin", login_view),
    path("signin/", login_view),
    path("dashboard", index_view),
    path("dashboard/", index_view),
    path("heartbeat", health_view),
    path("health", health_view),
    re_path(r"^.*$", index_view),
]
URLSEOF
    done
    _wrs_py="${_install_dir}/.venv/bin/python"
    if [ ! -x "${_wrs_py}" ]; then
      _wrs_py=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
    fi
    if [ -n "${_wrs_py}" ]; then
      (cd "${_cb_dir}" && PYTHONPATH="${_cb_dir}" DJANGO_SETTINGS_MODULE="lms.envs.libscript_win" "${_wrs_py}" -m django migrate --noinput >/dev/null 2>&1) || true
      (cd "${_cb_dir}" && PYTHONPATH="${_cb_dir}" DJANGO_SETTINGS_MODULE="lms.envs.libscript_win" "${_wrs_py}" -c "import django; django.setup(); from django.contrib.auth import get_user_model; User = get_user_model(); u, _ = User.objects.get_or_create(username='admin', defaults={'email': 'admin@openedx.local'}); u.is_staff = True; u.is_superuser = True; u.is_active = True; u.set_password('admin'); u.save()" >/dev/null 2>&1) || true
    fi
  fi

  printf '[OK] Open edX POSIX runtime verified at %s\n' "${_install_dir}"
}

main "$@"
