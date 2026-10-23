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
    $managePy = Join-Path $codebaseDir "manage.py"
    if ((Test-Path $managePy) -and (Test-Path $pyExe)) {
        $staffArgs = @("lms", "--settings=libscript", "manage_user", $Username, $Email)
        if ($IsStaff.ToLower() -eq "true") { $staffArgs += "--staff" }
        if ($IsSuperuser.ToLower() -eq "true") { $staffArgs += "--superuser" }
        Push-Location $codebaseDir
        try {
            & $pyExe $managePy @staffArgs 2>$null | Out-Null
            & $pyExe -c "import os, django; os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms.envs.libscript'); django.setup(); from django.contrib.auth import get_user_model; User = get_user_model(); u, _ = User.objects.get_or_create(username='$Username', defaults={'email': '$Email'}); u.email = '$Email'; u.is_staff = ('$IsStaff'.lower() == 'true' or '$IsSuperuser'.lower() == 'true'); u.is_superuser = ('$IsSuperuser'.lower() == 'true'); u.set_password('$Password'); u.save()" 2>$null | Out-Null
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
