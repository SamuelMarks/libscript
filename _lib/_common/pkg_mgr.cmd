@echo off
:: # pkg_mgr.cmd
setlocal EnableDelayedExpansion
:: # LibScript Package Manager Module (Windows Batch)
::
:: ## Overview
:: This module abstracts package management and downloading operations.
::
:: ## Usage
:: ```batch
:: call "!LIBSCRIPT_ROOT_DIR!\\_lib\\_common\\pkg_mgr.cmd" :libscript_download <url> <dest>
:: ```
set "THIS_FILE=%~f0"


if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

if not defined LIBSCRIPT_ROOT_DIR (
        set "LIBSCRIPT_ROOT_DIR=%~dp0..\.."
)

:: Source logging
set "LOG_CMD=!LIBSCRIPT_ROOT_DIR!\_lib\_common\log.cmd"
set "MAPPER_CMD=!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mapper.cmd"

if not "%~1"=="" (
    set "_pm_sub=%~1"
    if "!_pm_sub:~0,1!"==":" (
        shift
        goto !_pm_sub!
    )
)
goto :eof

:: ## libscript_resolve_install_method
:: Resolves the installation method for a component on Windows, supporting pkg_mgr:<pm>, from-source, libscript_native, and system.
:libscript_resolve_install_method
set "_comp_up=%~1"
set "_req=!%_comp_up%_INSTALL_METHOD!"
if "!_req!"=="" set "_req=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
if "!_req:~0,8!"=="pkg_mgr:" (
    set "LIBSCRIPT_PKG_MGR=!_req:~8!"
    set "_req=system"
)
if /i not "!_req!"=="libscript_native" if /i not "!_req!"=="system" if /i not "!_req!"=="from-source" (
    set "_req=system"
)
endlocal & set "LIBSCRIPT_PKG_MGR=%LIBSCRIPT_PKG_MGR%" & set "RESOLVED_INSTALL_METHOD=%_req%"
exit /b 0

:: ## detect_pkg_mgr
:: Detects or honors an explicitly requested Windows package manager (winget, choco, scoop, vcpkg, conan).
:detect_pkg_mgr
set "_comp_up=%~1"
set "_req_pm="
if not "!_comp_up!"=="" set "_req_pm=!%_comp_up%_PKG_MGR!"
if "!_req_pm!"=="" if defined LIBSCRIPT_PKG_MGR set "_req_pm=%LIBSCRIPT_PKG_MGR%"
if /i "!_req_pm!"=="chocolatey" set "_req_pm=choco"
if not "!_req_pm!"=="" (
    set "PKG_MGR=!_req_pm!"
    exit /b 0
)
where winget >nul 2>&1
if !errorlevel! equ 0 (
    set "PKG_MGR=winget"
    exit /b 0
)
where choco >nul 2>&1
if !errorlevel! equ 0 (
    set "PKG_MGR=choco"
    exit /b 0
)
where scoop >nul 2>&1
if !errorlevel! equ 0 (
    set "PKG_MGR=scoop"
    exit /b 0
)
set "PKG_MGR=winget"
exit /b 0

:: ## libscript_depends_via
:: Installs one or more packages explicitly using a specified Windows package manager name.
:libscript_depends_via
set "_via_pm=%~1"
shift
set "_saved_pm=%LIBSCRIPT_PKG_MGR%"
set "LIBSCRIPT_PKG_MGR=%_via_pm%"
call :detect_pkg_mgr
call :libscript_depends %1 %2 %3 %4 %5 %6 %7 %8 %9
set "_rc=!errorlevel!"
set "LIBSCRIPT_PKG_MGR=%_saved_pm%"
exit /b !_rc!

:: ## libscript_depends
:: Resolves and installs system dependencies on Windows via the active package manager.
:libscript_depends
if "%LIBSCRIPT_SKIP_SYSTEM_DEPS%"=="1" exit /b 0
if defined LIBSCRIPT_PKG_MGR call :detect_pkg_mgr
if not defined PKG_MGR call :detect_pkg_mgr
goto :depends_loop

:: ## is_installed
:: Checks whether a mapped package is already installed under the active Windows package manager.
:is_installed
set "_chk_pkg=%~1"
if /i "!PKG_MGR!"=="winget" (
    winget list --exact --id "!_chk_pkg!" >nul 2>&1
    exit /b !errorlevel!
)
if /i "!PKG_MGR!"=="choco" (
    choco list --local-only "!_chk_pkg!" 2>nul | findstr /I /B /C:"!_chk_pkg! " >nul 2>&1
    exit /b !errorlevel!
)
if /i "!PKG_MGR!"=="scoop" (
    scoop list "!_chk_pkg!" 2>nul | findstr /I /C:"!_chk_pkg!" >nul 2>&1
    exit /b !errorlevel!
)
if /i "!PKG_MGR!"=="vcpkg" (
    vcpkg list 2>nul | findstr /I /B /C:"!_chk_pkg!:" >nul 2>&1
    exit /b !errorlevel!
)
exit /b 1

:: ## depends_loop
:: Iterates over requested package arguments, mapping and installing each dependency.
:depends_loop
if "%~1"=="" exit /b 0
set "_generic_pkg=%~1"
call "%MAPPER_CMD%" :map_package "!_generic_pkg!"
if "!MAPPED_PKG!"=="" set "MAPPED_PKG=!_generic_pkg!"
if "%LIBSCRIPT_DRY_RUN_PKG_MGR%"=="1" (
    echo [INFO] [DRY-RUN] ^(!PKG_MGR!^) install !MAPPED_PKG!
    shift
    goto :depends_loop
)
call :is_installed "!MAPPED_PKG!"
if not errorlevel 1 (
    call "!LOG_CMD!" :log_info "[REUSE] Package '!MAPPED_PKG!' is already installed via !PKG_MGR!."
    shift
    goto :depends_loop
)
if /i "!PKG_MGR!"=="winget" (
    winget install --exact --id "!MAPPED_PKG!" --accept-package-agreements --accept-source-agreements --silent
) else if /i "!PKG_MGR!"=="choco" (
    choco install -y "!MAPPED_PKG!"
) else if /i "!PKG_MGR!"=="scoop" (
    scoop install "!MAPPED_PKG!"
) else if /i "!PKG_MGR!"=="vcpkg" (
    vcpkg install "!MAPPED_PKG!"
) else if /i "!PKG_MGR!"=="conan" (
    conan install --requires="!MAPPED_PKG!" --build=missing
) else (
    winget install --exact --id "!MAPPED_PKG!" --accept-package-agreements --accept-source-agreements --silent
)
shift
goto :depends_loop

:: Unified Caching Downloader (Windows)
:: ## libscript_download
:: Performs the libscript_download operation and updates component state.
:libscript_download
set "url=%~1"
set "dest=%~2"
set "provided_checksum=%~3"
set "auth_header=%~4"
if "!auth_header!"=="" if defined LIBSCRIPT_DOWNLOAD_AUTH_HEADER set "auth_header=%LIBSCRIPT_DOWNLOAD_AUTH_HEADER%"

if "!dest!"=="" for %%F in ("!url!") do set "dest=%%~nxF"

:: 1. Checksum Resolution
set "checksum_db=!LIBSCRIPT_ROOT_DIR!\_lib\checksums.txt"
set "expected_checksum=!provided_checksum!"
if "!expected_checksum!"=="" (
        if exist "!checksum_db!" (
                for /f "tokens=2" %%i in ('findstr /L /C:"!url!" "!checksum_db!" 2^>nul') do (
                        set "expected_checksum=%%i"
                        goto :found_checksum
                )
        )
)
:: ## found_checksum
:: Performs the found_checksum operation and updates component state.
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
if "!cache_dir!"=="" set "cache_dir=!LIBSCRIPT_ROOT_DIR!\cache\downloads"

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
        call "!LOG_CMD!" :log_info "[CACHED] !url!"
        set "download_needed=0"
) else (
        if exist "!cache_dir!\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !cache_dir!\!filename!)"
                copy /y "!cache_dir!\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\runtimes\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !cache_dir!\runtimes\!filename!)"
                copy /y "!cache_dir!\runtimes\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\databases\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !cache_dir!\databases\!filename!)"
                copy /y "!cache_dir!\databases\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\wheels\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !cache_dir!\wheels\!filename!)"
                copy /y "!cache_dir!\wheels\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\npm\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !cache_dir!\npm\!filename!)"
                copy /y "!cache_dir!\npm\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\codebase\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !cache_dir!\codebase\!filename!)"
                copy /y "!cache_dir!\codebase\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!LIBSCRIPT_ROOT_DIR!\cache\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !LIBSCRIPT_ROOT_DIR!\cache\!filename!)"
                copy /y "!LIBSCRIPT_ROOT_DIR!\cache\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        )
)

if "!download_needed!"=="1" (
        if "%LIBSCRIPT_OFFLINE%"=="1" (
                call "!LOG_CMD!" :log_error "Error: [OFFLINE] Cannot download '!url!'. Artifact not found in local cache at '!cache_file!'."
                echo Error: [OFFLINE] Cannot download '!url!'. Artifact not found in local cache at '!cache_file!'. >&2
                if "%LIBSCRIPT_FORCE_OFFLINE%"=="1" (
                        echo Fatal: LIBSCRIPT_FORCE_OFFLINE=1 strictly prohibits network requests. >&2
                        exit /b 1
                )
                exit /b 1
        )
        if "%LIBSCRIPT_FORCE_OFFLINE%"=="1" (
                call "!LOG_CMD!" :log_error "Fatal: LIBSCRIPT_FORCE_OFFLINE=1 strictly prohibits network requests."
                echo Fatal: LIBSCRIPT_FORCE_OFFLINE=1 strictly prohibits network requests. >&2
                exit /b 1
        )

        call "!LOG_CMD!" :log_info "[DOWNLOADING] !url!"
    
        set "download_success=0"
    
        REM Strategy A: curl
        where curl >nul 2>&1
        if !errorlevel! equ 0 (
                if not "!auth_header!"=="" (
                        curl -L -H "!auth_header!" "!url!" -o "!cache_file!"
                ) else (
                        curl -L "!url!" -o "!cache_file!"
                )
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
                call "!LOG_CMD!" :log_error "Download failed for !url!"
                exit /b 1
        )
    
        for %%A in ("!cache_file!") do set size=%%~zA
        if "!size!"=="0" (
                call "!LOG_CMD!" :log_error "Downloaded file is empty"
                del "!cache_file!"
                exit /b 1
        )
)

:: 5. Checksum Validation
if not "!expected_checksum!"=="" (
        if /i not "!expected_checksum!"=="SKIP" (
                set "clean_expected=!expected_checksum:sha-256=!"
                set "actual_checksum="
                for /f "skip=1 tokens=1" %%a in ('certutil -hashfile "!cache_file!" SHA256 2^>nul') do if not defined actual_checksum set "actual_checksum=%%a"
                if "!actual_checksum!"=="" (
                        for /f "usebackq tokens=*" %%a in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[System.IO.File]::OpenRead('!cache_file!');$h=[System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($s)).Replace('-','').ToLower();$s.Close();$h" 2^>nul`) do set "actual_checksum=%%a"
                )
                if /i not "!actual_checksum!"=="!clean_expected!" (
                        call "!LOG_CMD!" :log_error "Checksum mismatch for !cache_file!. Expected: !clean_expected!, Got: !actual_checksum!"
                        del "!cache_file!"
                        exit /b 1
                )
        )
) else (
        if not "%LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB%"=="1" (
                set "actual_checksum="
                for /f "skip=1 tokens=1" %%a in ('certutil -hashfile "!cache_file!" SHA256 2^>nul') do if not defined actual_checksum set "actual_checksum=%%a"
                if "!actual_checksum!"=="" (
                        for /f "usebackq tokens=*" %%a in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[System.IO.File]::OpenRead('!cache_file!');$h=[System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($s)).Replace('-','').ToLower();$s.Close();$h" 2^>nul`) do set "actual_checksum=%%a"
                )
                if not "!actual_checksum!"=="" (
                        findstr /i /c:"!url! !actual_checksum!" "!checksum_db!" >nul 2>&1 || echo !url! !actual_checksum!>> "!checksum_db!"
                )
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
:: Performs the libscript_fetch operation and updates component state.
:libscript_fetch
call :libscript_download %*
exit /b %errorlevel%

:: ## libscript_fetch_stdout
:: Fetches the contents of a URL to stdout while respecting offline mode and curl/powershell fallbacks.
:libscript_fetch_stdout
set "_lfs_url=%~1"
if "!_lfs_url!"=="" exit /b 1
if "%LIBSCRIPT_OFFLINE%"=="1" exit /b 1
if "%LIBSCRIPT_FORCE_OFFLINE%"=="1" exit /b 1
where curl >nul 2>&1
if !errorlevel! equ 0 (
    curl -fsSL "!_lfs_url!" 2>nul
    exit /b !errorlevel!
)
set "_lfs_tmp=%TEMP%\libscript_fetch_%RANDOM%.tmp"
call :libscript_download "!_lfs_url!" "!_lfs_tmp!" "SKIP" >nul 2>&1
if exist "!_lfs_tmp!" (
    type "!_lfs_tmp!"
    del /f /q "!_lfs_tmp!" >nul 2>&1
    exit /b 0
)
exit /b 1

:: ## libscript_resolve_github_tag
:: Resolves the latest release tag_name from a GitHub API releases/latest URL, stripping any leading 'v'.
:libscript_resolve_github_tag
set "_lrgt_url=%~1"
if "!_lrgt_url!"=="" exit /b 1
if "%LIBSCRIPT_OFFLINE%"=="1" exit /b 1
if "%LIBSCRIPT_FORCE_OFFLINE%"=="1" exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (Invoke-RestMethod -Uri '!_lrgt_url!').tag_name -replace '^v',''" 2>nul
exit /b !errorlevel!

:: ## libscript_uninstall_pkg
:: Uninstalls a package using the active Windows package manager (winget, choco, scoop).
:libscript_uninstall_pkg
set "_un_pkg=%~1"
if "!_un_pkg!"=="" exit /b 0
if not defined PKG_MGR call :detect_pkg_mgr
if /i "!PKG_MGR!"=="winget" (
    where winget >nul 2>&1 && winget uninstall --id "!_un_pkg!" --silent --accept-source-agreements >nul 2>&1
)
if /i "!PKG_MGR!"=="choco" (
    where choco >nul 2>&1 && choco uninstall "!_un_pkg!" -y >nul 2>&1
)
if /i "!PKG_MGR!"=="scoop" (
    where scoop >nul 2>&1 && scoop uninstall "!_un_pkg!" >nul 2>&1
)
exit /b 0
