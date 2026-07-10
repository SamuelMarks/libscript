@echo off
:: # api.cmd
::
:: ## Overview
:: API implementation for SSL Certificate operations on Windows. Wraps native cloud CLIs.
::
:: ## Usage
:: call "%~dp0api.cmd" :libscript_cert_create aws example.com

goto :%1

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

:libscript_cert_delete
set "provider=%~2"
set "domain=%~3"

if "%provider%"=="aws" (
    echo %domain% | findstr /b /c:"arn:aws:acm" >nul
    if not errorlevel 1 (
        aws acm delete-certificate --certificate-arn "%domain%"
    ) else (
        for /f "tokens=*" %%i in ('aws acm list-certificates --query "CertificateSummaryList[?DomainName=='%domain%'].CertificateArn" --output text') do set "arn=%%i"
        if not "!arn!"=="" (
            aws acm delete-certificate --certificate-arn "!arn!"
        ) else (
            echo Error: Certificate for domain %domain% not found. >&2
            exit /b 1
        )
    )
) else if "%provider%"=="gcp" (
    set "cert_name=%domain:.=-%"
    gcloud compute ssl-certificates delete "!cert_name!" --global --quiet
) else if "%provider%"=="azure" (
    echo Azure managed CDN certificates are deleted when the custom domain mapping is removed.
)
exit /b 0

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
