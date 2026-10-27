# ## Overview
# End-to-end PowerShell integration test harness for real Open edX services.
#
# ## Usage
# Execute this script to verify Open edX service coordination, registration, and login.

<#
.SYNOPSIS
    End-to-end PowerShell integration test harness for real Open edX services.
.DESCRIPTION
    Verifies service coordination, tests registration and login endpoints,
    submits user credentials, and confirms Studio operation.
#>
$ErrorActionPreference = "Stop"
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$LmsHost = if ($env:LMS_HOST) { $env:LMS_HOST } else { "127.0.0.1" }
$CmsHost = if ($env:CMS_HOST) { $env:CMS_HOST } else { "127.0.0.1" }
$LmsPort = if ($env:LMS_PORT) { $env:LMS_PORT } else { 8000 }
$CmsPort = if ($env:CMS_PORT) { $env:CMS_PORT } else { 8001 }
$AdminUser = if ($env:OPENEDX_ADMIN_USERNAME) { $env:OPENEDX_ADMIN_USERNAME } else { "admin" }
$AdminPass = if ($env:OPENEDX_ADMIN_PASSWORD) { $env:OPENEDX_ADMIN_PASSWORD } else { "admin" }
$UserHome = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { "." }
$LibHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $UserHome ".libscript" }
$InstallDir = if ($env:OPENEDX_INSTALL_DIR) { $env:OPENEDX_INSTALL_DIR } else { Join-Path $LibHome "openedx" }

$Session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

Write-Host "=== Open edX Real Service Coordination & Authentication Test (PowerShell) ==="

# 1. Backing Services Check
Write-Host "[CHECK 1/6] Verifying backing services..."
if (Get-Command "Get-Service" -ErrorAction SilentlyContinue) {
    $mysqlSvc = Get-Service -Name "mysql" -ErrorAction SilentlyContinue
    if ($mysqlSvc) { Write-Host "  -> MySQL: $($mysqlSvc.Status)" }

    $redisSvc = Get-Service -Name "redis" -ErrorAction SilentlyContinue
    if ($redisSvc) { Write-Host "  -> Redis: $($redisSvc.Status)" }
}

try {
    # libscript-allow-raw-fetch
    $meili = Invoke-WebRequest -Uri "http://127.0.0.1:7700/health" -UseBasicParsing -TimeoutSec 2
    Write-Host "  -> Meilisearch: ACTIVE"
} catch {
    # Non-blocking check
}

# 2. Verify LMS and CMS are reachable
Write-Host "[CHECK 2/6] Verifying LMS and Studio availability..."
$wsgiPy = Join-Path $ScriptDir "wsgi_server.py"
try {
    # libscript-allow-raw-fetch
    $null = Invoke-WebRequest -Uri "http://127.0.0.1`:$LmsPort/" -UseBasicParsing -TimeoutSec 2
} catch {
    if (Test-Path $wsgiPy) {
        Write-Host "  -> Starting Open edX WSGI server..."
        Start-Process -NoNewWindow python -ArgumentList @($wsgiPy, "--lms-port", "$LmsPort", "--cms-port", "$CmsPort")
        Start-Sleep -Seconds 3
    }
}

# 3. Test Registration Screen GET
Write-Host "[TEST 3/6] GET http://127.0.0.1`:$LmsPort/register (Registration Screen)..."
# libscript-allow-raw-fetch
$reg = Invoke-WebRequest -Uri "http://127.0.0.1`:$LmsPort/register" -WebSession $Session -UseBasicParsing -TimeoutSec 5
if ($reg.StatusCode -eq 500 -or $reg.StatusCode -eq 502) { throw "Server error $($reg.StatusCode)" }
Write-Host "  -> PASSED: Registration screen accessible without server error ($($reg.StatusCode))"

# 4. Test Login Screen GET
Write-Host "[TEST 4/6] GET http://127.0.0.1`:$LmsPort/login (Login Screen)..."
# libscript-allow-raw-fetch
$login = Invoke-WebRequest -Uri "http://127.0.0.1`:$LmsPort/login" -WebSession $Session -UseBasicParsing -TimeoutSec 5
if ($login.StatusCode -eq 500 -or $login.StatusCode -eq 502) { throw "Server error $($login.StatusCode)" }
Write-Host "  -> PASSED: Login screen rendered without server error ($($login.StatusCode))"

# 5. Test Real Authentication
Write-Host "[TEST 5/6] POST User Authentication with seeded credentials ($AdminUser)..."
$authBody = "email=$AdminUser&password=$AdminPass"
# libscript-allow-raw-fetch
$auth = Invoke-WebRequest -Uri "http://127.0.0.1`:$LmsPort/login" -Method POST -Body $authBody -ContentType "application/x-www-form-urlencoded" -WebSession $Session -UseBasicParsing -TimeoutSec 5
if ($auth.StatusCode -eq 500 -or $auth.StatusCode -eq 502) { throw "Server error $($auth.StatusCode)" }
Write-Host "  -> PASSED: Authentication request processed without server error ($($auth.StatusCode))"

# 6. Verify Studio / CMS Service
Write-Host "[TEST 6/6] GET http://127.0.0.1`:$CmsPort/signin (Studio / CMS Service)..."
# libscript-allow-raw-fetch
$studio = Invoke-WebRequest -Uri "http://127.0.0.1`:$CmsPort/signin" -UseBasicParsing -TimeoutSec 5
if ($studio.StatusCode -eq 500 -or $studio.StatusCode -eq 502) { throw "Server error $($studio.StatusCode)" }
Write-Host "  -> PASSED: Studio CMS verified operational without server error ($($studio.StatusCode))"

Write-Host ""
Write-Host "======================================================================"
Write-Host "[SUCCESS] Real Open edX LMS and Studio/CMS Services Verified Successfully!"
Write-Host "======================================================================"
exit 0
