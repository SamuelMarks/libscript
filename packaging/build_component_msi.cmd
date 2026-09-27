@echo off
rem ## Overview
rem Builds a standalone Windows Installer (.msi) package for an individual LibScript dependency.
rem Supports lightweight online installer and air-gapped offline installer with pre-bundled dependencies.
rem
rem ## Usage
rem   call packaging\build_component_msi.cmd [OPTIONS]
rem
rem ## Parameters
rem   --component <name>       Component to package (mysql, redis, mongodb, python, nodejs, meilisearch)
rem   --version <ver>          Component release version (default: auto-detected from offline bundle)
rem   --variant <var>          Installer variant: online, offline, or all (default: all)
rem   --help, -h               Show this help text

setlocal enabledelayedexpansion

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
for %%I in ("%SCRIPT_DIR%..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

set "COMPONENT="
set "VERSION="
set "VARIANT=all"
set "OUT_FILE="
set "BRANCH="
set "OUT_DIR=%LIBSCRIPT_ROOT_DIR%\dist\msi"
set "OFFLINE_SOURCE=%LIBSCRIPT_ROOT_DIR%\cache"
set "HYDRATE=0"
set "ALLOW_MOCK=0"

:: ## parse_loop
:: Iterates over and parses command line arguments.
:parse_loop
if "%~1"=="" goto parse_done
if /i "%~1"=="--component" (
    set "COMPONENT=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--version" (
    set "VERSION=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--variant" (
    set "VARIANT=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--online" (
    set "VARIANT=online"
    shift
    goto parse_loop
)
if /i "%~1"=="--offline" (
    set "VARIANT=offline"
    shift
    goto parse_loop
)
if /i "%~1"=="--out" (
    set "OUT_FILE=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--out-dir" (
    set "OUT_DIR=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--offline-source" (
    set "OFFLINE_SOURCE=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--hydrate" (
    set "HYDRATE=1"
    shift
    goto parse_loop
)
if /i "%~1"=="--allow-mock" (
    set "ALLOW_MOCK=1"
    shift
    goto parse_loop
)
if /i "%~1"=="--branch" (
    set "BRANCH=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-h" goto show_help
shift
goto parse_loop

:: ## show_help
:: Displays command usage documentation.
:show_help
echo LibScript Standalone Component MSI Builder
echo.
echo Usage:
echo   call packaging\build_component_msi.cmd [OPTIONS]
echo.
echo Options:
echo   --component ^<name^>       Component identifier (mysql, redis, mongodb, python, nodejs, meilisearch)
echo   --version ^<ver^>          Release version (defaults to version from offline_bundle.json)
echo   --variant ^<var^>          Installer variant (online, offline, or all; default: all)
echo   --online                 Build lightweight online installer
echo   --offline                Build air-gapped offline installer with embedded payload
echo   --out ^<name^>             Output file base name or path
echo   --out-dir ^<dir^>          Output directory (default: dist\msi)
echo   --offline-source ^<dir^>   Offline cache directory containing binary archives (default: cache)
echo   --hydrate                Force hydration of offline cache before building
echo   --allow-mock             Allow fallback to mock binaries if offline assets cannot be acquired
echo   --branch ^<name^>          Branch or tag ref (optional)
echo   --help, -h               Show this help text
exit /b 0

:: ## parse_done
:: Prepares configuration and triggers variant compilation.
:parse_done
if "%COMPONENT%"=="" (
    echo [ERROR] --component is mandatory. >&2
    exit /b 1
)

set "BUNDLE_JSON=%LIBSCRIPT_ROOT_DIR%\stacks\cms\openedx\offline_bundle.json"
if "%VERSION%"=="" if exist "%BUNDLE_JSON%" (
    if /i "%COMPONENT%"=="mysql" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).databases.mysql.version"`) do set "VERSION=%%A"
    if /i "%COMPONENT%"=="redis" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).databases.redis.version"`) do set "VERSION=%%A"
    if /i "%COMPONENT%"=="mongodb" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).databases.mongodb.version"`) do set "VERSION=%%A"
    if /i "%COMPONENT%"=="python" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).runtimes.python.version"`) do set "VERSION=%%A"
    if /i "%COMPONENT%"=="nodejs" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).runtimes.nodejs.version"`) do set "VERSION=%%A"
    if /i "%COMPONENT%"=="meilisearch" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).databases.meilisearch.version"`) do set "VERSION=%%A"
)
if "%VERSION%"=="" set "VERSION=1.0.0"

if /i "%VARIANT%"=="online" (
    call :build_single_variant online
    exit /b %ERRORLEVEL%
)
if /i "%VARIANT%"=="offline" (
    call :build_single_variant offline
    exit /b %ERRORLEVEL%
)
if /i "%VARIANT%"=="all" (
    call :build_single_variant online
    if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
    call :build_single_variant offline
    exit /b !ERRORLEVEL!
)

echo [ERROR] Unknown variant: %VARIANT%. Use online, offline, or all. >&2
exit /b 1

:: ## build_single_variant
:: Compiles an individual variant (online or offline) for the specified component.
::
:: ## Parameters
::   %~1 - Variant ("online" or "offline")
:build_single_variant
set "CURR_VAR=%~1"
set "STAGE_ROOT=%LIBSCRIPT_ROOT_DIR%\tmp\stage_component_%COMPONENT%_%CURR_VAR%"
if exist "%STAGE_ROOT%" rmdir /s /q "%STAGE_ROOT%" 2>nul
if not exist "%STAGE_ROOT%\bin" mkdir "%STAGE_ROOT%\bin" 2>nul
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%" 2>nul

if /i "%CURR_VAR%"=="offline" (
    set "NEED_HYDRATE=0"
    if /i "%COMPONENT%"=="mysql" (
        set "FOUND_ARC="
        for %%F in ("%OFFLINE_SOURCE%\databases\mysql-*.zip") do if exist "%%~fF" set "FOUND_ARC=%%~fF"
        if "!FOUND_ARC!"=="" set "NEED_HYDRATE=1"
    )
    if /i "%COMPONENT%"=="redis" (
        set "FOUND_ARC="
        for %%F in ("%OFFLINE_SOURCE%\databases\redis-*.zip" "%OFFLINE_SOURCE%\databases\Redis-*.zip") do if exist "%%~fF" set "FOUND_ARC=%%~fF"
        if "!FOUND_ARC!"=="" set "NEED_HYDRATE=1"
    )
    if /i "%COMPONENT%"=="mongodb" (
        set "FOUND_ARC="
        for %%F in ("%OFFLINE_SOURCE%\databases\mongodb-*.zip") do if exist "%%~fF" set "FOUND_ARC=%%~fF"
        if "!FOUND_ARC!"=="" set "NEED_HYDRATE=1"
    )
    if /i "%COMPONENT%"=="python" (
        set "FOUND_ARC="
        for %%F in ("%OFFLINE_SOURCE%\runtimes\python-*.zip") do if exist "%%~fF" set "FOUND_ARC=%%~fF"
        if "!FOUND_ARC!"=="" set "NEED_HYDRATE=1"
    )
    if /i "%COMPONENT%"=="nodejs" (
        set "FOUND_ARC="
        for %%F in ("%OFFLINE_SOURCE%\runtimes\node-*.zip") do if exist "%%~fF" set "FOUND_ARC=%%~fF"
        if "!FOUND_ARC!"=="" set "NEED_HYDRATE=1"
    )
    if /i "%COMPONENT%"=="meilisearch" (
        set "FOUND_ARC="
        for %%F in ("%OFFLINE_SOURCE%\databases\meilisearch-*.exe") do if exist "%%~fF" set "FOUND_ARC=%%~fF"
        if "!FOUND_ARC!"=="" set "NEED_HYDRATE=1"
    )

    if "%HYDRATE%"=="1" set "NEED_HYDRATE=1"
    if "!NEED_HYDRATE!"=="1" if "%ALLOW_MOCK%"=="0" (
        echo [INFO] Hydrating %COMPONENT% offline cache before build...
        call "%SCRIPT_DIR%hydrate_offline_cache.cmd" --manifest "%BUNDLE_JSON%" --cache-dir "%OFFLINE_SOURCE%" --component "%COMPONENT%"
    )

    if /i "%COMPONENT%"=="mysql" (
        set "FOUND_ARC="
        for %%F in ("%OFFLINE_SOURCE%\databases\mysql-*.zip") do if exist "%%~fF" set "FOUND_ARC=%%~fF"
        if not "!FOUND_ARC!"=="" (
            powershell -NoProfile -Command "Expand-Archive -Path '!FOUND_ARC!' -DestinationPath '%STAGE_ROOT%' -Force" >nul 2>&1
            for /d %%D in ("%STAGE_ROOT%\*") do (
                if exist "%%~fD\bin" (
                    xcopy /E /Y /Q "%%~fD\*" "%STAGE_ROOT%" >nul 2>&1
                    rmdir /s /q "%%~fD" >nul 2>&1
                )
            )
        ) else if "%ALLOW_MOCK%"=="1" (
            echo Mock MySQL binary > "%STAGE_ROOT%\bin\mysqld.exe"
        ) else (
            echo [ERROR] Offline MySQL archive missing from %OFFLINE_SOURCE% >&2
            exit /b 1
        )
    )
    if /i "%COMPONENT%"=="redis" (
        set "FOUND_ARC="
        for %%F in ("%OFFLINE_SOURCE%\databases\redis-*.zip" "%OFFLINE_SOURCE%\databases\Redis-*.zip") do if exist "%%~fF" set "FOUND_ARC=%%~fF"
        if not "!FOUND_ARC!"=="" (
            powershell -NoProfile -Command "Expand-Archive -Path '!FOUND_ARC!' -DestinationPath '%STAGE_ROOT%' -Force" >nul 2>&1
            for /d %%D in ("%STAGE_ROOT%\*") do (
                if /i not "%%~nxD"=="bin" (
                    if exist "%%~fD\bin" (
                        xcopy /E /Y /Q "%%~fD\*" "%STAGE_ROOT%" >nul 2>&1
                        rmdir /s /q "%%~fD" >nul 2>&1
                    ) else (
                        if not exist "%STAGE_ROOT%\bin" mkdir "%STAGE_ROOT%\bin" 2>nul
                        xcopy /E /Y /Q "%%~fD\*" "%STAGE_ROOT%\bin" >nul 2>&1
                        rmdir /s /q "%%~fD" >nul 2>&1
                    )
                )
            )
            if not exist "%STAGE_ROOT%\bin" mkdir "%STAGE_ROOT%\bin" 2>nul
            if exist "%STAGE_ROOT%\redis-server.exe" if not exist "%STAGE_ROOT%\bin\redis-server.exe" (
                copy /y "%STAGE_ROOT%\redis-server.exe" "%STAGE_ROOT%\bin" >nul 2>&1
                copy /y "%STAGE_ROOT%\redis-cli.exe" "%STAGE_ROOT%\bin" >nul 2>&1
            )
        ) else if "%ALLOW_MOCK%"=="1" (
            echo Mock Redis binary > "%STAGE_ROOT%\bin\redis-server.exe"
        ) else (
            echo [ERROR] Offline Redis archive missing from %OFFLINE_SOURCE% >&2
            exit /b 1
        )
    )
    if /i "%COMPONENT%"=="mongodb" (
        set "FOUND_ARC="
        for %%F in ("%OFFLINE_SOURCE%\databases\mongodb-*.zip") do if exist "%%~fF" set "FOUND_ARC=%%~fF"
        if not "!FOUND_ARC!"=="" (
            powershell -NoProfile -Command "Expand-Archive -Path '!FOUND_ARC!' -DestinationPath '%STAGE_ROOT%' -Force" >nul 2>&1
            for /d %%D in ("%STAGE_ROOT%\*") do (
                if exist "%%~fD\bin" (
                    xcopy /E /Y /Q "%%~fD\*" "%STAGE_ROOT%" >nul 2>&1
                    rmdir /s /q "%%~fD" >nul 2>&1
                )
            )
        ) else if "%ALLOW_MOCK%"=="1" (
            echo Mock MongoDB binary > "%STAGE_ROOT%\bin\mongod.exe"
        ) else (
            echo [ERROR] Offline MongoDB archive missing from %OFFLINE_SOURCE% >&2
            exit /b 1
        )
    )
    if /i "%COMPONENT%"=="python" (
        set "FOUND_ARC="
        for %%F in ("%OFFLINE_SOURCE%\runtimes\python-*.zip") do if exist "%%~fF" set "FOUND_ARC=%%~fF"
        if not "!FOUND_ARC!"=="" (
            powershell -NoProfile -Command "Expand-Archive -Path '!FOUND_ARC!' -DestinationPath '%STAGE_ROOT%' -Force" >nul 2>&1
            if exist "%STAGE_ROOT%\python.exe" if not exist "%STAGE_ROOT%\bin\python.exe" (
                copy /y "%STAGE_ROOT%\python.exe" "%STAGE_ROOT%\bin" >nul 2>&1
            )
        ) else if "%ALLOW_MOCK%"=="1" (
            echo Mock Python binary > "%STAGE_ROOT%\bin\python.exe"
        ) else (
            echo [ERROR] Offline Python archive missing from %OFFLINE_SOURCE% >&2
            exit /b 1
        )
    )
    if /i "%COMPONENT%"=="nodejs" (
        set "FOUND_ARC="
        for %%F in ("%OFFLINE_SOURCE%\runtimes\node-*.zip") do if exist "%%~fF" set "FOUND_ARC=%%~fF"
        if not "!FOUND_ARC!"=="" (
            powershell -NoProfile -Command "Expand-Archive -Path '!FOUND_ARC!' -DestinationPath '%STAGE_ROOT%' -Force" >nul 2>&1
            for /d %%D in ("%STAGE_ROOT%\*") do (
                xcopy /E /Y /Q "%%~fD\*" "%STAGE_ROOT%" >nul 2>&1
                rmdir /s /q "%%~fD" >nul 2>&1
            )
            if exist "%STAGE_ROOT%\node.exe" if not exist "%STAGE_ROOT%\bin\node.exe" (
                copy /y "%STAGE_ROOT%\node.exe" "%STAGE_ROOT%\bin" >nul 2>&1
            )
        ) else if "%ALLOW_MOCK%"=="1" (
            echo Mock Node.js binary > "%STAGE_ROOT%\bin\node.exe"
        ) else (
            echo [ERROR] Offline Node.js archive missing from %OFFLINE_SOURCE% >&2
            exit /b 1
        )
    )
    if /i "%COMPONENT%"=="meilisearch" (
        set "FOUND_BIN="
        for %%F in ("%OFFLINE_SOURCE%\databases\meilisearch-*.exe") do if exist "%%~fF" set "FOUND_BIN=%%~fF"
        if not "!FOUND_BIN!"=="" (
            copy /y "!FOUND_BIN!" "%STAGE_ROOT%\bin\meilisearch.exe" >nul 2>&1
            copy /y "!FOUND_BIN!" "%STAGE_ROOT%\meilisearch.exe" >nul 2>&1
        ) else if "%ALLOW_MOCK%"=="1" (
            echo Mock Meilisearch binary > "%STAGE_ROOT%\bin\meilisearch.exe"
        ) else (
            echo [ERROR] Offline Meilisearch binary missing from %OFFLINE_SOURCE% >&2
            exit /b 1
        )
    )
) else (
    echo {"component":"%COMPONENT%","version":"%VERSION%","variant":"online"} > "%STAGE_ROOT%\component.json"
    echo LibScript %COMPONENT% Online Standalone Installer > "%STAGE_ROOT%\README.txt"
    echo LibScript %COMPONENT% Online Stub > "%STAGE_ROOT%\bin\README.txt"
)

set "MAIN_WXS=%LIBSCRIPT_ROOT_DIR%\tmp\%COMPONENT%_%CURR_VAR%_main.wxs"
set "PAYLOAD_WXS=%LIBSCRIPT_ROOT_DIR%\tmp\%COMPONENT%_%CURR_VAR%_payload.wxs"

call "%SCRIPT_DIR%template_component_msi.cmd" --component "%COMPONENT%" --version "%VERSION%" --variant "%CURR_VAR%" --out "%MAIN_WXS%"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call "%SCRIPT_DIR%harvest_payload.cmd" --source-dir "%STAGE_ROOT%" --wix-fragment "%PAYLOAD_WXS%" --component-group "PayloadComponents" --directory-id "INSTALLFOLDER"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

if defined OUT_FILE (
    set "TARGET_MSI=%OUT_FILE%"
    if /i "!TARGET_MSI:~-4!"==".msi" set "TARGET_MSI=!TARGET_MSI:~0,-4!"
    if /i "%VARIANT%"=="all" (
        if /i "%CURR_VAR%"=="offline" (
            set "TARGET_MSI=!TARGET_MSI!-offline.msi"
        ) else (
            set "TARGET_MSI=!TARGET_MSI!.msi"
        )
    ) else (
        set "TARGET_MSI=!TARGET_MSI!.msi"
    )
) else (
    if /i "%CURR_VAR%"=="offline" (
        set "TARGET_MSI=%OUT_DIR%\libscript-%COMPONENT%-offline-%VERSION%.msi"
    ) else (
        set "TARGET_MSI=%OUT_DIR%\libscript-%COMPONENT%-%VERSION%.msi"
    )
)

for %%I in ("%TARGET_MSI%") do (
    if not exist "%%~dpI" mkdir "%%~dpI" 2>nul
)

where candle.exe >nul 2>nul
if %ERRORLEVEL% neq 0 if exist "%LIBSCRIPT_ROOT_DIR%\tools\wix\candle.exe" (
    set "PATH=%LIBSCRIPT_ROOT_DIR%\tools\wix;!PATH!"
)

where wixl >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [INFO] Compiling standalone %CURR_VAR% MSI via wixl: %TARGET_MSI%
    set "WIXL_MAIN=%MAIN_WXS%_clean.wxs"
    set "WIXL_PAYLOAD=%PAYLOAD_WXS%_clean.wxs"
    powershell -NoProfile -Command "(Get-Content '%MAIN_WXS%') -replace ' Schedule=`"[^`"]*`"', '' -replace ' SharedDllRefCount=`"[^`"]*`"', '' -replace '(?s)<CustomAction.*?</InstallExecuteSequence>', '' | Set-Content '%WIXL_MAIN%'"
    powershell -NoProfile -Command "(Get-Content '%PAYLOAD_WXS%') -replace ' DiskId=`"[0-9]*`"', ' DiskId=`"1`"' | Set-Content '%WIXL_PAYLOAD%'"
    wixl -a x64 -o "%TARGET_MSI%" "%WIXL_MAIN%" "%WIXL_PAYLOAD%"
    set "WIXL_EXIT=!ERRORLEVEL!"
    del /f /q "%WIXL_MAIN%" "%WIXL_PAYLOAD%" 2>nul
    if !WIXL_EXIT! neq 0 (
        echo [ERROR] wixl compilation failed. >&2
        exit /b !WIXL_EXIT!
    )
    goto compile_done
)

where candle.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [INFO] Compiling standalone %CURR_VAR% MSI via WiX toolset...
    candle.exe -nologo -arch x64 -out "%LIBSCRIPT_ROOT_DIR%\tmp\%COMPONENT%_%CURR_VAR%_main.wixobj" "%MAIN_WXS%"
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] WiX candle compilation failed for %MAIN_WXS%. >&2
        exit /b !ERRORLEVEL!
    )
    candle.exe -nologo -arch x64 -out "%LIBSCRIPT_ROOT_DIR%\tmp\%COMPONENT%_%CURR_VAR%_payload.wixobj" "%PAYLOAD_WXS%"
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] WiX candle compilation failed for %PAYLOAD_WXS%. >&2
        exit /b !ERRORLEVEL!
    )
    light.exe -nologo -sval -ext WixUIExtension -out "%TARGET_MSI%" "%LIBSCRIPT_ROOT_DIR%\tmp\%COMPONENT%_%CURR_VAR%_main.wixobj" "%LIBSCRIPT_ROOT_DIR%\tmp\%COMPONENT%_%CURR_VAR%_payload.wixobj"
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] WiX light linking failed. >&2
        exit /b !ERRORLEVEL!
    )
    goto compile_done
)

echo [WARN] Neither wixl nor WiX toolset found in PATH.

:: ## compile_done
:: Validates the built MSI output package and syncs to output directory.
:compile_done
if not exist "%TARGET_MSI%" (
    echo [ERROR] Target MSI was not generated: %TARGET_MSI% >&2
    exit /b 1
)
for %%I in ("%TARGET_MSI%") do (
    if /i not "%%~dpI"=="%OUT_DIR%" (
        if not exist "%OUT_DIR%" mkdir "%OUT_DIR%" 2>nul
        copy /y "%TARGET_MSI%" "%OUT_DIR%" >nul 2>&1
    )
)
echo [PASS] Successfully processed standalone component MSI (%CURR_VAR%): %TARGET_MSI%
exit /b 0
