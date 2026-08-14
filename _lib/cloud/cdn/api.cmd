@echo off
:: # api.cmd
::
:: ## Overview
:: API implementation for CDN operations on Windows. Wraps native cloud CLIs.
::
:: ## Usage
:: call "%~dp0api.cmd" :libscript_cdn_create aws my-bucket

goto :%1

:: ## libscript_cdn_create
:: Executes libscript_cdn_create functionality.
:libscript_cdn_create
set "provider=%~2"
set "bucket=%~3"
set "domain=%~4"
set "cert_id=%~5"

call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init

if "%provider%"=="aws" (
    for /f "tokens=*" %%i in ('aws cloudfront list-distributions --query "DistributionList.Items[?Origins.Items[?Id=='S3-%bucket%']].DomainName | [0]" --output text 2^>nul') do set "existing_dist=%%i"
    if not "!existing_dist!"=="" if not "!existing_dist!"=="None" (
        echo CDN Distribution already exists for '%bucket%': !existing_dist!
        set "dist_domain=!existing_dist!"
    ) else (
        :: Basic OAC creation wrapper
        for /f "tokens=*" %%i in ('aws cloudfront create-origin-access-control --origin-access-control-config "Name=%bucket%-oac,Description=libscript OAC,OriginAccessControlOriginType=s3,SigningBehavior=always,SigningProtocol=sigv4" --query "OriginAccessControl.Id" --output text 2^>nul') do set "oac_id=%%i"
        if "!oac_id!"=="" (
            for /f "tokens=*" %%i in ('aws cloudfront list-origin-access-controls --query "OriginAccessControlList.Items[?Name=='%bucket%-oac'].Id" --output text') do set "oac_id=%%i"
        )
    
        echo { > "%TEMP%\dist.json"
        echo   "CallerReference": "libscript-!RANDOM!", >> "%TEMP%\dist.json"
        echo   "Comment": "libscript managed CDN for %bucket%", >> "%TEMP%\dist.json"
        echo   "Enabled": true, >> "%TEMP%\dist.json"
        echo   "DefaultRootObject": "index.html", >> "%TEMP%\dist.json"
        echo   "Origins": { >> "%TEMP%\dist.json"
        echo     "Quantity": 1, >> "%TEMP%\dist.json"
        echo     "Items": [ >> "%TEMP%\dist.json"
        echo       { >> "%TEMP%\dist.json"
        echo         "Id": "S3-%bucket%", >> "%TEMP%\dist.json"
        echo         "DomainName": "%bucket%.s3.amazonaws.com", >> "%TEMP%\dist.json"
        echo         "OriginAccessControlId": "!oac_id!", >> "%TEMP%\dist.json"
        echo         "S3OriginConfig": { "OriginAccessIdentity": "" } >> "%TEMP%\dist.json"
        echo       } >> "%TEMP%\dist.json"
        echo     ] >> "%TEMP%\dist.json"
        echo   }, >> "%TEMP%\dist.json"
        echo   "DefaultCacheBehavior": { >> "%TEMP%\dist.json"
        echo     "TargetOriginId": "S3-%bucket%", >> "%TEMP%\dist.json"
        echo     "ViewerProtocolPolicy": "redirect-to-https", >> "%TEMP%\dist.json"
        echo     "MinTTL": 0, >> "%TEMP%\dist.json"
        echo     "ForwardedValues": { "QueryString": false, "Cookies": { "Forward": "none" } } >> "%TEMP%\dist.json"
        echo   } >> "%TEMP%\dist.json"
    
        if not "%domain%"=="" (
            if not "%cert_id%"=="" (
                echo   , >> "%TEMP%\dist.json"
                echo   "Aliases": { "Quantity": 1, "Items": [ "%domain%" ] }, >> "%TEMP%\dist.json"
                echo   "ViewerCertificate": { "ACMCertificateArn": "%cert_id%", "SSLSupportMethod": "sni-only", "MinimumProtocolVersion": "TLSv1.2_2021" } >> "%TEMP%\dist.json"
            ) else (
                echo   , >> "%TEMP%\dist.json"
                echo   "ViewerCertificate": { "CloudFrontDefaultCertificate": true } >> "%TEMP%\dist.json"
            )
        ) else (
            echo   , >> "%TEMP%\dist.json"
            echo   "ViewerCertificate": { "CloudFrontDefaultCertificate": true } >> "%TEMP%\dist.json"
        )
        echo } >> "%TEMP%\dist.json"
    
        for /f "tokens=*" %%i in ('aws cloudfront create-distribution --distribution-config "file://%TEMP%\dist.json" --query "Distribution.DomainName" --output text') do set "dist_domain=%%i"
        del "%TEMP%\dist.json"
    
        if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
            for /f "tokens=*" %%i in ('aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='!dist_domain!'].ARN" --output text') do set "dist_arn=%%i"
            if not "!dist_arn!"=="" (
                aws cloudfront tag-resource --resource "!dist_arn!" --tags "Items=[{Key=%LIBSCRIPT_TAG_KEY%,Value=%LIBSCRIPT_TAG_VALUE%}]"
            )
        )
        echo CDN Distribution created: !dist_domain!
    )

    echo IMPORTANT: You must apply the following bucket policy to '%bucket%' to allow OAC access:
    echo { "Version": "2012-10-17", "Statement": { "Effect": "Allow", "Principal": { "Service": "cloudfront.amazonaws.com" }, "Action": "s3:GetObject", "Resource": "arn:aws:s3:::%bucket%/*", "Condition": { "StringEquals": { "AWS:SourceArn": "arn:aws:cloudfront::YOUR_ACCOUNT_ID:distribution/YOUR_DIST_ID" } } } }

) else if "%provider%"=="gcp" (
    gcloud compute backend-buckets describe "%bucket%-backend" >nul 2>&1
    if not errorlevel 1 (
        echo CDN backend-bucket already exists for %bucket%
    ) else (
        gcloud compute backend-buckets create "%bucket%-backend" --gcs-bucket-name="%bucket%" --enable-cdn
        gcloud compute url-maps create "%bucket%-urlmap" --default-backend-bucket="%bucket%-backend"
        
        if not "%domain%"=="" (
            if not "%cert_id%"=="" (
                gcloud compute target-https-proxies create "%bucket%-https-proxy" --url-map="%bucket%-urlmap" --ssl-certificates="%cert_id%"
                gcloud compute forwarding-rules create "%bucket%-https-rule" --target-https-proxy="%bucket%-https-proxy%" --ports=443 --global
                echo HTTPS CDN created.
                exit /b 0
            )
        )
        gcloud compute target-http-proxies create "%bucket%-http-proxy" --url-map="%bucket%-urlmap"
        gcloud compute forwarding-rules create "%bucket%-http-rule" --target-http-proxy="%bucket%-http-proxy%" --ports=80 --global
        echo HTTP CDN created.
    )
) else if "%provider%"=="azure" (
    echo Azure CDN creation requires an existing CDN Profile. Skipping complex scaffolding for now.
)
exit /b 0

:: ## libscript_cdn_delete
:: Executes libscript_cdn_delete functionality.
:libscript_cdn_delete
set "provider=%~2"
set "dist_id=%~3"

if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed "%provider%" cdn "%dist_id%"
    if errorlevel 1 exit /b 1
)

if "%provider%"=="aws" (
    for /f "tokens=*" %%i in ('aws cloudfront get-distribution --id "%dist_id%" --query "ETag" --output text') do set "etag=%%i"
    aws cloudfront delete-distribution --id "%dist_id%" --if-match "!etag!"
) else if "%provider%"=="gcp" (
    gcloud compute forwarding-rules delete "%dist_id%-https-rule" "%dist_id%-http-rule" --global --quiet 2>nul
    gcloud compute target-https-proxies delete "%dist_id%-https-proxy" --quiet 2>nul
    gcloud compute target-http-proxies delete "%dist_id%-http-proxy" --quiet 2>nul
    gcloud compute url-maps delete "%dist_id%-urlmap" --quiet 2>nul
    gcloud compute backend-buckets delete "%dist_id%-backend" --quiet 2>nul
) else if "%provider%"=="azure" (
    echo Azure CDN delete not implemented in stub.
)
exit /b 0

:: ## libscript_cdn_list
:: Executes libscript_cdn_list functionality.
:libscript_cdn_list
set "provider=%~2"

if "%provider%"=="aws" (
    aws cloudfront list-distributions --query "DistributionList.Items[*].[Id,DomainName,Status]" --output table
) else if "%provider%"=="gcp" (
    gcloud compute backend-buckets list
    gcloud compute url-maps list
) else if "%provider%"=="azure" (
    echo Azure CDN list not implemented in stub.
)
exit /b 0

:: ## libscript_cdn_invalidate
:: Executes libscript_cdn_invalidate functionality.
:libscript_cdn_invalidate
set "provider=%~2"
set "dist_id=%~3"
set "paths=%~4"
if "%paths%"=="" set "paths=/*"

if "%provider%"=="aws" (
    aws cloudfront create-invalidation --distribution-id "%dist_id%" --paths "%paths%"
) else if "%provider%"=="gcp" (
    gcloud compute url-maps invalidate-cdn-cache "%dist_id%-urlmap" --path "%paths%"
) else if "%provider%"=="azure" (
    echo Azure CDN invalidate not implemented in stub.
)
exit /b 0
