@echo off
setlocal EnableDelayedExpansion

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%~dp0..\.."
)

:: Source logging
set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"

goto :eof

:: Unified Caching Downloader (Windows)
:libscript_download
set "url=%~1"
set "dest=%~2"
set "provided_checksum=%~3"

if "!dest!"=="" for %%F in ("!url!") do set "dest=%%~nxF"

:: 1. Checksum Resolution
set "checksum_db=%LIBSCRIPT_ROOT_DIR%\checksums.txt"
set "expected_checksum=!provided_checksum!"
if "!expected_checksum!"=="" (
    if exist "!checksum_db!" (
        for /f "tokens=2" %%i in ('findstr /L /C:"!url!" "!checksum_db!"') do (
            set "expected_checksum=%%i"
            goto :found_checksum
        )
    )
)
:found_checksum

:: 2. Aria2 Export Mode
if defined LIBSCRIPT_ARIA2_EXPORT_FILE (
    echo !url!>> "!LIBSCRIPT_ARIA2_EXPORT_FILE!"
    for %%F in ("!dest!") do echo   out=%%~nxF>> "!LIBSCRIPT_ARIA2_EXPORT_FILE!"
    if not "!expected_checksum!"=="" echo   checksum=sha-256=!expected_checksum!>> "!LIBSCRIPT_ARIA2_EXPORT_FILE!"
    exit /b 0
)

:: 3. Cache Path Resolution
set "cache_dir=%LIBSCRIPT_CACHE_DIR%"
if "!cache_dir!"=="" set "cache_dir=%LIBSCRIPT_ROOT_DIR%\cache\downloads"

if "%DOWNLOAD_DIR%"=="" (
    set "dl_dir=!cache_dir!"
    if defined PACKAGE_NAME (
        set "dl_dir=!dl_dir!\!PACKAGE_NAME!"
    ) else (
        set "dl_dir=!dl_dir!\unknown"
    )
) else (
    set "dl_dir=%DOWNLOAD_DIR%"
)

if not exist "!dl_dir!" mkdir "!dl_dir!"
for %%F in ("!url!") do set "filename=%%~nxF"
set "cache_file=!dl_dir!\!filename!"

:: 4. Cache Check & Download
if exist "!cache_file!" (
    call "%LOG_CMD%" :log_info "[CACHED] !url!"
) else (
    call "%LOG_CMD%" :log_info "[DOWNLOADING] !url!"
    
    set "download_success=0"
    
    :: Strategy A: curl
    where curl >nul 2>&1
    if !errorlevel! equ 0 (
        curl -L "!url!" -o "!cache_file!"
        if !errorlevel! equ 0 set "download_success=1"
    )
    
    :: Strategy B: powershell
    if !download_success! equ 0 (
        where powershell >nul 2>&1
        if !errorlevel! equ 0 (
            powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '!url!' -OutFile '!cache_file!'"
            if !errorlevel! equ 0 set "download_success=1"
        )
    )
    
    :: Strategy C: certutil
    if !download_success! equ 0 (
        certutil -urlcache -split -f "!url!" "!cache_file!" >nul
        if !errorlevel! equ 0 set "download_success=1"
    )

    if !download_success! equ 0 (
        call "%LOG_CMD%" :log_error "Download failed for !url!"
        exit /b 1
    )
    
    for %%A in ("!cache_file!") do set size=%%~zA
    if "!size!"=="0" (
        call "%LOG_CMD%" :log_error "Downloaded file is empty"
        del "!cache_file!"
        exit /b 1
    )
)

:: 5. Checksum Validation
if not "!expected_checksum!"=="" (
    if /i not "!expected_checksum!"=="SKIP" (
        set "clean_expected=!expected_checksum:sha-256=!"
        for /f "tokens=*" %%a in ('powershell -Command "(Get-FileHash -Path '!cache_file!' -Algorithm SHA256).Hash.ToLower()"') do set "actual_checksum=%%a"
        if not "!actual_checksum!"=="!clean_expected!" (
            call "%LOG_CMD%" :log_error "Checksum mismatch for !cache_file!. Expected: !clean_expected!, Got: !actual_checksum!"
            del "!cache_file!"
            exit /b 1
        )
    )
) else (
    if not "%LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB%"=="1" (
        for /f "tokens=*" %%a in ('powershell -Command "(Get-FileHash -Path '!cache_file!' -Algorithm SHA256).Hash.ToLower()"') do set "actual_checksum=%%a"
        echo !url! !actual_checksum!>> "!checksum_db!"
    )
)

:: 6. Final Placement
if not "!dest!"=="" (
    if /i not "!dest!"=="!cache_file!" (
        for %%D in ("!dest!") do if not exist "%%~dpD" mkdir "%%~dpD"
        copy /y "!cache_file!" "!dest!" >nul
    )
)
exit /b 0

:libscript_fetch
call :libscript_download %*
exit /b %errorlevel%
