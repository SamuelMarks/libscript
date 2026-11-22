@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup module for Rust acting as an isolated side-by-side version manager
:: (`rustup` replacement) with cross-compilation target and component management.
::
:: ## Usage
:: Invoked via `libscript.cmd <install|use|ls|ls-remote|target-add|target-rm|target-ls|component-add|component-ls|uninstall> rust [version] [args...]`.
setlocal EnableDelayedExpansion
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

if "%ACTION%"=="" set "ACTION=install"
if "%RUST_VERSION%"=="" (
    if not "%VERSION%"=="" (
        set "RUST_VERSION=%VERSION%"
    ) else (
        set "RUST_VERSION=stable"
    )
)
if /i "%RUST_VERSION%"=="latest" set "RUST_VERSION=stable"

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"

if "%RUST_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "RUST_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "RUST_INSTALL_METHOD=libscript_native"
    )
)

set "RUST_HOST_TRIPLE=x86_64-pc-windows-msvc"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "RUST_HOST_TRIPLE=aarch64-pc-windows-msvc"

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="target-add" goto :action_target_add
if /i "%ACTION%"=="target-rm" goto :action_target_rm
if /i "%ACTION%"=="target-ls" goto :action_target_ls
if /i "%ACTION%"=="component-add" goto :action_component_add
if /i "%ACTION%"=="component-ls" goto :action_component_ls
if /i "%ACTION%"=="install" goto :action_install
if /i "%ACTION%"=="status" goto :action_generic
if /i "%ACTION%"=="health" goto :action_generic
if /i "%ACTION%"=="logs" goto :action_generic
if /i "%ACTION%"=="uninstall" goto :action_generic
echo [ERROR] Unsupported rust action: %ACTION% >&2
exit /b 1

:: ## action_ls
:: Lists locally installed Rust toolchains under LIBSCRIPT_HOME\rust.
:action_ls
if /i "%RUST_INSTALL_METHOD%"=="system" ( rustc --version 2>nul & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\rust" dir /b "%LIBSCRIPT_HOME%\rust"
exit /b 0

:: ## action_ls_remote
:: Lists available Rust channels and upstream semver release tags.
:action_ls_remote
if /i "%RUST_INSTALL_METHOD%"=="system" (
    echo System package manager does not support ls-remote directly here.
    exit /b 0
)
echo stable
echo beta
echo nightly
if "%LIBSCRIPT_OFFLINE%"=="1" (
    echo 1.85.0
    exit /b 0
)
if not "%RUST_RELEASES_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_fetch_stdout "%RUST_RELEASES_URL%"
    exit /b !errorlevel!
)
where git >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=2" %%T in ('git ls-remote --tags "https://github.com/rust-lang/rust.git" 2^>nul') do (
        set "_tag=%%T"
        set "_tag=!_tag:refs/tags/=!"
        echo.!_tag! | findstr /R "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul 2>&1
        if not errorlevel 1 echo.!_tag!
    )
)
exit /b 0

:: ## action_use
:: Activates the specified Rust toolchain version and updates LIBSCRIPT_HOME\bin shims.
:action_use
if /i "%RUST_INSTALL_METHOD%"=="system" (
    echo [ERROR] Cannot 'use' specific version with system package manager. >&2
    exit /b 1
)
set "TARGET_DIR=%LIBSCRIPT_HOME%\rust\%RUST_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    set "ACTION=install"
    call :action_install
    if errorlevel 1 exit /b 1
)
call "!LIBSCRIPT_ROOT_DIR!\engine\common\versioning.cmd" :libscript_symlink_alias "rust" "default" "%RUST_VERSION%"
echo Active rust toolchain set to %RUST_VERSION%.
exit /b 0

:: ## action_download
:: Downloads the standalone Rust toolchain archive into DOWNLOAD_DIR\rust.
:action_download
if not exist "%DOWNLOAD_DIR%\rust" mkdir "%DOWNLOAD_DIR%\rust"
set "_DL_URL=%RUST_DOWNLOAD_URL%"
if "!_DL_URL!"=="" set "_DL_URL=https://static.rust-lang.org/dist/rust-%RUST_VERSION%-%RUST_HOST_TRIPLE%.tar.gz"
set "_DL_DEST=%DOWNLOAD_DIR%\rust\rust-%RUST_VERSION%-%RUST_HOST_TRIPLE%.tar.gz"
if exist "!_DL_DEST!" (
    echo [REUSE] Rust archive already cached at !_DL_DEST!.
    exit /b 0
)
call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "!_DL_URL!" "!_DL_DEST!"
exit /b !errorlevel!

:: ## extract_rust_archive
:: Extracts a standalone Rust toolchain or sub-artifact archive into TARGET_DIR.
:extract_rust_archive
set "_ERA_ARC=%~1"
set "_ERA_DST=%~2"
if not exist "!_ERA_DST!\bin" mkdir "!_ERA_DST!\bin"
if not exist "!_ERA_DST!\lib\rustlib" mkdir "!_ERA_DST!\lib\rustlib"
set "_ERA_TMP=%TEMP%\rust_ext_%RANDOM%"
if not exist "!_ERA_TMP!" mkdir "!_ERA_TMP!"
tar -xf "!_ERA_ARC!" -C "!_ERA_TMP!"
set "_ERA_INNER=!_ERA_TMP!"
for /d %%S in ("!_ERA_TMP!\*") do set "_ERA_INNER=%%~fS"
if exist "!_ERA_INNER!\bin" xcopy /E /I /Y "!_ERA_INNER!\bin\*" "!_ERA_DST!\bin\" >nul 2>&1
if exist "!_ERA_INNER!\lib" xcopy /E /I /Y "!_ERA_INNER!\lib\*" "!_ERA_DST!\lib\" >nul 2>&1
for /d %%C in ("!_ERA_INNER!\rustc" "!_ERA_INNER!\cargo" "!_ERA_INNER!\rust-std-*" "!_ERA_INNER!\clippy*" "!_ERA_INNER!\rustfmt*") do (
    if exist "%%~fC\bin" xcopy /E /I /Y "%%~fC\bin\*" "!_ERA_DST!\bin\" >nul 2>&1
    if exist "%%~fC\lib" xcopy /E /I /Y "%%~fC\lib\*" "!_ERA_DST!\lib\" >nul 2>&1
)
rmdir /s /q "!_ERA_TMP!" >nul 2>&1
exit /b 0

:: ## action_target_add
:: Installs one or more cross-compilation targets into the selected Rust toolchain.
:action_target_add
set "TARGET_DIR=%LIBSCRIPT_HOME%\rust\%RUST_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo [ERROR] Rust toolchain %RUST_VERSION% is not installed at %TARGET_DIR%. >&2
    exit /b 1
)
:: wincheck disable=CMD3005
:: ## target_add_loop
:: Iterates positional target triples passed to target-add.
:target_add_loop
if "%~1"=="" goto :target_add_done
set "_T_ARG=%~1"
if not "!_T_ARG:~0,2!"=="--" if /i not "!_T_ARG!"=="target-add" if /i not "!_T_ARG!"=="rust" if /i not "!_T_ARG!"=="%RUST_VERSION%" (
    call :install_one_target "!_T_ARG!"
    if errorlevel 1 exit /b 1
)
shift
goto :target_add_loop

:: ## target_add_done
:: Completes target-add invocation.
:target_add_done
exit /b 0

:: ## install_one_target
:: Installs a single rust-std cross-compilation target archive idempotently.
:install_one_target
set "_IOT=%~1"
set "_IOT_DIR=%LIBSCRIPT_HOME%\rust\%RUST_VERSION%\lib\rustlib\!_IOT!"
if exist "!_IOT_DIR!\.libscript_target_stamp" (
    echo [REUSE] Rust target !_IOT! already installed for %RUST_VERSION%.
    exit /b 0
)
if not exist "%DOWNLOAD_DIR%\rust" mkdir "%DOWNLOAD_DIR%\rust"
set "_IOT_ARC=%DOWNLOAD_DIR%\rust\rust-std-%RUST_VERSION%-!_IOT!.tar.gz"
if not exist "!_IOT_ARC!" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "https://static.rust-lang.org/dist/rust-std-%RUST_VERSION%-!_IOT!.tar.gz" "!_IOT_ARC!"
    if errorlevel 1 exit /b 1
)
call :extract_rust_archive "!_IOT_ARC!" "%LIBSCRIPT_HOME%\rust\%RUST_VERSION%"
if not exist "!_IOT_DIR!" mkdir "!_IOT_DIR!"
echo.!_IOT!> "!_IOT_DIR!\.libscript_target_stamp"
exit /b 0

:: ## action_target_rm
:: Removes an installed cross-compilation target from the selected Rust toolchain.
:action_target_rm
goto :target_rm_loop
:: ## target_rm_loop
:: Iterates positional target triples passed to target-rm.
:target_rm_loop
if "%~1"=="" exit /b 0
set "_TRM=%~1"
if not "!_TRM:~0,2!"=="--" if /i not "!_TRM!"=="target-rm" if /i not "!_TRM!"=="rust" if /i not "!_TRM!"=="%RUST_VERSION%" (
    if exist "%LIBSCRIPT_HOME%\rust\%RUST_VERSION%\lib\rustlib\!_TRM!" (
        rmdir /s /q "%LIBSCRIPT_HOME%\rust\%RUST_VERSION%\lib\rustlib\!_TRM!" >nul 2>&1
    )
)
shift
goto :target_rm_loop

:: ## action_target_ls
:: Lists installed cross-compilation targets in the selected Rust toolchain.
:action_target_ls
if exist "%LIBSCRIPT_HOME%\rust\%RUST_VERSION%\lib\rustlib" (
    for /d %%T in ("%LIBSCRIPT_HOME%\rust\%RUST_VERSION%\lib\rustlib\*") do (
        if /i not "%%~nxT"=="src" if /i not "%%~nxT"=="etc" echo.%%~nxT
    )
)
exit /b 0

:: ## action_component_add
:: Installs optional toolchain sub-components (e.g. clippy, rustfmt) idempotently.
:action_component_add
goto :comp_add_loop
:: ## comp_add_loop
:: Iterates positional component names passed to component-add.
:comp_add_loop
if "%~1"=="" exit /b 0
set "_CA=%~1"
if not "!_CA:~0,2!"=="--" if /i not "!_CA!"=="component-add" if /i not "!_CA!"=="rust" if /i not "!_CA!"=="%RUST_VERSION%" (
    call :install_one_component "!_CA!"
    if errorlevel 1 exit /b 1
)
shift
goto :comp_add_loop

:: ## install_one_component
:: Installs a single optional Rust sub-component archive idempotently.
:install_one_component
set "_IOC=%~1"
set "_IOC_REG=%LIBSCRIPT_HOME%\rust\%RUST_VERSION%\.libscript_components"
if exist "!_IOC_REG!" (
    findstr /I /X /C:"!_IOC!" "!_IOC_REG!" >nul 2>&1
    if not errorlevel 1 (
        echo [REUSE] Rust component !_IOC! already installed for %RUST_VERSION%.
        exit /b 0
    )
)
if not exist "%DOWNLOAD_DIR%\rust" mkdir "%DOWNLOAD_DIR%\rust"
set "_IOC_ARC=%DOWNLOAD_DIR%\rust\!_IOC!-%RUST_VERSION%-%RUST_HOST_TRIPLE%.tar.gz"
if not exist "!_IOC_ARC!" if exist "%DOWNLOAD_DIR%\rust\!_IOC!-%RUST_VERSION%.tar.gz" set "_IOC_ARC=%DOWNLOAD_DIR%\rust\!_IOC!-%RUST_VERSION%.tar.gz"
if not exist "!_IOC_ARC!" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "https://static.rust-lang.org/dist/!_IOC!-%RUST_VERSION%-%RUST_HOST_TRIPLE%.tar.gz" "!_IOC_ARC!"
    if errorlevel 1 exit /b 1
)
call :extract_rust_archive "!_IOC_ARC!" "%LIBSCRIPT_HOME%\rust\%RUST_VERSION%"
echo.!_IOC!>> "!_IOC_REG!"
exit /b 0

:: ## action_component_ls
:: Lists installed optional Rust toolchain sub-components.
:action_component_ls
if exist "%LIBSCRIPT_HOME%\rust\%RUST_VERSION%\.libscript_components" (
    type "%LIBSCRIPT_HOME%\rust\%RUST_VERSION%\.libscript_components"
)
exit /b 0

:: ## action_install
:: Installs the requested Rust toolchain version into an isolated directory under LIBSCRIPT_HOME\rust.
:action_install
if /i "%RUST_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_depends rust
    exit /b !errorlevel!
)
set "TARGET_DIR=%LIBSCRIPT_HOME%\rust\%RUST_VERSION%"
set "_RUST_INSTALLED=0"
if exist "%TARGET_DIR%\bin\rustc.exe" (
    if not "%FORCE_REINSTALL%"=="1" set "_RUST_INSTALLED=1"
)
if "!_RUST_INSTALLED!"=="1" (
    echo [REUSE] rust %RUST_VERSION% is already installed at %TARGET_DIR%.
) else (
    if not exist "%DOWNLOAD_DIR%\rust" mkdir "%DOWNLOAD_DIR%\rust"
    set "_ARC=%DOWNLOAD_DIR%\rust\rust-%RUST_VERSION%-%RUST_HOST_TRIPLE%.tar.gz"
    if not exist "!_ARC!" if exist "%DOWNLOAD_DIR%\rust\rust-%RUST_VERSION%.tar.gz" set "_ARC=%DOWNLOAD_DIR%\rust\rust-%RUST_VERSION%.tar.gz"
    if not exist "!_ARC!" (
        set "_DL_URL=%RUST_DOWNLOAD_URL%"
        if "!_DL_URL!"=="" set "_DL_URL=https://static.rust-lang.org/dist/rust-%RUST_VERSION%-%RUST_HOST_TRIPLE%.tar.gz"
        call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "!_DL_URL!" "!_ARC!"
        if errorlevel 1 exit /b 1
    )
    call :extract_rust_archive "!_ARC!" "%TARGET_DIR%"
    if not exist "%TARGET_DIR%\cargo\bin" mkdir "%TARGET_DIR%\cargo\bin"
    if not exist "%TARGET_DIR%\rustup" mkdir "%TARGET_DIR%\rustup"
    if not exist "%TARGET_DIR%\lib\rustlib\%RUST_HOST_TRIPLE%" mkdir "%TARGET_DIR%\lib\rustlib\%RUST_HOST_TRIPLE%"
    echo.%RUST_HOST_TRIPLE%> "%TARGET_DIR%\lib\rustlib\%RUST_HOST_TRIPLE%\.libscript_target_stamp"
)

if not "%RUST_TARGETS%"=="" (
    for %%T in (%RUST_TARGETS:,= %) do call :install_one_target "%%T"
)
if not "%RUST_COMPONENTS%"=="" (
    for %%C in (%RUST_COMPONENTS:,= %) do call :install_one_component "%%C"
)

if "%LIBSCRIPT_AUTO_USE%"=="1" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\versioning.cmd" :libscript_symlink_alias "rust" "default" "%RUST_VERSION%"
) else if not exist "%LIBSCRIPT_HOME%\rust\default" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\versioning.cmd" :libscript_symlink_alias "rust" "default" "%RUST_VERSION%"
)
exit /b 0

:: ## action_generic
:: Delegates generic status/uninstall lifecycle actions to setup_base.cmd.
:action_generic
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\setup_base.cmd" :libscript_handle_generic_action "rust" "%ACTION%" "%RUST_VERSION%" "%RUST_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\rust\%RUST_VERSION%\\bin\\rustc.exe\"" "%LIBSCRIPT_HOME%\rust\%RUST_VERSION%"
exit /b !errorlevel!
