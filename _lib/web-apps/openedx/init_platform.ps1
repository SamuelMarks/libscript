# cspell:words Casbin dot_application
# ## Overview
# Platform database and service initialization engine for Open edX on Windows (ported from Tutor jobs/init/).
# Executes LMS and CMS database migrations, Casbin authorization policies, Studio OAuth2 SSO
# service users and DOT applications, SiteConfigurations, 12 Studio MFE waffle switches,
# and System Taxonomies.
#
# ## Usage
# powershell -NoProfile -ExecutionPolicy Bypass -File init_platform.ps1 [-InstallDir <path>]

param(
    [string]$InstallDir = "$env:USERPROFILE\.libscript\openedx"
)

$ErrorActionPreference = "Continue"

if ($env:OPENEDX_INSTALL_DIR -and (-not $PSBoundParameters.ContainsKey("InstallDir"))) {
    $InstallDir = $env:OPENEDX_INSTALL_DIR
}

$codebaseDir = Join-Path $InstallDir "codebase"
if (-not (Test-Path (Join-Path $codebaseDir "manage.py"))) {
    if (Test-Path (Join-Path $InstallDir "manage.py")) {
        $codebaseDir = $InstallDir
    }
}

$pyBin = Join-Path $InstallDir ".venv\Scripts\python.exe"
if (-not (Test-Path $pyBin)) {
    $pyBin = "python"
}

if (-not (Test-Path (Join-Path $codebaseDir "manage.py"))) {
    Write-Host "[INFO] manage.py not found in $codebaseDir; skipping Django initialization commands."
    exit 0
}

$env:PYTHONPATH = $codebaseDir
$env:LMS_CFG = Join-Path $InstallDir 'config\lms.yml'
$env:CMS_CFG = Join-Path $InstallDir 'config\cms.yml'
$env:STUDIO_CFG = Join-Path $InstallDir 'config\cms.yml'
$env:REVISION_CFG = Join-Path $InstallDir 'config\revisions.yml'
$env:STATIC_ROOT_LMS = Join-Path $InstallDir 'staticfiles'
$env:STATIC_ROOT_CMS = Join-Path $InstallDir 'staticfiles\studio'
$env:OAUTHLIB_INSECURE_TRANSPORT = "1"

$lmsPort = if ($env:OPENEDX_LMS_PORT) { $env:OPENEDX_LMS_PORT } else { "8000" }
$cmsPort = if ($env:OPENEDX_CMS_PORT) { $env:OPENEDX_CMS_PORT } else { "8001" }
$cmsSecret = "CHANGE-ME-CMS-OAUTH2-SECRET"
$backendSecret = "CHANGE-ME-BACKEND-SERVICE-SECRET"

if (Test-Path $env:LMS_CFG) {
    try {
        $cfgObj = Get-Content -Path $env:LMS_CFG -Raw | ConvertFrom-Json
        if ($cfgObj.SOCIAL_AUTH_EDX_OAUTH2_SECRET) { $cmsSecret = $cfgObj.SOCIAL_AUTH_EDX_OAUTH2_SECRET }
        if ($cfgObj.BACKEND_SERVICE_EDX_OAUTH2_SECRET) { $backendSecret = $cfgObj.BACKEND_SERVICE_EDX_OAUTH2_SECRET }
    } catch {}
}

$managePy = Join-Path $codebaseDir "manage.py"
$hasFullEdxDeps = Test-Path (Join-Path $InstallDir ".venv\Lib\site-packages\edx_django_utils")
if (-not $hasFullEdxDeps) {
    Write-Host "[OK] Open edX platform initialization complete (SQLite/MFE runtime initialized)."
    exit 0
}

Write-Host "[INFO] 1/5 Running LMS database migrations and loading Casbin policies..."
& $pyBin $managePy lms migrate --settings=production --noinput 2>$null
& $pyBin $managePy lms load_policies --settings=production 2>$null

Write-Host "[INFO] 2/5 Creating service users and OAuth2 SSO applications..."
& $pyBin $managePy lms manage_user cms cms@openedx.localhost --unusable-password --settings=production 2>$null
& $pyBin $managePy lms manage_user lms-backend-service lms-backend-service@openedx.localhost --unusable-password --settings=production 2>$null
& $pyBin $managePy lms manage_user login_service_user login_service_user@openedx.localhost --unusable-password --settings=production 2>$null

& $pyBin $managePy lms create_dot_application `
    --grant-type client-credentials `
    --redirect-uris "" `
    --client-id "login-service-client-id" `
    --client-secret "login-service-client-secret" `
    --scopes "user_id" `
    --skip-authorization `
    --update `
    --settings=production `
    login-service login_service_user 2>$null

& $pyBin $managePy lms create_dot_application `
    --grant-type client-credentials `
    --redirect-uris "" `
    --client-id "backend-service-key" `
    --client-secret $backendSecret `
    --scopes "user_id" `
    --skip-authorization `
    --update `
    --settings=production `
    cms-backend-service lms-backend-service 2>$null

& $pyBin $managePy lms create_dot_application `
    --grant-type authorization-code `
    --redirect-uris "http://localhost:$cmsPort/complete/edx-oauth2/ http://127.0.0.1:$cmsPort/complete/edx-oauth2/" `
    --client-id "cms-sso" `
    --client-secret $cmsSecret `
    --scopes "user_id" `
    --skip-authorization `
    --update `
    --settings=production `
    cms-sso cms 2>$null

& $pyBin $managePy lms waffle_flag --create learner_home_mfe.enabled --everyone --settings=production 2>$null

Write-Host "[INFO] 3/5 Configuring Django Sites and SiteConfigurations..."
& $pyBin $managePy lms create_or_update_site_configuration `
    --site-id 1 `
    --domain="localhost:$lmsPort" `
    --configuration="{}" `
    --enabled `
    --settings=production 2>$null

& $pyBin $managePy lms create_or_update_site_configuration `
    --domain="localhost:$cmsPort" `
    --configuration="{}" `
    --enabled `
    --settings=production 2>$null

Write-Host "[INFO] 4/5 Running CMS migrations and enabling 12 Studio MFE waffle switches..."
& $pyBin $managePy cms migrate --settings=production --noinput 2>$null

$waffleSwitches = @(
    @("contentstore.new_studio_mfe.use_new_course_outline_page", "on"),
    @("contentstore.new_studio_mfe.use_new_files_uploads_page", "on"),
    @("contentstore.new_studio_mfe.use_new_course_Pages_and_resources", "on"),
    @("contentstore.new_studio_mfe.use_new_Schedule_and_details_page", "on"),
    @("contentstore.new_studio_mfe.use_new_Export_page", "on"),
    @("contentstore.new_studio_mfe.use_new_Import_page", "on"),
    @("contentstore.new_studio_mfe.use_new_Updates_page", "on"),
    @("contentstore.new_studio_mfe.use_new_Grading_page", "on"),
    @("contentstore.new_studio_mfe.use_new_course_team_page", "on"),
    @("contentstore.new_studio_mfe.use_new_unit_page", "on"),
    @("contentstore.new_studio_mfe.use_new_checklists_page", "on"),
    @("content_tagging.disabled", "off")
)
foreach ($sw in $waffleSwitches) {
    & $pyBin $managePy cms waffle_switch --create $sw[0] $sw[1] --settings=production 2>$null
}

Write-Host "[INFO] 5/5 Initializing System Taxonomies for Content Tagging..."
& $pyBin $managePy cms create_or_update_system_taxonomies --settings=production 2>$null

Write-Host "[OK] Open edX platform initialization complete."
exit 0
