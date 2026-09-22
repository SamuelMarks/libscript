@echo off
setlocal EnableDelayedExpansion
:: # LibScript Package Manager Module (Windows Batch)
::
:: ## Overview
:: This module abstracts package management and downloading operations.
::
:: ## Usage
:: ```batch
:: call "%LIBSCRIPT_ROOT_DIR%\\_lib\\_common\\pkg_mgr.cmd" :libscript_download <url> <dest>
:: ```
set "THIS_FILE=%~f0"


if not defined LIBSCRIPT_ROOT_DIR (
        set "LIBSCRIPT_ROOT_DIR=%~dp0..\.."
)

:: Source logging
set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"

goto :eof

:: Unified Caching Downloader (Windows)
:: ## libscript_download
:: Executes libscript_download functionality.
:libscript_download
set "url=%~1"
set "dest=%~2"
set "provided_checksum=%~3"

if "!dest!"=="" for %%F in ("!url!") do set "dest=%%~nxF"

:: 1. Checksum Resolution
set "checksum_db=%LIBSCRIPT_ROOT_DIR%\_lib/checksums.txt"
set "expected_checksum=!provided_checksum!"
if "!expected_checksum!"=="" (
        if exist "!checksum_db!" (
                for /f "tokens=2" %%i in ('findstr /L /C:"!url!" "!checksum_db!"') do (
                        set "expected_checksum=%%i"
                        goto :found_checksum
                )
        )
)
:: ## found_checksum
:: Executes found_checksum functionality.
:found_checksum

:: 2. Aria2 Export Mode
if defined LIBSCRIPT_ARIA2_EXPORT_FILE (
        set "skip_export="
        if exist "!LIBSCRIPT_ARIA2_EXPORT_FILE!" (
                findstr /L /X /C:"!url!" "!LIBSCRIPT_ARIA2_EXPORT_FILE!" >nul 2>&1
                if not errorlevel 1 set "skip_export=1"
        )
        if not defined skip_export (
                echo !url!>> "!LIBSCRIPT_ARIA2_EXPORT_FILE!"
                for %%F in ("!dest!") do echo   out=%%~nxF>> "!LIBSCRIPT_ARIA2_EXPORT_FILE!"
                if not "!expected_checksum!"=="" echo   checksum=sha-256=!expected_checksum!>> "!LIBSCRIPT_ARIA2_EXPORT_FILE!"
        )
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
set "download_needed=1"
if exist "!cache_file!" (
        call "%LOG_CMD%" :log_info "[CACHED] !url!"
        set "download_needed=0"
) else (
        if exist "!cache_dir!\!filename!" (
                call "%LOG_CMD%" :log_info "[CACHED] !url! (found in !cache_dir!\!filename!)"
                copy /y "!cache_dir!\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\runtimes\!filename!" (
                call "%LOG_CMD%" :log_info "[CACHED] !url! (found in !cache_dir!\runtimes\!filename!)"
                copy /y "!cache_dir!\runtimes\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\databases\!filename!" (
                call "%LOG_CMD%" :log_info "[CACHED] !url! (found in !cache_dir!\databases\!filename!)"
                copy /y "!cache_dir!\databases\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\wheels\!filename!" (
                call "%LOG_CMD%" :log_info "[CACHED] !url! (found in !cache_dir!\wheels\!filename!)"
                copy /y "!cache_dir!\wheels\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\npm\!filename!" (
                call "%LOG_CMD%" :log_info "[CACHED] !url! (found in !cache_dir!\npm\!filename!)"
                copy /y "!cache_dir!\npm\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\codebase\!filename!" (
                call "%LOG_CMD%" :log_info "[CACHED] !url! (found in !cache_dir!\codebase\!filename!)"
                copy /y "!cache_dir!\codebase\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "%LIBSCRIPT_ROOT_DIR%\cache\!filename!" (
                call "%LOG_CMD%" :log_info "[CACHED] !url! (found in %LIBSCRIPT_ROOT_DIR%\cache\!filename!)"
                copy /y "%LIBSCRIPT_ROOT_DIR%\cache\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        )
)

if "!download_needed!"=="1" (
        if "%LIBSCRIPT_OFFLINE%"=="1" (
                call "%LOG_CMD%" :log_error "Error: [OFFLINE] Cannot download '!url!'. Artifact not found in local cache at '!cache_file!'."
                echo Error: [OFFLINE] Cannot download '!url!'. Artifact not found in local cache at '!cache_file!'. >&2
                if "%LIBSCRIPT_FORCE_OFFLINE%"=="1" (
                        echo Fatal: LIBSCRIPT_FORCE_OFFLINE=1 strictly prohibits network requests. >&2
                        exit /b 1
                )
                exit /b 1
        )
        if "%LIBSCRIPT_FORCE_OFFLINE%"=="1" (
                call "%LOG_CMD%" :log_error "Fatal: LIBSCRIPT_FORCE_OFFLINE=1 strictly prohibits network requests."
                echo Fatal: LIBSCRIPT_FORCE_OFFLINE=1 strictly prohibits network requests. >&2
                exit /b 1
        )

        call "%LOG_CMD%" :log_info "[DOWNLOADING] !url!"
    
        set "download_success=0"
    
        REM Strategy A: curl
        where curl >nul 2>&1
        if !errorlevel! equ 0 (
                curl -L "!url!" -o "!cache_file!"
                if !errorlevel! equ 0 set "download_success=1"
        )
    
        REM Strategy B: powershell
        if !download_success! equ 0 (
                where powershell >nul 2>&1
                if !errorlevel! equ 0 (
                        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '!url!' -OutFile '!cache_file!'"
                        if !errorlevel! equ 0 set "download_success=1"
                )
        )
    
        REM Strategy C: certutil
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
                findstr /c:"!url! !actual_checksum!" "!checksum_db!" >nul 2>&1 || echo !url! !actual_checksum!>> "!checksum_db!"
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

:: ## libscript_fetch
:: Executes libscript_fetch functionality.
:libscript_fetch
call :libscript_download %*
exit /b %errorlevel%
