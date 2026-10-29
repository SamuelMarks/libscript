# ## Overview
# User management helper utility for Open edX on Windows.
# Manages user account creation, credentials, staff roles, and catalog enumeration.
#
# ## Usage
# powershell _lib/web-apps/openedx/user_helper.ps1 create <install_dir> <username> <email> <password> <is_staff> <is_superuser>
# powershell _lib/web-apps/openedx/user_helper.ps1 set_password <install_dir> <username> <password>
# powershell _lib/web-apps/openedx/user_helper.ps1 list <install_dir>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Action,
    [Parameter(Position = 1)]
    [string]$Arg1,
    [Parameter(Position = 2)]
    [string]$Arg2,
    [Parameter(Position = 3)]
    [string]$Arg3,
    [Parameter(Position = 4)]
    [string]$Arg4,
    [Parameter(Position = 5)]
    [string]$Arg5,
    [Parameter(Position = 6)]
    [string]$Arg6
)

# ## Show-Help
# Displays command usage documentation.
function Show-Help {
    Write-Host "Usage: user_helper.ps1 create <install_dir> <username> <email> <password> <is_staff> <is_superuser>"
    Write-Host "       user_helper.ps1 set_password <install_dir> <username> <password>"
    Write-Host "       user_helper.ps1 list <install_dir>"
    exit 0
}

# ## Do-Create
# Creates or updates a user account.
function Do-Create {
    param(
        [string]$InstallDir,
        [string]$Username,
        [string]$Email,
        [string]$Password,
        [string]$IsStaff,
        [string]$IsSuperuser
    )

    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    $pyExe = Join-Path $InstallDir ".venv\Scripts\python.exe"
    $codebaseDir = if (Test-Path (Join-Path $InstallDir "codebase\manage.py")) { Join-Path $InstallDir "codebase" } else { $InstallDir }
    $hasFullEdxDeps = Test-Path (Join-Path $InstallDir ".venv\Lib\site-packages\edx_django_utils")
    $settingsMod = if ($hasFullEdxDeps) { "lms.envs.production" } else { "lms.envs.libscript_win" }
    if (Test-Path $pyExe) {
        Push-Location $codebaseDir
        try {
            $env:PYTHONPATH = $codebaseDir
            $env:OPENEDX_INSTALL_DIR = $InstallDir
            $env:LMS_CFG = Join-Path $InstallDir "config\lms.yml"
            $env:CMS_CFG = Join-Path $InstallDir "config\cms.yml"
            $env:REVISION_CFG = Join-Path $InstallDir "config\revisions.yml"
            $env:DJANGO_SETTINGS_MODULE = $settingsMod
            $env:OPENEDX_ADMIN_USERNAME = $Username
            $env:OPENEDX_ADMIN_EMAIL = $Email
            $env:OPENEDX_ADMIN_PASSWORD = $Password
            $staffArgs = @()
            if ($IsStaff.ToLower() -eq "true") { $staffArgs += "--staff" }
            if ($IsSuperuser.ToLower() -eq "true") { $staffArgs += "--superuser" }
            if ($hasFullEdxDeps -and (Test-Path (Join-Path $codebaseDir "manage.py"))) {
                & $pyExe (Join-Path $codebaseDir "manage.py") lms --settings=production manage_user $Username $Email @staffArgs 2>$null | Out-Null
            }
            $setupUserPy = @"
import os, django
django.setup()
from django.contrib.auth import get_user_model
User = get_user_model()
un = os.environ['OPENEDX_ADMIN_USERNAME']
em = os.environ['OPENEDX_ADMIN_EMAIL']
pw = os.environ['OPENEDX_ADMIN_PASSWORD']
u = User.objects.filter(username=un).first() or User.objects.filter(email=em).first()
if not u:
    u = User.objects.create_user(username=un, email=em, password=pw)
u.username = un
u.email = em
u.is_staff = ('$IsStaff'.lower() == 'true' or '$IsSuperuser'.lower() == 'true')
u.is_superuser = ('$IsSuperuser'.lower() == 'true')
u.is_active = True
u.set_password(pw)
u.save()
try:
    from common.djangoapps.student.models import UserProfile, CourseEnrollment
    from opaque_keys.edx.keys import CourseKey
    UserProfile.objects.get_or_create(user=u, defaults={'name': un})
    ck = CourseKey.from_string('course-v1:edX+DemoX+Demo_Course')
    CourseEnrollment.enroll(u, ck, check_access=False)
except Exception:
    pass
try:
    from cms.djangoapps.course_creators.models import CourseCreator
    cc, _ = CourseCreator.objects.get_or_create(user=u)
    cc.state = CourseCreator.GRANTED
    cc.save()
except Exception:
    pass
"@
            & $pyExe -c $setupUserPy 2>$null | Out-Null
        } finally {
            Pop-Location
        }
    }

    $p = Join-Path $InstallDir "users.json"
    $dict = @{}
    if (Test-Path $p) {
        try {
            $raw = Get-Content -Path $p -Raw
            $json = ConvertFrom-Json $raw
            foreach ($prop in $json.PSObject.Properties) {
                $dict[$prop.Name] = @{
                    "username" = $prop.Value.username
                    "email" = $prop.Value.email
                    "is_staff" = $prop.Value.is_staff
                    "is_superuser" = $prop.Value.is_superuser
                }
            }
        } catch {
            $dict = @{}
        }
    }

    $dict[$Username] = @{
        "username" = $Username
        "email" = $Email
        "is_staff" = ($IsStaff.ToLower() -eq "true")
        "is_superuser" = ($IsSuperuser.ToLower() -eq "true")
    }

    Set-Content -Path $p -Value (ConvertTo-Json $dict -Depth 5) -Encoding Ascii
    Write-Host "User processed successfully."
}

# ## Do-SetPassword
# Modifies user password state.
function Do-SetPassword {
    param(
        [string]$InstallDir,
        [string]$Username,
        [string]$Password
    )

    $pyExe = Join-Path $InstallDir ".venv\Scripts\python.exe"
    $codebaseDir = if (Test-Path (Join-Path $InstallDir "codebase\manage.py")) { Join-Path $InstallDir "codebase" } else { $InstallDir }
    $hasFullEdxDeps = Test-Path (Join-Path $InstallDir ".venv\Lib\site-packages\edx_django_utils")
    $settingsMod = if ($hasFullEdxDeps) { "lms.envs.production" } else { "lms.envs.libscript_win" }
    if (Test-Path $pyExe) {
        Push-Location $codebaseDir
        try {
            $env:PYTHONPATH = $codebaseDir
            $env:OPENEDX_INSTALL_DIR = $InstallDir
            $env:LMS_CFG = Join-Path $InstallDir "config\lms.yml"
            $env:CMS_CFG = Join-Path $InstallDir "config\cms.yml"
            $env:REVISION_CFG = Join-Path $InstallDir "config\revisions.yml"
            $env:DJANGO_SETTINGS_MODULE = $settingsMod
            & $pyExe -c "import os, django; django.setup(); from django.contrib.auth import get_user_model; User = get_user_model(); u = User.objects.filter(username='$Username').first() or User.objects.filter(email='$Username').first(); (u.set_password('$Password'), u.save()) if u else None" 2>$null | Out-Null
        } finally {
            Pop-Location
        }
    }

    $p = Join-Path $InstallDir "users.json"
    if (-not (Test-Path $p)) {
        Write-Error "Error: User $Username does not exist."
        exit 1
    }

    $dict = @{}
    try {
        $raw = Get-Content -Path $p -Raw
        $json = ConvertFrom-Json $raw
        foreach ($prop in $json.PSObject.Properties) {
            $dict[$prop.Name] = @{
                "username" = $prop.Value.username
                "email" = $prop.Value.email
                "is_staff" = $prop.Value.is_staff
                "is_superuser" = $prop.Value.is_superuser
            }
        }
    } catch {
        Write-Error "Error: User $Username does not exist."
        exit 1
    }

    if (-not $dict.ContainsKey($Username)) {
        Write-Error "Error: User $Username does not exist."
        exit 1
    }

    $dict[$Username]["password_updated"] = $true
    Set-Content -Path $p -Value (ConvertTo-Json $dict -Depth 5) -Encoding Ascii
    Write-Host "Password updated."
}

# ## Do-List
# Lists users and roles from users.json.
function Do-List {
    param([string]$InstallDir)

    $p = Join-Path $InstallDir "users.json"
    Write-Host ("{0,-20} {1,-30} {2,-8} {3,-10}" -f "USERNAME", "EMAIL", "STAFF", "SUPERUSER")
    Write-Host ("-" * 72)

    if (Test-Path $p) {
        try {
            $raw = Get-Content -Path $p -Raw
            $json = ConvertFrom-Json $raw
            foreach ($prop in $json.PSObject.Properties) {
                $email = if ($prop.Value.email) { $prop.Value.email } else { "" }
                $staff = if ($prop.Value.is_staff) { "True" } else { "False" }
                $super = if ($prop.Value.is_superuser) { "True" } else { "False" }
                Write-Host ("{0,-20} {1,-30} {2,-8} {3,-10}" -f $prop.Name, $email, $staff, $super)
            }
        } catch {}
    }
}

if ([string]::IsNullOrEmpty($Action) -or $Action -in @("help", "--help", "-h")) {
    Show-Help
}

switch ($Action.ToLower()) {
    "create" {
        Do-Create -InstallDir $Arg1 -Username $Arg2 -Email $Arg3 -Password $Arg4 -IsStaff $Arg5 -IsSuperuser $Arg6
    }
    "set_password" {
        Do-SetPassword -InstallDir $Arg1 -Username $Arg2 -Password $Arg3
    }
    "list" {
        Do-List -InstallDir $Arg1
    }
    Default {
        Write-Error "Error: Unknown action $Action"
        exit 1
    }
}
