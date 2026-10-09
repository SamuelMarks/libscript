@echo off
:: # api.cmd
::
:: ## Overview
:: API implementation for SSL Certificate operations on Windows. Wraps native cloud CLIs.
::
:: ## Usage
:: call "%~dp0api.cmd" :libscript_cert_create aws example.com
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

goto :%1

:: ## libscript_cert_create
:: Executes libscript_cert_create functionality.
:libscript_cert_create
set "provider=%~2"
set "domain=%~3"

call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init

if "%provider%"=="aws" (
    for /f "tokens=*" %%i in ('aws acm request-certificate --domain-name "%domain%" --validation-method DNS --query "CertificateArn" --output text') do set "arn=%%i"
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        aws acm add-tags-to-certificate --certificate-arn "!arn!" --tags "Key=%LIBSCRIPT_TAG_KEY%,Value=%LIBSCRIPT_TAG_VALUE%"
    )
    echo Requested certificate: !arn!
    echo Use 'aws acm describe-certificate --certificate-arn !arn!' to get DNS validation records.
) else if "%provider%"=="gcp" (
    set "cert_name=%domain:.=-%"
    gcloud compute ssl-certificates create "!cert_name!" --domains="%domain%" --global
    echo Requested certificate: !cert_name!
) else if "%provider%"=="azure" (
    echo Azure Front Door managed certificates are typically provisioned automatically when adding a custom domain to a CDN endpoint.
)
exit /b 0

:: ## libscript_cert_delete
:: Executes libscript_cert_delete functionality.
:libscript_cert_delete
set "provider=%~2"
set "domain=%~3"

if "%provider%"=="aws" (
    echo %domain% | findstr /b /c:"arn:aws:acm" >nul
    if not errorlevel 1 (
        if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
            call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed aws cert "%domain%"
            if errorlevel 1 exit /b 1
        )
        aws acm delete-certificate --certificate-arn "%domain%"
    ) else (
        for /f "tokens=*" %%i in ('aws acm list-certificates --query "CertificateSummaryList[?DomainName=='%domain%'].CertificateArn" --output text') do set "arn=%%i"
        if not "!arn!"=="" (
            if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
                call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed aws cert "!arn!"
                if errorlevel 1 exit /b 1
            )
            aws acm delete-certificate --certificate-arn "!arn!"
        ) else (
            echo Error: Certificate for domain %domain% not found. >&2
            exit /b 1
        )
    )
) else if "%provider%"=="gcp" (
    set "cert_name=%domain:.=-%"
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
        call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed gcp cert "!cert_name!"
        if errorlevel 1 exit /b 1
    )
    gcloud compute ssl-certificates delete "!cert_name!" --global --quiet
) else if "%provider%"=="azure" (
    echo Azure managed CDN certificates are deleted when the custom domain mapping is removed.
)
exit /b 0

:: ## libscript_cert_list
:: Executes libscript_cert_list functionality.
:libscript_cert_list
set "provider=%~2"

if "%provider%"=="aws" (
    aws acm list-certificates
) else if "%provider%"=="gcp" (
    gcloud compute ssl-certificates list --global
) else if "%provider%"=="azure" (
    echo Azure managed certificates are tied to CDN custom domains. Use CDN list commands.
)
exit /b 0
