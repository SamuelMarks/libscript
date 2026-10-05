@echo off
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

:: ## Overview
:: Declarative Reverse Proxy Synthesizer. Generates Nginx, Caddy, Httpd, or IIS configurations
:: to map multi-vHost architectures to underlying WSGI ports, static webroots, MFEs, and WebSockets.
::
:: ## Usage
::   call provision_proxy.cmd --proxy <nginx|caddy|httpd|iis> --app-dir <dir> --packaging <path>

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop
:found_root

set "PROXY_TYPE="
set "APP_DIR="
set "PACKAGING_PATH="

:parse_args
if "%~1"=="" goto run_provision
if "%~1"=="--proxy" ( set "PROXY_TYPE=%~2" & shift & shift & goto parse_args )
if "%~1"=="--app-dir" ( set "APP_DIR=%~2" & shift & shift & goto parse_args )
if "%~1"=="--packaging" ( set "PACKAGING_PATH=%~2" & shift & shift & goto parse_args )
shift
goto parse_args

:run_provision
if "%PROXY_TYPE%"=="" ( echo Error: Missing proxy >&2 & exit /b 1 )
if "%APP_DIR%"=="" ( echo Error: Missing app-dir >&2 & exit /b 1 )
if "%PACKAGING_PATH%"=="" ( echo Error: Missing packaging >&2 & exit /b 1 )

set "CONF_DIR=%APP_DIR%\proxy"
if not exist "%CONF_DIR%" mkdir "%CONF_DIR%"
set "WEBROOT_BASE=%APP_DIR%\webroot"
set "PS1_TMP=%CONF_DIR%\_proxy_gen.ps1"

echo $ErrorActionPreference = 'Stop' > "%PS1_TMP%"
echo $proxyType = '%PROXY_TYPE%' >> "%PS1_TMP%"
echo $confDir = '%CONF_DIR%' >> "%PS1_TMP%"
echo $webrootBase = '%WEBROOT_BASE%'.Replace('\', '/') >> "%PS1_TMP%"
echo $packagingPath = '%PACKAGING_PATH%' >> "%PS1_TMP%"
echo if (-not (Test-Path $packagingPath^)^) { exit 1 } >> "%PS1_TMP%"
echo $manifest = Get-Content -Raw $packagingPath ^| ConvertFrom-Json >> "%PS1_TMP%"
echo if ($null -eq $manifest.services) { exit 0 } >> "%PS1_TMP%"
echo. >> "%PS1_TMP%"

:: NGINX
echo if ($proxyType -eq 'nginx'^) { >> "%PS1_TMP%"
echo   $confFile = Join-Path $confDir 'nginx.conf' >> "%PS1_TMP%"
echo   Set-Content -Path $confFile -Value '# Auto-generated Nginx Config' >> "%PS1_TMP%"
echo   foreach ($svc in $manifest.services) { >> "%PS1_TMP%"
echo     $domain = if ($svc.domain) { $svc.domain } else { ^"$($svc.id).local^" } >> "%PS1_TMP%"
echo     if ($svc.type -eq 'wsgi' -or $svc.type -eq 'asgi'^) { >> "%PS1_TMP%"
echo       $port = $svc.port_binding >> "%PS1_TMP%"
echo       Add-Content -Path $confFile -Value ^"server {`n    listen 80;`n    server_name $domain;^" >> "%PS1_TMP%"
echo       if ($svc.static_paths) { foreach ($sp in $svc.static_paths) { >> "%PS1_TMP%"
echo         Add-Content -Path $confFile -Value ^"    location $($sp.path) {`n        alias $($sp.dir)/;`n    }^" >> "%PS1_TMP%"
echo       } } >> "%PS1_TMP%"
echo       if ($svc.mfes) { foreach ($mfe in $svc.mfes) { >> "%PS1_TMP%"
echo         if ($mfe.port) { >> "%PS1_TMP%"
echo           Add-Content -Path $confFile -Value ^"    location $($mfe.path) {`n        proxy_pass http://127.0.0.1:$($mfe.port);`n        proxy_set_header Host `$host;`n    }^" >> "%PS1_TMP%"
echo         } elseif ($mfe.dir) { >> "%PS1_TMP%"
echo           Add-Content -Path $confFile -Value ^"    location $($mfe.path) {`n        alias $($mfe.dir)/;`n        try_files `$uri `$uri/ /index.html;`n    }^" >> "%PS1_TMP%"
echo         } >> "%PS1_TMP%"
echo       } } >> "%PS1_TMP%"
echo       if ($svc.websockets) { foreach ($ws in $svc.websockets) { >> "%PS1_TMP%"
echo         Add-Content -Path $confFile -Value ^"    location $($ws.path) {`n        proxy_pass http://127.0.0.1:$($ws.port);`n        proxy_http_version 1.1;`n        proxy_set_header Upgrade `$http_upgrade;`n        proxy_set_header Connection `"Upgrade`";`n        proxy_set_header Host `$host;`n    }^" >> "%PS1_TMP%"
echo       } } >> "%PS1_TMP%"
echo       Add-Content -Path $confFile -Value ^"    location / {`n        proxy_pass http://127.0.0.1:$port;`n        proxy_set_header Host `$host;`n        proxy_set_header X-Real-IP `$remote_addr;`n        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;`n    }`n}^" >> "%PS1_TMP%"
echo     } elseif ($svc.type -eq 'static'^) { >> "%PS1_TMP%"
echo       Add-Content -Path $confFile -Value ^"server {`n    listen 80;`n    server_name $domain;`n    root $webrootBase/$($svc.id);`n    index index.html;`n    location / {`n        try_files `$uri `$uri/ /index.html;`n    }`n}^" >> "%PS1_TMP%"
echo     } >> "%PS1_TMP%"
echo   } >> "%PS1_TMP%"
echo } >> "%PS1_TMP%"

:: CADDY
echo elseif ($proxyType -eq 'caddy'^) { >> "%PS1_TMP%"
echo   $confFile = Join-Path $confDir 'Caddyfile' >> "%PS1_TMP%"
echo   Set-Content -Path $confFile -Value '# Auto-generated Caddyfile' >> "%PS1_TMP%"
echo   foreach ($svc in $manifest.services) { >> "%PS1_TMP%"
echo     $domain = if ($svc.domain) { $svc.domain } else { ^"$($svc.id).local^" } >> "%PS1_TMP%"
echo     if ($svc.type -eq 'wsgi' -or $svc.type -eq 'asgi'^) { >> "%PS1_TMP%"
echo       $port = $svc.port_binding >> "%PS1_TMP%"
echo       Add-Content -Path $confFile -Value ^"$domain {^" >> "%PS1_TMP%"
echo       if ($svc.static_paths) { foreach ($sp in $svc.static_paths) { >> "%PS1_TMP%"
echo         Add-Content -Path $confFile -Value ^"    handle_path $($sp.path)* {`n        root * $($sp.dir)`n        file_server`n    }^" >> "%PS1_TMP%"
echo       } } >> "%PS1_TMP%"
echo       if ($svc.mfes) { foreach ($mfe in $svc.mfes) { >> "%PS1_TMP%"
echo         if ($mfe.port) { >> "%PS1_TMP%"
echo           Add-Content -Path $confFile -Value ^"    handle_path $($mfe.path)* {`n        reverse_proxy 127.0.0.1:$($mfe.port)`n    }^" >> "%PS1_TMP%"
echo         } elseif ($mfe.dir) { >> "%PS1_TMP%"
echo           Add-Content -Path $confFile -Value ^"    handle_path $($mfe.path)* {`n        root * $($mfe.dir)`n        file_server`n        try_files {path} {path}/ /index.html`n    }^" >> "%PS1_TMP%"
echo         } >> "%PS1_TMP%"
echo       } } >> "%PS1_TMP%"
echo       if ($svc.websockets) { foreach ($ws in $svc.websockets) { >> "%PS1_TMP%"
echo         Add-Content -Path $confFile -Value ^"    handle $($ws.path)* {`n        reverse_proxy 127.0.0.1:$($ws.port)`n    }^" >> "%PS1_TMP%"
echo       } } >> "%PS1_TMP%"
echo       Add-Content -Path $confFile -Value ^"    reverse_proxy 127.0.0.1:$port`n}^" >> "%PS1_TMP%"
echo     } elseif ($svc.type -eq 'static'^) { >> "%PS1_TMP%"
echo       Add-Content -Path $confFile -Value ^"$domain {`n    root * $webrootBase/$($svc.id)`n    file_server`n    try_files {path} {path}/ /index.html`n}^" >> "%PS1_TMP%"
echo     } >> "%PS1_TMP%"
echo   } >> "%PS1_TMP%"
echo } >> "%PS1_TMP%"

:: HTTPD
echo elseif ($proxyType -eq 'httpd' -or $proxyType -eq 'apache2'^) { >> "%PS1_TMP%"
echo   $confFile = Join-Path $confDir 'httpd-vhosts.conf' >> "%PS1_TMP%"
echo   Set-Content -Path $confFile -Value '# Auto-generated Httpd Config' >> "%PS1_TMP%"
echo   foreach ($svc in $manifest.services) { >> "%PS1_TMP%"
echo     $domain = if ($svc.domain) { $svc.domain } else { ^"$($svc.id).local^" } >> "%PS1_TMP%"
echo     if ($svc.type -eq 'wsgi' -or $svc.type -eq 'asgi'^) { >> "%PS1_TMP%"
echo       $port = $svc.port_binding >> "%PS1_TMP%"
echo       Add-Content -Path $confFile -Value ^"<VirtualHost *:80>`n    ServerName $domain^" >> "%PS1_TMP%"
echo       if ($svc.static_paths) { foreach ($sp in $svc.static_paths) { >> "%PS1_TMP%"
echo         Add-Content -Path $confFile -Value ^"    Alias $($sp.path) `"$($sp.dir)/`"^" >> "%PS1_TMP%"
echo       } } >> "%PS1_TMP%"
echo       if ($svc.mfes) { foreach ($mfe in $svc.mfes) { >> "%PS1_TMP%"
echo         if ($mfe.port) { >> "%PS1_TMP%"
echo           Add-Content -Path $confFile -Value ^"    ProxyPass $($mfe.path) http://127.0.0.1:$($mfe.port)$($mfe.path)`n    ProxyPassReverse $($mfe.path) http://127.0.0.1:$($mfe.port)$($mfe.path)^" >> "%PS1_TMP%"
echo         } elseif ($mfe.dir) { >> "%PS1_TMP%"
echo           Add-Content -Path $confFile -Value ^"    Alias $($mfe.path) `"$($mfe.dir)/`"^" >> "%PS1_TMP%"
echo         } >> "%PS1_TMP%"
echo       } } >> "%PS1_TMP%"
echo       if ($svc.websockets) { foreach ($ws in $svc.websockets) { >> "%PS1_TMP%"
echo         Add-Content -Path $confFile -Value ^"    ProxyPass $($ws.path) ws://127.0.0.1:$($ws.port)$($ws.path)`n    ProxyPassReverse $($ws.path) ws://127.0.0.1:$($ws.port)$($ws.path)^" >> "%PS1_TMP%"
echo       } } >> "%PS1_TMP%"
echo       Add-Content -Path $confFile -Value ^"    ProxyPass / http://127.0.0.1:$port/`n    ProxyPassReverse / http://127.0.0.1:$port/`n</VirtualHost>^" >> "%PS1_TMP%"
echo     } elseif ($svc.type -eq 'static'^) { >> "%PS1_TMP%"
echo       Add-Content -Path $confFile -Value ^"<VirtualHost *:80>`n    ServerName $domain`n    DocumentRoot `"$webrootBase/$($svc.id)`"`n</VirtualHost>^" >> "%PS1_TMP%"
echo     } >> "%PS1_TMP%"
echo   } >> "%PS1_TMP%"
echo } >> "%PS1_TMP%"

:: IIS
echo elseif ($proxyType -eq 'iis'^) { >> "%PS1_TMP%"
echo   $confFile = Join-Path $confDir 'Web.config' >> "%PS1_TMP%"
echo   Set-Content -Path $confFile -Value ^"<?xml version=`"1.0`" encoding=`"UTF-8`"?><configuration><system.webServer><rewrite><rules>^" >> "%PS1_TMP%"
echo   foreach ($svc in $manifest.services) { >> "%PS1_TMP%"
echo     $domain = if ($svc.domain) { $svc.domain } else { ^"$($svc.id).local^" } >> "%PS1_TMP%"
echo     if ($svc.type -eq 'wsgi' -or $svc.type -eq 'asgi'^) { >> "%PS1_TMP%"
echo       $port = $svc.port_binding >> "%PS1_TMP%"
echo       if ($svc.websockets) { foreach ($ws in $svc.websockets) { >> "%PS1_TMP%"
echo         $pmatch = $($ws.path).TrimStart('/') >> "%PS1_TMP%"
echo         Add-Content -Path $confFile -Value ^"        <rule name=`"ReverseProxyWebSocket_$($svc.id)_$($ws.port)`" stopProcessing=`"true`"><match url=`"^$pmatch(.*)`" /><conditions><add input=`"{HTTP_HOST}`" pattern=`"^$domain$`" /></conditions><action type=`"Rewrite`" url=`"ws://127.0.0.1:$($ws.port)$($ws.path){R:1}`" /></rule>^" >> "%PS1_TMP%"
echo       } } >> "%PS1_TMP%"
echo       if ($svc.mfes) { foreach ($mfe in $svc.mfes) { >> "%PS1_TMP%"
echo         if ($mfe.port) { >> "%PS1_TMP%"
echo           $pmatch = $($mfe.path).TrimStart('/') >> "%PS1_TMP%"
echo           Add-Content -Path $confFile -Value ^"        <rule name=`"ReverseProxyMFE_$($svc.id)_$($mfe.port)`" stopProcessing=`"true`"><match url=`"^$pmatch(.*)`" /><conditions><add input=`"{HTTP_HOST}`" pattern=`"^$domain$`" /></conditions><action type=`"Rewrite`" url=`"http://127.0.0.1:$($mfe.port)$($mfe.path){R:1}`" /></rule>^" >> "%PS1_TMP%"
echo         } >> "%PS1_TMP%"
echo       } } >> "%PS1_TMP%"
echo       Add-Content -Path $confFile -Value ^"        <rule name=`"ReverseProxyInbound_$($svc.id)`" stopProcessing=`"true`"><match url=`"(.*)`" /><conditions><add input=`"{HTTP_HOST}`" pattern=`"^$domain$`" /></conditions><action type=`"Rewrite`" url=`"http://127.0.0.1:$port/{R:1}`" /></rule>^" >> "%PS1_TMP%"
echo     } >> "%PS1_TMP%"
echo   } >> "%PS1_TMP%"
echo   Add-Content -Path $confFile -Value ^"</rules></rewrite></system.webServer></configuration>^" >> "%PS1_TMP%"
echo } >> "%PS1_TMP%"
echo else { Write-Error `"Unsupported proxy type $proxyType`"; exit 1 } >> "%PS1_TMP%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1_TMP%"
set "PS1_EXIT=%ERRORLEVEL%"
del "%PS1_TMP%"
exit /b %PS1_EXIT%