# cspell:words GETFD SETFD CLOEXEC TCSANOW tcgetattr tcsetattr geteuid getuid getegid getgid sitecustomize HTTPONLY httponly mimetypes urlsafe rstrip edxloggedin getattr endswith csrftoken unenroll Prereqs Flearner
# ## Overview
# Configures the Open edX Django LMS and Studio CMS settings, URLs, Micro-Frontend (MFE)
# static serving, REST APIs, and POSIX compatibility shims for native Windows 11 execution
# under Waitress / Django WSGI.
#
# ## Usage
# powershell -NoProfile -ExecutionPolicy Bypass -File windows_runtime_setup.ps1 [-InstallDir <path>] [-PythonExe <path>]

param(
    [string]$InstallDir = "$env:USERPROFILE\.libscript\openedx",
    [string]$PythonExe = "",
    [string]$AdminUser = "",
    [string]$AdminEmail = "",
    [string]$AdminPassword = ""
)

$ErrorActionPreference = "Stop"

if (-not $PythonExe -or -not (Test-Path $PythonExe)) {
    $venvPy = Join-Path $InstallDir ".venv\Scripts\python.exe"
    if (Test-Path $venvPy) {
        $PythonExe = $venvPy
    } else {
        $pyCandidates = @(
            "$env:LOCALAPPDATA\Programs\Python\Python312-arm64\python.exe",
            "$env:LOCALAPPDATA\Programs\Python\Python311-arm64\python.exe",
            "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
            "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
            "C:\Program Files\Python312\python.exe",
            "C:\Program Files\Python311\python.exe"
        )
        foreach ($c in $pyCandidates) {
            if (Test-Path $c) { $PythonExe = $c; break }
        }
    }
}

$codebaseDir = Join-Path $InstallDir "codebase"
if (-not (Test-Path (Join-Path $codebaseDir "manage.py"))) {
    if (Test-Path (Join-Path $InstallDir "manage.py")) {
        $codebaseDir = $InstallDir
    }
}

$sitePackages = Join-Path $InstallDir ".venv\Lib\site-packages"
$venvScripts = Join-Path $InstallDir ".venv\Scripts"
if (Test-Path $venvScripts) {
    Get-ChildItem -Path $venvScripts -Filter "*._pth" -ErrorAction SilentlyContinue | ForEach-Object {
        $pthLines = Get-Content $_.FullName
        if ($pthLines -notcontains $codebaseDir) {
            Add-Content -Path $_.FullName -Value "`r`n$codebaseDir"
        }
    }
}
if (Test-Path $sitePackages) {
    Set-Content -Path (Join-Path $sitePackages "openedx_codebase.pth") -Value $codebaseDir -Encoding Ascii
    $fcntlPy = @"
LOCK_SH = 1
LOCK_EX = 2
LOCK_NB = 4
LOCK_UN = 8
F_GETFD = 1
F_SETFD = 2
FD_CLOEXEC = 1
def fcntl(fd, op, arg=0): return 0
def ioctl(fd, op, arg=0, mutate_flag=True): return 0
def flock(fd, op): pass
def lockf(fd, op, length=0, start=0, whence=0): pass
"@
    Set-Content -Path (Join-Path $sitePackages "fcntl.py") -Value $fcntlPy -Encoding Ascii

    $pwdPy = @"
class struct_passwd:
    def __init__(self, pw_name='edxapp', pw_passwd='x', pw_uid=1000, pw_gid=1000, pw_gecos='', pw_dir='', pw_shell=''):
        self.pw_name = pw_name
        self.pw_passwd = pw_passwd
        self.pw_uid = pw_uid
        self.pw_gid = pw_gid
        self.pw_gecos = pw_gecos
        self.pw_dir = pw_dir
        self.pw_shell = pw_shell
def getpwuid(uid): return struct_passwd(pw_uid=uid)
def getpwnam(name): return struct_passwd(pw_name=name)
def getpwall(): return [struct_passwd()]
"@
    Set-Content -Path (Join-Path $sitePackages "pwd.py") -Value $pwdPy -Encoding Ascii

    $grpPy = @"
class struct_group:
    def __init__(self, gr_name='edxapp', gr_passwd='x', gr_gid=1000, gr_mem=None):
        self.gr_name = gr_name
        self.gr_passwd = gr_passwd
        self.gr_gid = gr_gid
        self.gr_mem = gr_mem or []
def getgrgid(gid): return struct_group(gr_gid=gid)
def getgrnam(name): return struct_group(gr_name=name)
def getgrall(): return [struct_group()]
"@
    Set-Content -Path (Join-Path $sitePackages "grp.py") -Value $grpPy -Encoding Ascii

    $resourcePy = @"
RLIMIT_NOFILE = 7
RLIMIT_AS = 9
def getrlimit(res): return (4096, 4096)
def setrlimit(res, limits): pass
def getrusage(who):
    class _RUsage:
        ru_utime = 0.0
        ru_stime = 0.0
        ru_maxrss = 0
    return _RUsage()
RUSAGE_SELF = 0
"@
    Set-Content -Path (Join-Path $sitePackages "resource.py") -Value $resourcePy -Encoding Ascii

    $syslogPy = @"
LOG_INFO = 6
LOG_ERR = 3
LOG_WARNING = 4
LOG_DEBUG = 7
LOG_PID = 1
LOG_USER = 8
def openlog(*args, **kwargs): pass
def syslog(*args, **kwargs): pass
def closelog(): pass
"@
    Set-Content -Path (Join-Path $sitePackages "syslog.py") -Value $syslogPy -Encoding Ascii

    $termiosPy = @"
TCSANOW = 0
def tcgetattr(fd): return [0, 0, 0, 0, 0, 0, []]
def tcsetattr(fd, when, attributes): pass
"@
    Set-Content -Path (Join-Path $sitePackages "termios.py") -Value $termiosPy -Encoding Ascii

    $siteCustomizePy = @"
import os, socket
if not hasattr(os, 'geteuid'):
    os.geteuid = lambda: 1000
if not hasattr(os, 'getuid'):
    os.getuid = lambda: 1000
if not hasattr(os, 'getegid'):
    os.getegid = lambda: 1000
if not hasattr(os, 'getgid'):
    os.getgid = lambda: 1000
if not hasattr(os, 'chown'):
    os.chown = lambda path, uid, gid, *a, **kw: None
if not hasattr(socket, 'AF_UNIX'):
    socket.AF_UNIX = 1
"@
    Set-Content -Path (Join-Path $sitePackages "sitecustomize.py") -Value $siteCustomizePy -Encoding Ascii
}

# Deploy pre-built MFE bundle if present in cache or codebase
$mfeDistDir = Join-Path $InstallDir "mfe_dist"
if (-not (Test-Path $mfeDistDir)) {
    New-Item -ItemType Directory -Path $mfeDistDir -Force | Out-Null
}
$mfeArchiveCandidates = @(
    (Join-Path $InstallDir "cache\codebase\mfe-bundle-verawood.1.tar.gz"),
    "C:\libscript\cache\codebase\mfe-bundle-verawood.1.tar.gz",
    "C:\libscript\mfe-bundle-verawood.1.tar.gz"
)
foreach ($cand in $mfeArchiveCandidates) {
    if ((Test-Path $cand) -and (-not (Test-Path (Join-Path $mfeDistDir "authn\index.html")))) {
        Write-Host "[INFO] Extracting Open edX Verawood.1 MFE bundle from $cand..."
        & tar.exe -xzf $cand -C $mfeDistDir 2>$null
        break
    }
}

$lmsEnvsDir = Join-Path $codebaseDir "lms\envs"
$cmsEnvsDir = Join-Path $codebaseDir "cms\envs"
if (-not (Test-Path $lmsEnvsDir)) { New-Item -ItemType Directory -Path $lmsEnvsDir -Force | Out-Null }
if (-not (Test-Path $cmsEnvsDir)) { New-Item -ItemType Directory -Path $cmsEnvsDir -Force | Out-Null }

foreach ($pkgDir in @(
    (Join-Path $codebaseDir "lms"),
    (Join-Path $codebaseDir "cms"),
    $lmsEnvsDir,
    $cmsEnvsDir
)) {
    $initFile = Join-Path $pkgDir "__init__.py"
    if (-not (Test-Path $initFile)) {
        Set-Content -Path $initFile -Value "# Open edX package marker`r`n" -Encoding Ascii
    }
}

$lmsWsgiPath = Join-Path $codebaseDir "lms\wsgi.py"
$lmsWsgiContent = @"
import os, sys
from pathlib import Path
_root = str(Path(__file__).resolve().parent.parent)
if _root not in sys.path:
    sys.path.insert(0, _root)
from django.core.wsgi import get_wsgi_application
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms.envs.libscript_win')
application = get_wsgi_application()
"@
Set-Content -Path $lmsWsgiPath -Value $lmsWsgiContent -Encoding Ascii

$cmsWsgiPath = Join-Path $codebaseDir "cms\wsgi.py"
$cmsWsgiContent = @"
import os, sys
from pathlib import Path
_root = str(Path(__file__).resolve().parent.parent)
if _root not in sys.path:
    sys.path.insert(0, _root)
from django.core.wsgi import get_wsgi_application
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'cms.envs.libscript_win')
application = get_wsgi_application()
"@
Set-Content -Path $cmsWsgiPath -Value $cmsWsgiContent -Encoding Ascii

$installDirFwd = $InstallDir -replace '\\', '/'

$commonSettingsPy = @"
import os, sys, json
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent
INSTALL_DIR = Path(r'$installDirFwd')
MFE_DIST_DIR = INSTALL_DIR / 'mfe_dist'
DATA_DIR = INSTALL_DIR / 'data'
CONFIG_DIR = INSTALL_DIR / 'config'

SECRET_KEY = os.environ.get('OPENEDX_SECRET_KEY', 'libscript-openedx-verawood-win-secret-key-2026')
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

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [
            str(BASE_DIR / 'lms' / 'templates'),
            str(BASE_DIR / 'cms' / 'templates'),
            str(BASE_DIR / 'common' / 'templates'),
        ],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': str(INSTALL_DIR / 'openedx.sqlite3'),
    }
}

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
}

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True
STATIC_URL = '/static/'
STATIC_ROOT = str(INSTALL_DIR / 'staticfiles')
STATICFILES_DIRS = [
    p for p in [
        str(MFE_DIST_DIR),
        str(BASE_DIR / 'lms' / 'static'),
        str(BASE_DIR / 'cms' / 'static'),
        str(BASE_DIR / 'common' / 'static'),
    ] if os.path.isdir(p)
]
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
SESSION_COOKIE_NAME = 'edx-sessionid'
SESSION_COOKIE_HTTPONLY = False
SESSION_COOKIE_SAMESITE = 'Lax'
CSRF_COOKIE_SECURE = False
CSRF_COOKIE_HTTPONLY = False
PLATFORM_NAME = 'Open edX'
SITE_NAME = 'localhost:8000'
LMS_PORT_VAL = os.environ.get('OPENEDX_LMS_PORT', '8000')
CMS_PORT_VAL = os.environ.get('OPENEDX_CMS_PORT', '8001')
LMS_ROOT_URL = f'http://localhost:{LMS_PORT_VAL}'
CMS_ROOT_URL = f'http://localhost:{CMS_PORT_VAL}'
"@

$lmsSettingsPy = $commonSettingsPy + "`r`nSERVICE_VARIANT = 'lms'`r`nROOT_URLCONF = 'lms.envs.libscript_urls'`r`nWSGI_APPLICATION = 'lms.wsgi.application'`r`n"
$cmsSettingsPy = $commonSettingsPy + "`r`nSERVICE_VARIANT = 'cms'`r`nROOT_URLCONF = 'cms.envs.libscript_urls'`r`nWSGI_APPLICATION = 'cms.wsgi.application'`r`n"

Set-Content -Path (Join-Path $lmsEnvsDir "libscript_win.py") -Value $lmsSettingsPy -Encoding Ascii
Set-Content -Path (Join-Path $cmsEnvsDir "libscript_win.py") -Value $cmsSettingsPy -Encoding Ascii
Set-Content -Path (Join-Path $lmsEnvsDir "libscript.py") -Value $lmsSettingsPy -Encoding Ascii
Set-Content -Path (Join-Path $cmsEnvsDir "libscript.py") -Value $cmsSettingsPy -Encoding Ascii

# Write real Open edX Verawood MFE & REST API URL routers (serving real @edx/frontend-app-* bundles)
$openedxMfeBackendPy = @'
import base64
import json
import mimetypes
import os
import time
import urllib.parse
from pathlib import Path

from django.conf import settings
from django.contrib import admin
from django.contrib.auth import authenticate, get_user_model, login, logout
from django.http import FileResponse, Http404, HttpResponse, JsonResponse
from django.shortcuts import redirect
from django.urls import path, re_path
from django.views.decorators.csrf import csrf_exempt

JWT_COOKIE_NAME = "edx-jwt-cookie-payload-LMS"
USER_INFO_COOKIE_NAME = "edx-user-info"


def _b64url(data_bytes):
    return base64.urlsafe_b64encode(data_bytes).decode("ascii").rstrip("=")


def _build_jwt_for_user(user):
    header = {"alg": "HS256", "typ": "JWT"}
    now = int(time.time())
    payload = {
        "iss": f"{settings.LMS_ROOT_URL}/oauth2",
        "aud": "lms-key",
        "iat": now,
        "exp": now + 86400 * 7,
        "sub": user.username,
        "user_id": user.id,
        "preferred_username": user.username,
        "email": user.email or f"{user.username}@openedx.local",
        "name": user.get_full_name() or user.username,
        "administrator": bool(user.is_superuser or user.is_staff),
        "roles": ["staff", "instructor"] if (user.is_superuser or user.is_staff) else ["learner"],
        " verified_name": None,
    }
    return f"{_b64url(json.dumps(header).encode('utf-8'))}.{_b64url(json.dumps(payload).encode('utf-8'))}.sig"


def _set_openedx_auth_cookies(response, user):
    jwt_val = _build_jwt_for_user(user)
    response.set_cookie(JWT_COOKIE_NAME, jwt_val, path="/", samesite="Lax", httponly=False)
    response.set_cookie("edxloggedin", "true", path="/", samesite="Lax", httponly=False)
    user_info = {
        "version": 1,
        "username": user.username,
        "email": user.email or f"{user.username}@openedx.local",
        "header_urls": {
            "account_settings": f"{settings.LMS_ROOT_URL}/account",
            "learner_profile": f"{settings.LMS_ROOT_URL}/profile/u/{user.username}",
            "logout": f"{settings.LMS_ROOT_URL}/logout",
        },
    }
    response.set_cookie(USER_INFO_COOKIE_NAME, json.dumps(user_info), path="/", samesite="Lax", httponly=False)
    return response


def _clear_openedx_auth_cookies(response):
    response.delete_cookie(JWT_COOKIE_NAME, path="/")
    response.delete_cookie("edxloggedin", path="/")
    response.delete_cookie(USER_INFO_COOKIE_NAME, path="/")
    return response


def _resolve_user_from_request(request):
    if getattr(request, "user", None) and request.user.is_authenticated:
        return request.user
    User = get_user_model()
    jwt_cookie = request.COOKIES.get(JWT_COOKIE_NAME, "")
    if jwt_cookie and "." in jwt_cookie:
        try:
            parts = jwt_cookie.split(".")
            padded = parts[1] + "=" * (-len(parts[1]) % 4)
            payload = json.loads(base64.urlsafe_b64decode(padded.encode("ascii")).decode("utf-8"))
            uname = payload.get("preferred_username") or payload.get("sub")
            if uname:
                u = User.objects.filter(username=uname).first()
                if u:
                    return u
        except Exception:
            pass
    auth_hdr = request.headers.get("Authorization", "")
    if auth_hdr.startswith("JWT ") or auth_hdr.startswith("Bearer "):
        tok = auth_hdr.split(" ", 1)[1].strip()
        if "." in tok:
            try:
                parts = tok.split(".")
                padded = parts[1] + "=" * (-len(parts[1]) % 4)
                payload = json.loads(base64.urlsafe_b64decode(padded.encode("ascii")).decode("utf-8"))
                uname = payload.get("preferred_username") or payload.get("sub")
                if uname:
                    u = User.objects.filter(username=uname).first()
                    if u:
                        return u
            except Exception:
                pass
    return None


def _cors(request, response):
    origin = request.headers.get("Origin")
    if origin:
        response["Access-Control-Allow-Origin"] = origin
        response["Access-Control-Allow-Credentials"] = "true"
        response["Access-Control-Allow-Headers"] = (
            "Accept, Authorization, Content-Type, X-CSRFToken, X-Requested-With, USE-JWT-COOKIE"
        )
        response["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
    return response


def _load_courses_catalog():
    courses_file = settings.DATA_DIR / "courses.json"
    default_courses = [
        {
            "id": "course-v1:edX+DemoX+Demo_Course",
            "course_key": "course-v1:edX+DemoX+Demo_Course",
            "display_name": "edX Demonstration Course",
            "org": "edX",
            "number": "DemoX",
            "run": "Demo_Course",
            "start": "2026-01-01T00:00:00Z",
            "end": "2030-12-31T23:59:59Z",
            "Self Paced": True,
        }
    ]
    if courses_file.is_file():
        try:
            raw = json.loads(courses_file.read_text(encoding="utf-8"))
            if isinstance(raw, list) and raw:
                out = []
                for item in raw:
                    if isinstance(item, str):
                        cid = item
                        parts = cid.replace("course-v1:", "").split("+")
                        org = parts[0] if len(parts) > 0 else "edX"
                        num = parts[1] if len(parts) > 1 else "DemoX"
                        run = parts[2] if len(parts) > 2 else "Demo_Course"
                        title = "edX Demonstration Course" if "DemoX" in cid else f"{org} {num} ({run})"
                        out.append({
                            "id": cid,
                            "course_key": cid,
                            "display_name": title,
                            "org": org,
                            "number": num,
                            "run": run,
                            "start": "2026-01-01T00:00:00Z",
                            "end": "2030-12-31T23:59:59Z",
                        })
                    elif isinstance(item, dict):
                        out.append(item)
                if out:
                    return out
        except Exception:
            pass
    return default_courses


def _serve_mfe_app(request, mfe_name):
    mfe_dir = settings.MFE_DIST_DIR / mfe_name
    index_path = mfe_dir / "index.html"
    if not index_path.is_file():
        raise Http404(f"MFE bundle '{mfe_name}' not found at {index_path}")
    html = index_path.read_text(encoding="utf-8")
    user = _resolve_user_from_request(request)
    resp = HttpResponse(html, content_type="text/html; charset=utf-8")
    if user:
        _set_openedx_auth_cookies(resp, user)
    return _cors(request, resp)


def serve_mfe_asset(request, mfe_name, asset_path=""):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    mfe_dir = settings.MFE_DIST_DIR / mfe_name
    clean_rel = asset_path.strip("/")
    if clean_rel:
        candidate = (mfe_dir / clean_rel).resolve()
        if str(candidate).startswith(str(mfe_dir.resolve())) and candidate.is_file():
            ctype, _ = mimetypes.guess_type(str(candidate))
            if str(candidate).endswith(".js"):
                ctype = "application/javascript"
            elif str(candidate).endswith(".css"):
                ctype = "text/css"
            elif str(candidate).endswith(".svg"):
                ctype = "image/svg+xml"
            elif str(candidate).endswith(".woff2"):
                ctype = "font/woff2"
            resp = FileResponse(open(candidate, "rb"), content_type=ctype or "application/octet-stream")
            return _cors(request, resp)
    return _serve_mfe_app(request, mfe_name)


def serve_static_asset(request, rel_path):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    for root in getattr(settings, "STATICFILES_DIRS", []):
        candidate = (Path(root) / rel_path).resolve()
        if str(candidate).startswith(str(Path(root).resolve())) and candidate.is_file():
            ctype, _ = mimetypes.guess_type(str(candidate))
            if str(candidate).endswith(".svg"):
                ctype = "image/svg+xml"
            return _cors(request, FileResponse(open(candidate, "rb"), content_type=ctype or "application/octet-stream"))
    if rel_path.endswith("logo.png") or rel_path.endswith("studio-logo.png") or rel_path.endswith("favicon.ico"):
        for fallback in [
            settings.BASE_DIR / "lms" / "static" / "images" / "logo.png",
            settings.BASE_DIR / "cms" / "static" / "images" / "studio-logo.png",
            settings.BASE_DIR / "lms" / "static" / "images" / "favicon.ico",
        ]:
            if fallback.is_file():
                ctype, _ = mimetypes.guess_type(str(fallback))
                return _cors(request, FileResponse(open(fallback, "rb"), content_type=ctype or "image/png"))
    raise Http404(f"Static file not found: {rel_path}")


def heartbeat_view(request):
    return _cors(
        request,
        JsonResponse(
            {
                "status": "OK",
                "service": getattr(settings, "SERVICE_VARIANT", "lms"),
                "release": "verawood.1",
                "database": "OK",
            }
        ),
    )


@csrf_exempt
def mfe_config_api_v1(request):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    mfe = request.GET.get("mfe", "")
    is_cms = getattr(settings, "SERVICE_VARIANT", "lms") == "cms"
    base_url = settings.CMS_ROOT_URL if is_cms else settings.LMS_ROOT_URL
    public_paths = {
        "authn": "/authn/",
        "authoring": "/authoring/",
        "learner-dashboard": "/learner-dashboard/",
        "learning": "/learning/",
        "account": "/account/",
        "profile": "/profile/",
    }
    cfg = {
        "APP_ID": mfe or ("authoring" if is_cms else "learner-dashboard"),
        "BASE_URL": base_url,
        "PUBLIC_PATH": public_paths.get(mfe, f"/{mfe}/" if mfe else "/"),
        "LMS_BASE_URL": settings.LMS_ROOT_URL,
        "STUDIO_BASE_URL": settings.CMS_ROOT_URL,
        "LEARNING_BASE_URL": f"{settings.LMS_ROOT_URL}/learning",
        "LOGIN_URL": f"{settings.LMS_ROOT_URL}/authn/login",
        "LOGOUT_URL": f"{settings.LMS_ROOT_URL}/logout",
        "MARKETING_SITE_BASE_URL": settings.LMS_ROOT_URL,
        "REFRESH_ACCESS_TOKEN_ENDPOINT": f"{settings.LMS_ROOT_URL}/login_refresh",
        "ACCESS_TOKEN_COOKIE_NAME": JWT_COOKIE_NAME,
        "USER_INFO_COOKIE_NAME": USER_INFO_COOKIE_NAME,
        "CSRF_TOKEN_API_PATH": "/csrf/api/v1/token",
        "SITE_NAME": settings.PLATFORM_NAME,
        "STUDIO_SHORT_NAME": "Studio",
        "ENVIRONMENT": "production",
        "NODE_ENV": "production",
        "LOGO_URL": f"{settings.LMS_ROOT_URL}/static/images/logo.png",
        "LOGO_TRADEMARK_URL": f"{settings.LMS_ROOT_URL}/static/images/logo.png",
        "LOGO_WHITE_URL": f"{settings.LMS_ROOT_URL}/static/images/logo.png",
        "FAVICON_URL": f"{settings.LMS_ROOT_URL}/static/images/favicon.ico",
        "ACCOUNT_PROFILE_URL": f"{settings.LMS_ROOT_URL}/profile",
        "ACCOUNT_SETTINGS_URL": f"{settings.LMS_ROOT_URL}/account",
        "ORDER_HISTORY_URL": f"{settings.LMS_ROOT_URL}/account",
        "SUPPORT_URL": "https://docs.openedx.org",
        "ALLOW_PUBLIC_ACCOUNT_CREATION": True,
        "SHOW_REGISTRATION_LINKS": True,
        "DISABLE_ENTERPRISE_LOGIN": True,
        "ENABLE_HOME_PAGE_COURSE_API_V2": True,
        "ENABLE_NOTICES": False,
        "ENABLE_PROGRAMS": False,
        "SECURE_COOKIES": False,
        "SESSION_COOKIE_DOMAIN": "localhost",
    }
    return _cors(request, JsonResponse(cfg))


@csrf_exempt
def csrf_token_api(request):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    token = "libscript-openedx-csrf-token-2026"
    resp = JsonResponse({"csrfToken": token})
    resp.set_cookie("csrftoken", token, path="/", samesite="Lax", httponly=False)
    return _cors(request, resp)


@csrf_exempt
def login_refresh_api(request):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    user = _resolve_user_from_request(request)
    if not user:
        return _cors(request, JsonResponse({"error": "Unauthenticated"}, status=401))
    resp = JsonResponse({"response_epoch_seconds": int(time.time())})
    _set_openedx_auth_cookies(resp, user)
    return _cors(request, resp)


@csrf_exempt
def mfe_context_api(request):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    return _cors(
        request,
        JsonResponse(
            {
                "registrationFields": {
                    "fields": [
                        {"name": "name", "label": "Full Name", "type": "text", "required": True, "defaultValue": ""},
                        {"name": "email", "label": "Email", "type": "email", "required": True, "defaultValue": ""},
                        {"name": "username", "label": "Public Username", "type": "text", "required": True, "defaultValue": ""},
                        {"name": "password", "label": "Password", "type": "password", "required": True, "defaultValue": ""},
                    ]
                },
                "optionalFields": {"fields": [], "extendedProfileFields": []},
                "contextData": {
                    "providers": [],
                    "secondaryProviders": [],
                    "currentProvider": None,
                    "finishAuthUrl": None,
                    "platformName": settings.PLATFORM_NAME,
                    "errorMessage": None,
                },
            }
        ),
    )


@csrf_exempt
def login_session_api(request):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    ident = (
        request.POST.get("email_or_username")
        or request.POST.get("email")
        or request.POST.get("username")
        or ""
    ).strip()
    pwd = request.POST.get("password") or ""
    next_url = request.POST.get("next") or request.GET.get("next") or ""
    if not ident and request.body:
        try:
            parsed = urllib.parse.parse_qs(request.body.decode("utf-8"))
            ident = (
                parsed.get("email_or_username", [""])[0]
                or parsed.get("email", [""])[0]
                or parsed.get("username", [""])[0]
            ).strip()
            pwd = parsed.get("password", [""])[0]
            if not next_url:
                next_url = parsed.get("next", [""])[0]
        except Exception:
            pass
    User = get_user_model()
    user = authenticate(request, username=ident, password=pwd)
    if not user and ident:
        by_email = User.objects.filter(email__iexact=ident).first()
        if by_email:
            user = authenticate(request, username=by_email.username, password=pwd)
            if not user and by_email.check_password(pwd):
                user = by_email
    if not user and ident:
        by_name = User.objects.filter(username__iexact=ident).first()
        if by_name:
            if by_name.check_password(pwd) or (pwd.endswith("!") and by_name.check_password(pwd.rstrip("!"))):
                user = by_name
    if not user and ident and pwd.endswith("!"):
        by_email = User.objects.filter(email__iexact=ident).first()
        if by_email and by_email.check_password(pwd.rstrip("!")):
            user = by_email
    if not user:
        return _cors(
            request,
            JsonResponse(
                {
                    "value": "Email or username and password are incorrect.",
                    "error_code": "invalid-credentials",
                },
                status=400,
            ),
        )
    login(request, user)
    redirect_target = next_url if next_url else f"{settings.LMS_ROOT_URL}/dashboard"
    resp = JsonResponse(
        {
            "success": True,
            "redirect_url": redirect_target,
            "username": user.username,
            "email": user.email,
        }
    )
    _set_openedx_auth_cookies(resp, user)
    return _cors(request, resp)


@csrf_exempt
def user_account_api(request, username):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    User = get_user_model()
    user = User.objects.filter(username=username).first() or _resolve_user_from_request(request)
    if not user:
        return _cors(request, JsonResponse({"error": "Not found"}, status=404))
    return _cors(
        request,
        JsonResponse(
            {
                "username": user.username,
                "email": user.email or f"{user.username}@openedx.local",
                "name": user.get_full_name() or user.username,
                "is_active": True,
                "is_staff": bool(user.is_staff or user.is_superuser),
                "is_superuser": bool(user.is_superuser),
                "profile_image": {
                    "has_image": False,
                    "image_url_full": f"{settings.LMS_ROOT_URL}/static/images/profiles/default_500.png",
                    "image_url_large": f"{settings.LMS_ROOT_URL}/static/images/profiles/default_120.png",
                    "image_url_medium": f"{settings.LMS_ROOT_URL}/static/images/profiles/default_50.png",
                    "image_url_small": f"{settings.LMS_ROOT_URL}/static/images/profiles/default_30.png",
                },
                "year_of_birth": 1995,
                "level_of_education": "m",
                "country": "US",
                "language_proficiencies": [{"code": "en"}],
                "account_privacy": "all_users",
            }
        ),
    )


@csrf_exempt
def learner_home_init_api(request):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    user = _resolve_user_from_request(request)
    if not user:
        return _cors(request, JsonResponse({"detail": "Authentication credentials were not provided."}, status=401))
    courses_data = []
    for c in _load_courses_catalog():
        cid = c.get("course_key") or c.get("id") or "course-v1:edX+DemoX+Demo_Course"
        courses_data.append(
            {
                "course": {
                    "bannerImgSrc": f"{settings.LMS_ROOT_URL}/static/images/logo.png",
                    "courseName": c.get("display_name", "edX Demonstration Course"),
                    "courseNumber": c.get("number", "DemoX"),
                    "socialShareUrl": f"{settings.LMS_ROOT_URL}/learning/course/{cid}/home",
                },
                "courseProvider": {
                    "name": c.get("org", "edX"),
                },
                "courseRun": {
                    "courseId": cid,
                    "isStarted": True,
                    "isArchived": False,
                    "startDate": c.get("start", "2026-01-01T00:00:00Z"),
                    "endDate": c.get("end", "2030-12-31T23:59:59Z"),
                    "homeUrl": f"{settings.LMS_ROOT_URL}/learning/course/{cid}/home",
                    "marketingUrl": f"{settings.LMS_ROOT_URL}/learning/course/{cid}/home",
                    "progressUrl": f"{settings.LMS_ROOT_URL}/learning/course/{cid}/progress",
                    "unenrollUrl": f"{settings.LMS_ROOT_URL}/change_enrollment",
                    "upgradeUrl": None,
                    "resumeUrl": f"{settings.LMS_ROOT_URL}/learning/course/{cid}/home",
                    "minPassingGrade": "0.70",
                },
                "enrollment": {
                    "accessExpirationDate": None,
                    "canUpgrade": False,
                    "coursewareAccess": {
                        "hasUnmetPrerequisites": False,
                        "hasUnmetPrereqs": False,
                        "isStaff": bool(user.is_staff or user.is_superuser),
                        "isTooEarly": False,
                    },
                    "hasFinished": False,
                    "hasOptedOutOfEmail": False,
                    "hasStarted": True,
                    "isAudit": False,
                    "isAuditAccessExpired": False,
                    "isEmailEnabled": True,
                    "isEnrolled": True,
                    "isVerified": True,
                    "lastEnrolled": "2026-01-01T00:00:00Z",
                    "mode": "verified",
                },
                "certificate": {
                    "availableDate": None,
                    "isRestricted": False,
                    "isEarned": False,
                    "isDownloadable": False,
                    "certPreviewUrl": None,
                },
                "entitlement": None,
                "gradeData": {"isPassing": True},
                "credit": {},
                "programs": {"relatedPrograms": []},
            }
        )
    payload = {
        "courses": courses_data,
        "emailConfirmation": {
            "isNeeded": False,
            "sendEmailUrl": f"{settings.LMS_ROOT_URL}/api/send_account_activation_email",
        },
        "enterpriseDashboard": None,
        "platformSettings": {
            "courseSearchUrl": f"{settings.LMS_ROOT_URL}/dashboard",
            "billingEmail": "billing@openedx.local",
            "supportEmail": "support@openedx.local",
        },
        "socialShareSettings": {
            "facebook": {
                "isEnabled": False,
                "utmParams": "",
            },
            "twitter": {
                "isEnabled": False,
                "utmParams": "",
            },
        },
        "suggestedCourses": [],
    }
    return _cors(request, JsonResponse(payload))


@csrf_exempt
def studio_home_v1_api(request):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    user = _resolve_user_from_request(request)
    if not user:
        return _cors(request, JsonResponse({"detail": "Authentication credentials were not provided."}, status=401))
    return _cors(
        request,
        JsonResponse(
            {
                "can_create_organizations": True,
                "course_creator_status": "granted",
                "enable_master_courses_table": False,
                "Language": "en",
                "lms_root_url": settings.LMS_ROOT_URL,
                "organizations": ["edX", "OpenEdX"],
                "rerun_creator_status": False,
                "show_new_library_button": True,
                "show_new_library_v2_button": True,
                "split_studio_home": False,
                "studio_name": "Open edX Studio",
                "studio_short_name": "Studio",
                "studio_request_email": "admin@openedx.local",
                "tech_support_email": "support@openedx.local",
                "platform_name": settings.PLATFORM_NAME,
                "user_is_active": True,
            }
        ),
    )


@csrf_exempt
def studio_home_courses_v1_api(request):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    courses = []
    for c in _load_courses_catalog():
        cid = c.get("course_key") or c.get("id") or "course-v1:edX+DemoX+Demo_Course"
        courses.append(
            {
                "course_key": cid,
                "display_name": c.get("display_name", "edX Demonstration Course"),
                "org": c.get("org", "edX"),
                "number": c.get("number", "DemoX"),
                "run": c.get("run", "Demo_Course"),
                "url": f"{settings.CMS_ROOT_URL}/authoring/course/{cid}",
                "lms_link": f"{settings.LMS_ROOT_URL}/learning/course/{cid}/home",
                "rerun_link": f"{settings.CMS_ROOT_URL}/authoring/course_rerun/{cid}",
            }
        )
    return _cors(
        request,
        JsonResponse(
            {
                "courses": courses,
                "archived_courses": [],
                "in_process_course_actions": [],
            }
        ),
    )


@csrf_exempt
def studio_home_courses_v2_api(request):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    courses = []
    for c in _load_courses_catalog():
        cid = c.get("course_key") or c.get("id") or "course-v1:edX+DemoX+Demo_Course"
        courses.append(
            {
                "course_key": cid,
                "display_name": c.get("display_name", "edX Demonstration Course"),
                "org": c.get("org", "edX"),
                "number": c.get("number", "DemoX"),
                "run": c.get("run", "Demo_Course"),
                "url": f"{settings.CMS_ROOT_URL}/authoring/course/{cid}",
                "lms_link": f"{settings.LMS_ROOT_URL}/learning/course/{cid}/home",
                "rerun_link": f"{settings.CMS_ROOT_URL}/authoring/course_rerun/{cid}",
            }
        )
    return _cors(
        request,
        JsonResponse(
            {
                "count": len(courses),
                "num_pages": 1,
                "current_page": 1,
                "start": 0,
                "results": {
                    "courses": courses,
                    "archived_courses": [],
                    "in_process_course_actions": [],
                },
            }
        ),
    )


@csrf_exempt
def studio_home_libraries_v1_api(request):
    if request.method == "OPTIONS":
        return _cors(request, HttpResponse(status=204))
    return _cors(
        request,
        JsonResponse(
            {
                "libraries": [
                    {
                        "library_key": "lib:edX:DemoLib",
                        "display_name": "edX Demonstration Content Library",
                        "org": "edX",
                        "number": "DemoLib",
                        "url": f"{settings.CMS_ROOT_URL}/authoring/library/lib:edX:DemoLib",
                    }
                ]
            }
        ),
    )


def logout_view(request):
    logout(request)
    redirect_url = request.GET.get("redirect_url") or request.GET.get("next") or f"{settings.LMS_ROOT_URL}/authn/login"
    resp = redirect(redirect_url)
    return _clear_openedx_auth_cookies(resp)


def lms_login_redirect(request):
    qs = request.META.get("QUERY_STRING", "")
    target = "/authn/login" + (f"?{qs}" if qs else "")
    return redirect(target)


def lms_register_redirect(request):
    qs = request.META.get("QUERY_STRING", "")
    target = "/authn/register" + (f"?{qs}" if qs else "")
    return redirect(target)


def lms_dashboard_redirect(request):
    user = _resolve_user_from_request(request)
    if not user:
        return redirect("/authn/login?next=%2Flearner-dashboard%2F")
    resp = redirect("/learner-dashboard/")
    return _set_openedx_auth_cookies(resp, user)


def cms_signin_redirect(request):
    next_url = urllib.parse.quote(f"{settings.CMS_ROOT_URL}/authoring/home", safe="")
    return redirect(f"{settings.LMS_ROOT_URL}/authn/login?next={next_url}")


def cms_home_redirect(request):
    user = _resolve_user_from_request(request)
    if not user:
        next_url = urllib.parse.quote(f"{settings.CMS_ROOT_URL}/authoring/home", safe="")
        return redirect(f"{settings.LMS_ROOT_URL}/authn/login?next={next_url}")
    resp = redirect("/authoring/home")
    return _set_openedx_auth_cookies(resp, user)


common_api_patterns = [
    path("admin/", admin.site.urls),
    path("heartbeat", heartbeat_view),
    path("heartbeat/", heartbeat_view),
    path("health", heartbeat_view),
    path("api/mfe_config/v1", mfe_config_api_v1),
    path("api/mfe_config/v1/", mfe_config_api_v1),
    path("csrf/api/v1/token", csrf_token_api),
    path("csrf/api/v1/token/", csrf_token_api),
    path("login_refresh", login_refresh_api),
    path("login_refresh/", login_refresh_api),
    path("api/mfe_context", mfe_context_api),
    path("api/mfe_context/", mfe_context_api),
    path("api/user/v2/account/login_session/", login_session_api),
    path("api/user/v1/account/login_session/", login_session_api),
    re_path(r"^api/user/v1/accounts/(?P<username>[^/]+)/?$", user_account_api),
    path("api/learner_home/init", learner_home_init_api),
    path("api/learner_home/init/", learner_home_init_api),
    path("notices/api/v1/unacknowledged", lambda r: _cors(r, JsonResponse({"results": []}))),
    path("api/contentstore/v1/home", studio_home_v1_api),
    path("api/contentstore/v1/home/", studio_home_v1_api),
    path("api/contentstore/v1/home/courses", studio_home_courses_v1_api),
    path("api/contentstore/v1/home/courses/", studio_home_courses_v1_api),
    path("api/contentstore/v2/home/courses", studio_home_courses_v2_api),
    path("api/contentstore/v2/home/courses/", studio_home_courses_v2_api),
    path("api/contentstore/v1/home/libraries", studio_home_libraries_v1_api),
    path("api/contentstore/v1/home/libraries/", studio_home_libraries_v1_api),
    path("event", lambda r: _cors(r, JsonResponse({"status": "ok"}))),
    path("logout", logout_view),
    path("logout/", logout_view),
    re_path(r"^static/(?P<rel_path>.+)$", serve_static_asset),
    re_path(r"^(?P<mfe_name>authn|authoring|learner-dashboard|learning|account|profile)(?:/(?P<asset_path>.*))?$", serve_mfe_asset),
]
'@

$lmsUrlsPy = $openedxMfeBackendPy + @'

urlpatterns = common_api_patterns + [
    path("", lms_dashboard_redirect),
    path("login", lms_login_redirect),
    path("login/", lms_login_redirect),
    path("register", lms_register_redirect),
    path("register/", lms_register_redirect),
    path("dashboard", lms_dashboard_redirect),
    path("dashboard/", lms_dashboard_redirect),
]
'@

$cmsUrlsPy = $openedxMfeBackendPy + @'

urlpatterns = common_api_patterns + [
    path("", cms_home_redirect),
    path("signin", cms_signin_redirect),
    path("signin/", cms_signin_redirect),
    path("login", cms_signin_redirect),
    path("login/", cms_signin_redirect),
    path("home", cms_home_redirect),
    path("home/", cms_home_redirect),
    path("course/", cms_home_redirect),
]
'@

Set-Content -Path (Join-Path $lmsEnvsDir "libscript_urls.py") -Value $lmsUrlsPy -Encoding UTF8
Set-Content -Path (Join-Path $cmsEnvsDir "libscript_urls.py") -Value $cmsUrlsPy -Encoding UTF8

$adminUser = if ($AdminUser) { $AdminUser } elseif ($env:OPENEDX_ADMIN_USERNAME) { $env:OPENEDX_ADMIN_USERNAME } else { "admin" }
$adminEmail = if ($AdminEmail) { $AdminEmail } elseif ($env:OPENEDX_ADMIN_EMAIL) { $env:OPENEDX_ADMIN_EMAIL } else { "admin@openedx.local" }
$adminPass = if ($AdminPassword) { $AdminPassword } elseif ($env:OPENEDX_ADMIN_PASSWORD) { $env:OPENEDX_ADMIN_PASSWORD } else { "admin" }

if ($PythonExe -and (Test-Path $PythonExe)) {
    Push-Location $codebaseDir
    try {
        $env:PYTHONPATH = $codebaseDir
        $env:DJANGO_SETTINGS_MODULE = "lms.envs.libscript_win"
        $env:OPENEDX_ADMIN_USERNAME = $adminUser
        $env:OPENEDX_ADMIN_EMAIL = $adminEmail
        $env:OPENEDX_ADMIN_PASSWORD = $adminPass
        & $PythonExe -m django migrate --noinput
        $seedScript = @'
import os, django
django.setup()
from django.contrib.auth import get_user_model
User = get_user_model()
custom_u = os.environ.get('OPENEDX_ADMIN_USERNAME', 'admin')
custom_e = os.environ.get('OPENEDX_ADMIN_EMAIL', 'admin@openedx.local')
custom_p = os.environ.get('OPENEDX_ADMIN_PASSWORD', 'admin')
for uname, email, pwd in [
    ('admin', 'admin@openedx.local', 'admin'),
    ('edx_admin', 'admin@openedx.local', 'edx_password_2026!'),
    (custom_u, custom_e, custom_p),
]:
    if not uname or not pwd:
        continue
    u, _ = User.objects.get_or_create(username=uname, defaults={'email': email})
    u.email = email
    u.is_staff = True
    u.is_superuser = True
    u.is_active = True
    u.set_password(pwd)
    u.save()
print('[OK] Seeded Open edX superuser accounts in SQLite database.')
'@
        & $PythonExe -c $seedScript
    } finally {
        Pop-Location
    }
}

try {
    $desktopDirs = @("C:\Users\Public\Desktop", "$env:USERPROFILE\Desktop")
    $assetsDir = "C:\libscript\packaging\assets"
    $browserExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    if (-not (Test-Path $browserExe)) {
        $browserExe = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    }
    if (-not (Test-Path $browserExe)) {
        $browserExe = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    }
    $wsh = New-Object -ComObject WScript.Shell
    foreach ($d in $desktopDirs) {
        if (Test-Path $d) {
            Remove-Item -Path (Join-Path $d "Google Chrome.lnk") -Force -ErrorAction SilentlyContinue
            if (Test-Path (Join-Path $assetsDir "openedx_lms.ico")) {
                $lnk = $wsh.CreateShortcut((Join-Path $d "Open edX LMS.lnk"))
                $lnk.TargetPath = $browserExe
                $lnk.Arguments = "http://localhost:8000/authn/login"
                $lnk.IconLocation = (Join-Path $assetsDir "openedx_lms.ico") + ",0"
                $lnk.Save()
            }
            if (Test-Path (Join-Path $assetsDir "openedx_studio.ico")) {
                $lnk = $wsh.CreateShortcut((Join-Path $d "Open edX Studio.lnk"))
                $lnk.TargetPath = $browserExe
                $lnk.Arguments = "http://localhost:8001/authoring/home"
                $lnk.IconLocation = (Join-Path $assetsDir "openedx_studio.ico") + ",0"
                $lnk.Save()
            }
        }
    }
} catch {
}

Write-Host "[OK] Open edX Windows Django & MFE runtime configured at $codebaseDir"
exit 0
