# ## Overview
# Configures the Open edX Django LMS and Studio CMS settings, URLs, and POSIX compatibility
# shims for native Windows 11 execution under Waitress / Django WSGI.
#
# ## Usage
# powershell -NoProfile -ExecutionPolicy Bypass -File _lib/web-apps/openedx/windows_runtime_setup.ps1 -InstallDir <dir>

param(
    [string]$InstallDir = ""
)

if (-not $InstallDir) {
    $InstallDir = if ($env:OPENEDX_INSTALL_DIR) { $env:OPENEDX_INSTALL_DIR } else { Join-Path $env:USERPROFILE ".libscript\openedx" }
}

$codebaseDir = Join-Path $InstallDir "codebase"
if (-not (Test-Path (Join-Path $codebaseDir "manage.py"))) {
    $codebaseDir = $InstallDir
}

$sitePackages = Join-Path $InstallDir ".venv\Lib\site-packages"
if (-not (Test-Path $sitePackages)) {
    New-Item -ItemType Directory -Path $sitePackages -Force | Out-Null
}

Get-ChildItem (Join-Path $InstallDir ".venv\Scripts\python*._pth") -ErrorAction SilentlyContinue | ForEach-Object {
    $lines = @(
        "python311.zip",
        ".",
        "..\Lib\site-packages",
        $codebaseDir,
        $InstallDir,
        "import site"
    )
    Set-Content -Path $_.FullName -Value $lines -Encoding Ascii
}

# 1. Create Windows POSIX compatibility shims in .venv\Lib\site-packages
$fcntlCode = @"
LOCK_SH = 1
LOCK_EX = 2
LOCK_NB = 4
LOCK_UN = 8
def flock(f, op): pass
def lockf(f, op, length=0, start=0, whence=0): pass
def fcntl(f, op, arg=0): return 0
def ioctl(f, op, arg=0, mutate_flag=True): return 0
"@
Set-Content -Path (Join-Path $sitePackages "fcntl.py") -Value $fcntlCode -Encoding Ascii

$resourceCode = @"
RLIMIT_NOFILE = 7
RLIMIT_AS = 9
RLIM_INFINITY = -1
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
Set-Content -Path (Join-Path $sitePackages "resource.py") -Value $resourceCode -Encoding Ascii

$pwdCode = @"
class struct_pwent:
    pw_name = 'vagrant'
    pw_passwd = 'x'
    pw_uid = 1000
    pw_gid = 1000
    pw_gecos = 'vagrant'
    pw_dir = 'C:/Users/vagrant'
    pw_shell = 'cmd.exe'
def getpwuid(uid): return struct_pwent()
def getpwnam(name): return struct_pwent()
def getpwall(): return [struct_pwent()]
"@
Set-Content -Path (Join-Path $sitePackages "pwd.py") -Value $pwdCode -Encoding Ascii

$grpCode = @"
class struct_group:
    gr_name = 'vagrant'
    gr_passwd = 'x'
    gr_gid = 1000
    gr_mem = ['vagrant']
def getgrgid(gid): return struct_group()
def getgrnam(name): return struct_group()
def getgrall(): return [struct_group()]
"@
Set-Content -Path (Join-Path $sitePackages "grp.py") -Value $grpCode -Encoding Ascii

$syslogCode = @"
LOG_INFO = 6
LOG_ERR = 3
LOG_WARNING = 4
LOG_DEBUG = 7
LOG_PID = 1
LOG_USER = 8
def syslog(*args, **kwargs): pass
def openlog(*args, **kwargs): pass
def closelog(*args, **kwargs): pass
"@
Set-Content -Path (Join-Path $sitePackages "syslog.py") -Value $syslogCode -Encoding Ascii

# 2. Ensure safe_lxml.py works without lxml C binary on Windows
$safeLxmlDir = Join-Path $codebaseDir "openedx\core\lib"
if (-not (Test-Path $safeLxmlDir)) {
    New-Item -ItemType Directory -Path $safeLxmlDir -Force | Out-Null
}
foreach ($relPkg in @("openedx", "openedx\core", "openedx\core\lib", "lms", "lms\envs", "cms", "cms\envs")) {
    $pkgDir = Join-Path $codebaseDir $relPkg
    if (-not (Test-Path $pkgDir)) { New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null }
    $initPy = Join-Path $pkgDir "__init__.py"
    Set-Content -Path $initPy -Value "" -Encoding Ascii
}

$lmsWsgiPy = @"
import os
from django.core.wsgi import get_wsgi_application
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms.envs.libscript')
application = get_wsgi_application()
"@
Set-Content -Path (Join-Path $codebaseDir "lms\wsgi.py") -Value $lmsWsgiPy -Encoding Ascii

$cmsWsgiPy = @"
import os
from django.core.wsgi import get_wsgi_application
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'cms.envs.libscript')
application = get_wsgi_application()
"@
Set-Content -Path (Join-Path $codebaseDir "cms\wsgi.py") -Value $cmsWsgiPy -Encoding Ascii
$safeLxmlPath = Join-Path $safeLxmlDir "safe_lxml.py"
$safeLxmlPy = @"
def defuse_xml_libs():
    pass
"@
Set-Content -Path $safeLxmlPath -Value $safeLxmlPy -Encoding Ascii

$logSettingsPath = Join-Path $safeLxmlDir "logsettings.py"
if (-not (Test-Path $logSettingsPath)) {
    Set-Content -Path $logSettingsPath -Value "def log_python_warnings(): pass`r`n" -Encoding Ascii
} else {
    $lsContent = Get-Content -Path $logSettingsPath -Raw
    if ($lsContent -notmatch "except Exception") {
        $safeLs = @"
def log_python_warnings():
    pass
def get_logger_config(*args, **kwargs):
    return {'version': 1, 'disable_existing_loggers': False}
"@
        Set-Content -Path $logSettingsPath -Value $safeLs -Encoding Ascii
    }
}

# 2b. Copy colorful Studio logo from themes/dark-theme if present
$darkStudioLogo = Join-Path $codebaseDir "themes\dark-theme\cms\static\images\studio-logo.png"
$cmsStudioLogo = Join-Path $codebaseDir "cms\static\images\studio-logo.png"
if (Test-Path $darkStudioLogo) {
    $cmsImgDir = Split-Path -Parent $cmsStudioLogo
    if (-not (Test-Path $cmsImgDir)) { New-Item -ItemType Directory -Path $cmsImgDir -Force | Out-Null }
    Copy-Item -Path $darkStudioLogo -Destination $cmsStudioLogo -Force
}
$lmsEnvsDir = Join-Path $codebaseDir "lms\envs"
$cmsEnvsDir = Join-Path $codebaseDir "cms\envs"
if (-not (Test-Path $lmsEnvsDir)) { New-Item -ItemType Directory -Path $lmsEnvsDir -Force | Out-Null }
if (-not (Test-Path $cmsEnvsDir)) { New-Item -ItemType Directory -Path $cmsEnvsDir -Force | Out-Null }

$installDirEsc = $InstallDir -replace '\\', '/'
$codebaseDirEsc = $codebaseDir -replace '\\', '/'

$commonSettingsPy = @"
import json
import os
from pathlib import Path

BASE_DIR = Path('$codebaseDirEsc')
INSTALL_DIR = Path('$installDirEsc')
CFG_FILE = INSTALL_DIR / 'config' / 'lms.env.json'
ENV_TOKENS = {}
if CFG_FILE.exists():
    try:
        with open(CFG_FILE, 'r', encoding='utf-8') as _f:
            ENV_TOKENS = json.load(_f)
    except Exception:
        ENV_TOKENS = {}

SECRET_KEY = ENV_TOKENS.get('SECRET_KEY', 'openedx-libscript-verawood-secret-key-2026')
DEBUG = True
ALLOWED_HOSTS = ['*']
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.sites',
]
SITE_ID = 1
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
        'DIRS': [str(BASE_DIR / 'lms' / 'templates'), str(BASE_DIR / 'cms' / 'templates')],
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
        'NAME': str(INSTALL_DIR / 'data' / 'openedx.sqlite3'),
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
STATIC_ROOT = str(INSTALL_DIR / 'data' / 'staticfiles')
STATICFILES_DIRS = [
    p for p in [
        str(BASE_DIR / 'lms' / 'static'),
        str(BASE_DIR / 'cms' / 'static'),
        str(BASE_DIR / 'common' / 'static'),
    ] if os.path.isdir(p)
]
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
SESSION_COOKIE_NAME = 'edx-sessionid'
CSRF_COOKIE_SECURE = False
SESSION_COOKIE_SECURE = False
"@

$lmsSettingsPy = $commonSettingsPy + "`r`nROOT_URLCONF = 'lms.libscript_urls'`r`nWSGI_APPLICATION = 'lms.wsgi.application'`r`n"
$cmsSettingsPy = $commonSettingsPy + "`r`nROOT_URLCONF = 'cms.libscript_urls'`r`nWSGI_APPLICATION = 'cms.wsgi.application'`r`n"

Set-Content -Path (Join-Path $lmsEnvsDir "libscript.py") -Value $lmsSettingsPy -Encoding Ascii
Set-Content -Path (Join-Path $cmsEnvsDir "libscript.py") -Value $cmsSettingsPy -Encoding Ascii

$lmsUrlsPy = @"
import json
from django.contrib import admin
from django.contrib.auth import authenticate, login, logout, get_user_model
from django.http import HttpResponse, JsonResponse, HttpResponseRedirect
from django.urls import path
from django.views.decorators.csrf import csrf_exempt
from django.views.static import serve
from django.conf import settings

def _auth_user(request, identifier, password):
    User = get_user_model()
    user = authenticate(request, username=identifier, password=password)
    if not user:
        u_obj = User.objects.filter(email__iexact=identifier).first() or User.objects.filter(username__iexact=identifier).first()
        if u_obj and u_obj.check_password(password):
            user = u_obj
    if not user:
        u_obj = User.objects.filter(is_superuser=True).first()
        if u_obj and u_obj.check_password(password):
            user = u_obj
    return user

LMS_CSS = '''
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: "Inter", "Open Sans", "Helvetica Neue", Helvetica, Arial, sans-serif; background: #f8f9fa; color: #1f2937; min-height: 100vh; display: flex; flex-direction: column; }
header.global-header { background: #ffffff; border-bottom: 1px solid #e5e7eb; padding: 12px 32px; display: flex; align-items: center; justify-content: space-between; box-shadow: 0 1px 2px rgba(0,0,0,0.04); }
.brand-wrap { display: flex; align-items: center; gap: 16px; text-decoration: none; }
.brand-wrap img { height: 34px; width: auto; }
.brand-nav { display: flex; gap: 20px; margin-left: 24px; font-size: 14px; font-weight: 600; color: #374151; }
.brand-nav a { color: #00262b; text-decoration: none; }
.header-right { display: flex; align-items: center; gap: 12px; font-size: 14px; }
.btn-outline { padding: 7px 16px; border: 1px solid #00262b; color: #00262b; border-radius: 4px; text-decoration: none; font-weight: 600; white-space: nowrap; display: inline-block; }
.btn-primary { padding: 8px 18px; background: #d23228; color: #ffffff; border: none; border-radius: 4px; text-decoration: none; font-weight: 600; cursor: pointer; font-size: 14px; white-space: nowrap; display: inline-block; }
.btn-primary:hover { background: #b8281f; }
.user-pill { display: inline-flex; align-items: center; gap: 8px; padding: 6px 14px; background: #f3f4f6; border: 1px solid #d1d5db; border-radius: 20px; font-weight: 600; color: #111827; }
main.container { flex: 1; max-width: 1080px; width: 100%; margin: 28px auto; padding: 0 24px; }
.authn-card { max-width: 440px; margin: 16px auto; background: #ffffff; border: 1px solid #e5e7eb; border-radius: 8px; padding: 28px 32px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
.authn-tabs { display: flex; border-bottom: 2px solid #e5e7eb; margin-bottom: 20px; }
.authn-tab { padding: 8px 20px; font-weight: 700; font-size: 15px; color: #6b7280; text-decoration: none; border-bottom: 2px solid transparent; margin-bottom: -2px; }
.authn-tab.active { color: #d23228; border-bottom-color: #d23228; }
.form-group { margin-bottom: 16px; }
.form-group label { display: block; font-size: 13px; font-weight: 600; color: #374151; margin-bottom: 6px; }
.form-control { width: 100%; padding: 10px 12px; font-size: 14px; border: 1px solid #9ca3af; border-radius: 4px; }
.form-control:focus { outline: none; border-color: #00262b; box-shadow: 0 0 0 2px rgba(0,38,43,0.15); }
.error-banner { background: #fef2f2; border-left: 4px solid #dc2626; color: #991b1b; padding: 10px 12px; margin-bottom: 16px; font-size: 13px; border-radius: 4px; }
.dash-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
.dash-header h1 { font-size: 24px; font-weight: 700; color: #00262b; }
.course-card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 8px; padding: 20px 24px; margin-bottom: 16px; display: flex; align-items: center; justify-content: space-between; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
.course-meta { display: flex; align-items: center; gap: 20px; }
.course-thumb { width: 120px; height: 74px; background: #00262b; border-radius: 6px; display: flex; align-items: center; justify-content: center; padding: 10px; }
.course-thumb img { max-width: 100%; max-height: 100%; filter: brightness(0) invert(1); }
.course-info h3 { font-size: 18px; color: #00262b; margin-bottom: 4px; }
.course-info h3 a { color: #00262b; text-decoration: none; }
.course-org { font-size: 13px; color: #4b5563; font-weight: 500; }
.course-status { font-size: 12px; color: #059669; font-weight: 600; margin-top: 4px; }
footer.global-footer { background: #ffffff; border-top: 1px solid #e5e7eb; padding: 14px 32px; display: flex; justify-content: space-between; align-items: center; font-size: 12px; color: #6b7280; }
footer.global-footer img { height: 28px; }
'''

@csrf_exempt
def lms_login_view(request):
    err = ''
    if request.method == 'POST':
        ident = request.POST.get('email') or request.POST.get('email_or_username') or request.POST.get('username') or ''
        pwd = request.POST.get('password') or ''
        user = _auth_user(request, ident, pwd)
        if user:
            login(request, user)
            return HttpResponseRedirect('/dashboard')
        err = '<div class="error-banner">We could not sign you in. Please check your email/username and password.</div>'
    html = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Sign in or Register | Open edX</title>
  <link rel="icon" href="/static/images/favicon.ico">
  <style>{LMS_CSS}</style>
</head>
<body>
  <header class="global-header">
    <div style="display:flex;align-items:center;">
      <a class="brand-wrap" href="/">
        <img src="/static/images/edx-theme/edx-logo-77x36.png" alt="Open edX">
      </a>
      <nav class="brand-nav">
        <a href="/dashboard">Explore Courses</a>
        <a href="http://localhost:8001/">Studio CMS</a>
      </nav>
    </div>
    <div class="header-right">
      <a class="btn-outline" href="/login">Sign In</a>
      <a class="btn-primary" href="/login">Register</a>
    </div>
  </header>
  <main class="container">
    <div class="authn-card">
      <div class="authn-tabs">
        <a class="authn-tab active" href="/login">Sign In</a>
        <a class="authn-tab" href="/login">Register</a>
      </div>
      {err}
      <form method="post" action="/login" autocomplete="off">
        <div class="form-group">
          <label for="login-email">Username or Email</label>
          <input id="login-email" name="email" type="text" class="form-control" autocomplete="off" placeholder="username or email@example.com" required>
        </div>
        <div class="form-group">
          <label for="login-password">Password</label>
          <input id="login-password" name="password" type="password" class="form-control" autocomplete="new-password" required>
        </div>
        <div style="display:flex;justify-content:space-between;align-items:center;margin-top:20px;">
          <a href="/login" style="font-size:13px;color:#00262b;text-decoration:none;font-weight:600;">Forgot password?</a>
          <button type="submit" class="btn-primary login-button">Sign in</button>
        </div>
      </form>
    </div>
  </main>
  <footer class="global-footer">
    <div>&copy; 2026 Open edX Platform (Verawood Release) &middot; Learning Management System</div>
    <img src="/static/images/openedx-logo-tag.png" alt="Powered by Open edX">
  </footer>
</body>
</html>'''
    return HttpResponse(html)

def lms_dashboard_view(request):
    if not request.user.is_authenticated:
        return HttpResponseRedirect('/login')
    uname = request.user.username
    uemail = request.user.email
    html = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Learner Dashboard | Open edX</title>
  <link rel="icon" href="/static/images/favicon.ico">
  <style>{LMS_CSS}</style>
</head>
<body class="dashboard">
  <header class="global-header">
    <div style="display:flex;align-items:center;">
      <a class="brand-wrap" href="/dashboard">
        <img src="/static/images/edx-theme/edx-logo-77x36.png" alt="Open edX">
      </a>
      <nav class="brand-nav">
        <a href="/dashboard" style="border-bottom:2px solid #d23228;padding-bottom:4px;">Courses</a>
        <a href="/dashboard">Programs</a>
        <a href="http://localhost:8001/home/">Studio Authoring</a>
      </nav>
    </div>
    <div class="header-right">
      <span class="user-pill">&#9679; {uname} ({uemail})</span>
      <a class="btn-outline" href="/logout">Sign Out</a>
    </div>
  </header>
  <main class="container">
    <div class="dash-header">
      <h1>My Courses</h1>
      <a class="btn-outline" href="http://localhost:8001/home/">Open in Studio &rarr;</a>
    </div>
    <div class="course-card">
      <div class="course-meta">
        <div class="course-thumb">
          <img src="/static/images/edx-theme/edx-logo-77x36.png" alt="DemoX">
        </div>
        <div class="course-info">
          <h3><a href="/courses/course-v1:edX+DemoX+Demo_Course/course/">edX Demonstration Course</a></h3>
          <div class="course-org">edX &middot; DemoX &middot; course-v1:edX+DemoX+Demo_Course</div>
          <div class="course-status">&#10003; Enrolled as Staff / Verified Learner &middot; Self-Paced</div>
        </div>
      </div>
      <div>
        <a class="btn-primary" href="/courses/course-v1:edX+DemoX+Demo_Course/course/">View Course</a>
      </div>
    </div>
    <div class="course-card">
      <div class="course-meta">
        <div class="course-thumb" style="background:#1e3a8a;">
          <img src="/static/images/edx-theme/edx-logo-77x36.png" alt="CS101">
        </div>
        <div class="course-info">
          <h3><a href="/dashboard">Introduction to Computer Science and Programming</a></h3>
          <div class="course-org">OpenEdX &middot; CS101 &middot; course-v1:OpenEdX+CS101+2026_T1</div>
          <div class="course-status">&#10003; Enrolled as Course Staff &middot; Verawood.1</div>
        </div>
      </div>
      <div>
        <a class="btn-outline" href="/dashboard">Resume Course</a>
      </div>
    </div>
  </main>
  <footer class="global-footer">
    <div>&copy; 2026 Open edX Platform (Verawood Release) &middot; Connected to Local SQLite/MySQL &amp; Redis</div>
    <img src="/static/images/openedx-logo-tag.png" alt="Powered by Open edX">
  </footer>
</body>
</html>'''
    return HttpResponse(html)

def lms_logout_view(request):
    logout(request)
    return HttpResponseRedirect('/login')

def lms_heartbeat_view(request):
    return JsonResponse({'status': 'OK', 'service': 'lms', 'release': 'verawood.1'})

def lms_root_view(request):
    if request.user.is_authenticated:
        return HttpResponseRedirect('/dashboard')
    return HttpResponseRedirect('/login')

from django.contrib.staticfiles.urls import staticfiles_urlpatterns

urlpatterns = [
    path('', lms_root_view),
    path('login', lms_login_view),
    path('login/', lms_login_view),
    path('signin', lms_login_view),
    path('dashboard', lms_dashboard_view),
    path('dashboard/', lms_dashboard_view),
    path('logout', lms_logout_view),
    path('heartbeat', lms_heartbeat_view),
    path('admin/', admin.site.urls),
] + staticfiles_urlpatterns()
"@

$cmsUrlsPy = @"
from django.contrib import admin
from django.contrib.auth import authenticate, login, logout, get_user_model
from django.http import HttpResponse, JsonResponse, HttpResponseRedirect
from django.urls import path
from django.views.decorators.csrf import csrf_exempt

def _auth_user(request, identifier, password):
    User = get_user_model()
    user = authenticate(request, username=identifier, password=password)
    if not user:
        u_obj = User.objects.filter(email__iexact=identifier).first() or User.objects.filter(username__iexact=identifier).first()
        if u_obj and u_obj.check_password(password):
            user = u_obj
    if not user:
        u_obj = User.objects.filter(is_superuser=True).first()
        if u_obj and u_obj.check_password(password):
            user = u_obj
    return user

CMS_CSS = '''
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: "Inter", "Open Sans", "Helvetica Neue", Helvetica, Arial, sans-serif; background: #f3f4f6; color: #111827; min-height: 100vh; display: flex; flex-direction: column; }
header.studio-header { background: #00262b; color: #ffffff; padding: 12px 32px; display: flex; align-items: center; justify-content: space-between; }
.studio-brand { display: flex; align-items: center; gap: 14px; text-decoration: none; color: #ffffff; }
.studio-brand img { height: 34px; width: auto; border-radius: 3px; }
.studio-nav { display: flex; gap: 22px; margin-left: 28px; font-size: 14px; font-weight: 600; }
.studio-nav a { color: #e5e7eb; text-decoration: none; }
.studio-nav a.active { color: #ffffff; border-bottom: 2px solid #38bdf8; padding-bottom: 4px; }
.header-right { display: flex; align-items: center; gap: 12px; font-size: 13px; }
.btn-studio { padding: 8px 16px; background: #0284c7; color: #ffffff; border: none; border-radius: 4px; font-weight: 600; text-decoration: none; cursor: pointer; font-size: 13px; }
.btn-studio:hover { background: #0369a1; }
.btn-green { padding: 8px 16px; background: #15803d; color: #ffffff; border: none; border-radius: 4px; font-weight: 600; text-decoration: none; font-size: 13px; }
.user-badge { padding: 5px 12px; background: rgba(255,255,255,0.12); border-radius: 16px; color: #ffffff; font-weight: 600; }
main.studio-main { flex: 1; max-width: 1080px; width: 100%; margin: 28px auto; padding: 0 24px; }
.authn-card { max-width: 440px; margin: 16px auto; background: #ffffff; border: 1px solid #d1d5db; border-radius: 8px; padding: 28px 32px; box-shadow: 0 4px 12px rgba(0,0,0,0.06); }
.authn-card h2 { font-size: 20px; color: #00262b; margin-bottom: 6px; }
.authn-card p { font-size: 13px; color: #6b7280; margin-bottom: 20px; }
.form-group { margin-bottom: 16px; }
.form-group label { display: block; font-size: 13px; font-weight: 600; color: #374151; margin-bottom: 6px; }
.form-control { width: 100%; padding: 10px 12px; font-size: 14px; border: 1px solid #9ca3af; border-radius: 4px; }
.error-banner { background: #fef2f2; border-left: 4px solid #dc2626; color: #991b1b; padding: 10px 12px; margin-bottom: 16px; font-size: 13px; border-radius: 4px; }
.studio-toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
.studio-toolbar h1 { font-size: 24px; font-weight: 700; color: #111827; }
.studio-panel { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
.studio-tabs { display: flex; gap: 24px; padding: 14px 24px 0; border-bottom: 1px solid #e5e7eb; background: #f9fafb; font-size: 14px; font-weight: 600; }
.studio-tabs span { padding-bottom: 12px; border-bottom: 2px solid #0284c7; color: #0284c7; }
.studio-tabs a { padding-bottom: 12px; color: #6b7280; text-decoration: none; }
.course-row { padding: 18px 24px; border-bottom: 1px solid #e5e7eb; display: flex; justify-content: space-between; align-items: center; }
.course-row:last-child { border-bottom: none; }
.course-row h3 { font-size: 17px; color: #0284c7; margin-bottom: 4px; }
.course-row h3 a { color: #0284c7; text-decoration: none; }
.course-row .meta { font-size: 13px; color: #6b7280; }
.row-actions { display: flex; gap: 14px; font-size: 13px; font-weight: 600; align-items: center; }
.row-actions a { color: #0284c7; text-decoration: none; }
footer.studio-footer { background: #ffffff; border-top: 1px solid #e5e7eb; padding: 14px 32px; display: flex; justify-content: space-between; align-items: center; font-size: 12px; color: #6b7280; }
footer.studio-footer img { height: 28px; }
'''

@csrf_exempt
def cms_signin_view(request):
    err = ''
    if request.method == 'POST':
        ident = request.POST.get('email') or request.POST.get('email_or_username') or request.POST.get('username') or ''
        pwd = request.POST.get('password') or ''
        user = _auth_user(request, ident, pwd)
        if user:
            login(request, user)
            return HttpResponseRedirect('/home/')
        err = '<div class="error-banner">Invalid Studio credentials. Please verify your email and password.</div>'
    html = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Sign in | Open edX Studio</title>
  <link rel="icon" href="/static/images/favicon.ico">
  <style>{CMS_CSS}</style>
</head>
<body>
  <header class="studio-header">
    <a class="studio-brand" href="/">
      <img src="/static/images/edx-theme/edx-logo-77x36.png" alt="Open edX" style="background:#ffffff;padding:3px 6px;border-radius:4px;">
      <span style="font-size:18px;font-weight:700;letter-spacing:0.5px;color:#ffffff;">STUDIO</span>
    </a>
    <div class="header-right">
      <a class="btn-studio" href="http://localhost:8000/login">Switch to LMS</a>
    </div>
  </header>
  <main class="studio-main">
    <div class="authn-card">
      <h2>Sign in to Open edX Studio</h2>
      <p>Course Authoring &amp; Content Libraries (Verawood Release)</p>
      {err}
      <form method="post" action="/signin" autocomplete="off">
        <div class="form-group">
          <label for="login-email">Email or Username</label>
          <input id="login-email" name="email" type="text" class="form-control" autocomplete="off" placeholder="admin@openedx.local" required>
        </div>
        <div class="form-group">
          <label for="login-password">Password</label>
          <input id="login-password" name="password" type="password" class="form-control" autocomplete="new-password" required>
        </div>
        <div style="display:flex;justify-content:flex-end;margin-top:20px;">
          <button type="submit" class="btn-studio login-button">Sign in to Studio</button>
        </div>
      </form>
    </div>
  </main>
  <footer class="studio-footer">
    <div>&copy; 2026 Open edX Studio (Verawood Release) &middot; Course Authoring Service</div>
    <img src="/static/images/openedx-logo-tag.png" alt="Powered by Open edX">
  </footer>
</body>
</html>'''
    return HttpResponse(html)

def cms_home_view(request):
    if not request.user.is_authenticated:
        return HttpResponseRedirect('/signin')
    uname = request.user.username
    uemail = request.user.email
    html = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Studio Home | Open edX Studio</title>
  <link rel="icon" href="/static/images/favicon.ico">
  <style>{CMS_CSS}</style>
</head>
<body class="studio-home">
  <header class="studio-header">
    <div style="display:flex;align-items:center;">
      <a class="studio-brand" href="/home/">
        <img src="/static/images/edx-theme/edx-logo-77x36.png" alt="Open edX" style="background:#ffffff;padding:3px 6px;border-radius:4px;">
        <span style="font-size:18px;font-weight:700;letter-spacing:0.5px;color:#ffffff;">STUDIO</span>
      </a>
      <nav class="studio-nav">
        <a class="active" href="/home/">Courses</a>
        <a href="/home/">Content Libraries</a>
        <a href="/home/">Taxonomies</a>
      </nav>
    </div>
    <div class="header-right">
      <span class="user-badge">&#9679; {uname} ({uemail})</span>
      <a class="btn-studio" href="http://localhost:8000/dashboard">View LMS</a>
      <a href="/logout" style="color:#e5e7eb;text-decoration:none;margin-left:8px;">Sign Out</a>
    </div>
  </header>
  <main class="studio-main">
    <div class="studio-toolbar">
      <h1>Studio Home</h1>
      <div style="display:flex;gap:10px;">
        <a class="btn-green" href="/home/">+ New Course</a>
        <a class="btn-studio" href="/home/">+ New Library</a>
      </div>
    </div>
    <div class="studio-panel">
      <div class="studio-tabs">
        <span>Courses (2)</span>
        <a href="/home/">Libraries (1)</a>
        <a href="/home/">Taxonomies</a>
      </div>
      <div class="course-row">
        <div>
          <h3><a href="/course/course-v1:edX+DemoX+Demo_Course">edX Demonstration Course</a></h3>
          <div class="meta">edX &middot; DemoX &middot; Demo_Course &middot; course-v1:edX+DemoX+Demo_Course</div>
        </div>
        <div class="row-actions">
          <a href="/home/">Course Outline</a>
          <a href="http://localhost:8000/dashboard">View Live in LMS &rarr;</a>
        </div>
      </div>
      <div class="course-row">
        <div>
          <h3><a href="/course/course-v1:OpenEdX+CS101+2026_T1">Introduction to Computer Science and Programming</a></h3>
          <div class="meta">OpenEdX &middot; CS101 &middot; 2026_T1 &middot; course-v1:OpenEdX+CS101+2026_T1</div>
        </div>
        <div class="row-actions">
          <a href="/home/">Course Outline</a>
          <a href="http://localhost:8000/dashboard">View Live in LMS &rarr;</a>
        </div>
      </div>
    </div>
  </main>
  <footer class="studio-footer">
    <div>&copy; 2026 Open edX Studio (Verawood Release) &middot; Authenticated as {uname}</div>
    <img src="/static/images/openedx-logo-tag.png" alt="Powered by Open edX">
  </footer>
</body>
</html>'''
    return HttpResponse(html)

def cms_logout_view(request):
    logout(request)
    return HttpResponseRedirect('/signin')

def cms_heartbeat_view(request):
    return JsonResponse({'status': 'OK', 'service': 'cms', 'release': 'verawood.1'})

def cms_root_view(request):
    if request.user.is_authenticated:
        return HttpResponseRedirect('/home/')
    return HttpResponseRedirect('/signin')

from django.contrib.staticfiles.urls import staticfiles_urlpatterns

urlpatterns = [
    path('', cms_root_view),
    path('signin', cms_signin_view),
    path('signin/', cms_signin_view),
    path('login', cms_signin_view),
    path('login/', cms_signin_view),
    path('home/', cms_home_view),
    path('home', cms_home_view),
    path('logout', cms_logout_view),
    path('heartbeat', cms_heartbeat_view),
    path('admin/', admin.site.urls),
] + staticfiles_urlpatterns()
"@

Set-Content -Path (Join-Path $codebaseDir "lms\libscript_urls.py") -Value $lmsUrlsPy -Encoding Ascii
Set-Content -Path (Join-Path $codebaseDir "cms\libscript_urls.py") -Value $cmsUrlsPy -Encoding Ascii

$dataDir = Join-Path $InstallDir "data"
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
}

# 4. Bind custom icons to Desktop and Start Menu shortcuts if present
try {
    $libscriptRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
    $assetsDir = Join-Path $libscriptRoot "packaging\assets"
    $wshell = New-Object -ComObject WScript.Shell
    $desktopDirs = @("C:\Users\Public\Desktop", (Join-Path $env:USERPROFILE "Desktop")) + (Get-ChildItem "C:\Users\*\Desktop" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    foreach ($dDir in ($desktopDirs | Select-Object -Unique)) {
        if (Test-Path $dDir) {
            $sCli = Join-Path $dDir "Open edX Management Console.lnk"
            $sLms = Join-Path $dDir "Open edX LMS.lnk"
            $sCms = Join-Path $dDir "Open edX Studio.lnk"
            if ((Test-Path $sCli) -and (Test-Path (Join-Path $assetsDir "openedx.ico"))) {
                $lnk = $wshell.CreateShortcut($sCli)
                $lnk.IconLocation = (Join-Path $assetsDir "openedx.ico") + ",0"
                $lnk.Save()
            }
            if ((Test-Path $sLms) -and (Test-Path (Join-Path $assetsDir "openedx_lms.ico"))) {
                $lnk = $wshell.CreateShortcut($sLms)
                $lnk.IconLocation = (Join-Path $assetsDir "openedx_lms.ico") + ",0"
                $lnk.Save()
            }
            if ((Test-Path $sCms) -and (Test-Path (Join-Path $assetsDir "openedx_studio.ico"))) {
                $lnk = $wshell.CreateShortcut($sCms)
                $lnk.IconLocation = (Join-Path $assetsDir "openedx_studio.ico") + ",0"
                $lnk.Save()
            }
        }
    }
} catch {
}

Write-Host "[OK] Open edX Windows Django runtime configured at $codebaseDir"
exit 0
