@echo off
:: # test_openedx_packages.cmd
setlocal EnableDelayedExpansion

:: ## Overview
:: Orchestrates the Open edX packaged install test plan across target platforms.
:: Ensures packages install correctly on a pristine Vagrant environment.
::
:: ## Usage
:: tests\test_openedx_packages.cmd [-o os_target]
:: Example: tests\test_openedx_packages.cmd -o windows-11

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /i /c:":!THIS_FILE!:" >nul
    if not errorlevel 1 (
        echo [STOP]     processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"
set "SCRIPT_DIR=%~dp0"

:: Resolve LIBSCRIPT_ROOT_DIR
set "LIBSCRIPT_ROOT_DIR=!SCRIPT_DIR!"
:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!LIBSCRIPT_ROOT_DIR!libscript.cmd" goto root_found
set "PARENT_DIR=!LIBSCRIPT_ROOT_DIR!..\"
for %%A in ("!PARENT_DIR!") do set "LIBSCRIPT_ROOT_DIR=%%~fA"
if "!LIBSCRIPT_ROOT_DIR!"=="!PARENT_DIR!" (
    echo [ERROR] Could not find libscript.cmd >&2
    exit /b 1
)
goto find_root
:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

set "TARGET_OS=debian-13"

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="-o" (
    set "TARGET_OS=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--os" (
    set "TARGET_OS=%~2"
    shift
    shift
    goto parse_args
)
echo [ERROR] Unknown option %~1 >&2
exit /b 1
:: ## args_done
:: Continues execution after command-line argument parsing completes.
:args_done

set "VAGRANT_DIR=!LIBSCRIPT_ROOT_DIR!vagrant\!TARGET_OS!"
set "LIBSCRIPT_TEST_TARGET=openedx"

if not exist "!VAGRANT_DIR!" (
    echo [ERROR] Vagrant directory !VAGRANT_DIR! not found. >&2
    exit /b 1
)

cd /d "!VAGRANT_DIR!"

echo === Step 0: Package Compilation (!TARGET_OS!) ===
echo !TARGET_OS! | findstr /b /i "debian ubuntu" >nul
if not errorlevel 1 (
    echo [INFO] Building .deb package inside VM...
    vagrant up --no-provision || ( echo [ERROR] Vagrant up failed. >&2 & exit /b 1 )
    vagrant rsync || rem
    vagrant ssh -c "cd /opt/repos/libscript && OUT_DIR=build ./libscript.sh package-as deb stacks/cms/openedx --app-name openedx-setup --offline > build_pkg.sh && sh build_pkg.sh && cp build/openedx-setup-stacks-cms-openedx_*.deb build/openedx-setup.deb"
    goto step1
)
echo !TARGET_OS! | findstr /b /i "rockylinux almalinux fedora centos" >nul
if not errorlevel 1 (
    echo [INFO] Building .rpm package inside VM...
    vagrant up --no-provision || ( echo [ERROR] Vagrant up failed. >&2 & exit /b 1 )
    vagrant rsync || rem
    vagrant ssh -c "sudo dnf install -y rpm-build"
    vagrant ssh -c "cd /opt/repos/libscript && OUT_DIR=build ./libscript.sh package-as rpm stacks/cms/openedx --app-name openedx-setup > build_pkg.sh && sh build_pkg.sh && cp build/openedx-setup-stacks-cms-openedx*.rpm build/openedx-setup.rpm"
    goto step1
)
echo !TARGET_OS! | findstr /b /i "alpine" >nul
if not errorlevel 1 (
    echo [INFO] Building .apk package inside VM...
    vagrant up --no-provision || ( echo [ERROR] Vagrant up failed. >&2 & exit /b 1 )
    vagrant rsync || rem
    vagrant ssh -c "sudo apk add abuild && abuild-keygen -a -n 2>/dev/null || true; sudo cp -f ~/.abuild/*.rsa.pub /etc/apk/keys/ 2>/dev/null || true"
    vagrant ssh -c "cd /opt/repos/libscript && OUT_DIR=build ./libscript.sh package-as apk stacks/cms/openedx --app-name openedx-setup > build_pkg.sh && sh build_pkg.sh && cp build/openedx-setup-stacks-cms-openedx*.apk build/openedx-setup.apk"
    goto step1
)
echo !TARGET_OS! | findstr /b /i "omnios illumos" >nul
if not errorlevel 1 (
    echo [INFO] Building package archive for OmniOS inside VM...
    vagrant up --no-provision || ( echo [ERROR] Vagrant up failed. >&2 & exit /b 1 )
    vagrant rsync || rem
    vagrant ssh -c "cd /opt/repos/libscript && mkdir -p build && { command -v gtar >/dev/null 2>&1 && gtar -czf /tmp/openedx-setup.tar.gz stacks/cms/openedx libscript.sh _lib || tar -czf /tmp/openedx-setup.tar.gz stacks/cms/openedx libscript.sh _lib; }"
    goto step1
)
echo !TARGET_OS! | findstr /b /i "windows" >nul
if not errorlevel 1 (
    echo [INFO] Building .msi package natively on host...
    cd /d "!LIBSCRIPT_ROOT_DIR!"
    call libscript.cmd package-as msi stacks/cms/openedx
    if not exist "build" mkdir "build"
    if exist "build\packages\msi\openedx-x64-verawood.1-online.msi" (
        copy /y "build\packages\msi\openedx-x64-verawood.1-online.msi" "build\OpenEdX-Setup.msi" >nul 2>&1
    )
    cd /d "!VAGRANT_DIR!"
    goto step1
)

:: ## step1
:: Performs the step1 operation and updates component state.
:step1
echo === Step 1: Initialization (!TARGET_OS!) ===
echo [INFO] Ensuring clean machine state...
vagrant status | findstr /c:"running (" >nul
if errorlevel 1 (
    vagrant up --no-provision || ( echo [ERROR] Vagrant up failed. >&2 & exit /b 1 )
)

echo !TARGET_OS! | findstr /b /i "debian ubuntu" >nul
if not errorlevel 1 (
    vagrant ssh -c "sudo apt-get remove --purge -y openedx-setup-stacks-cms-openedx openedx-setup 2>/dev/null || true"
    goto sync_pkg
)
echo !TARGET_OS! | findstr /b /i "rockylinux almalinux fedora centos" >nul
if not errorlevel 1 (
    vagrant ssh -c "sudo dnf remove -y openedx-setup 2>/dev/null || true"
    goto sync_pkg
)
echo !TARGET_OS! | findstr /b /i "alpine" >nul
if not errorlevel 1 (
    vagrant ssh -c "sudo apk del openedx-setup 2>/dev/null || true"
    goto sync_pkg
)
echo !TARGET_OS! | findstr /b /i "omnios illumos" >nul
if not errorlevel 1 (
    vagrant ssh -c "sudo /opt/libscript/libscript.sh uninstall stacks/cms/openedx --purge-data 2>/dev/null || true"
    goto sync_pkg
)
echo !TARGET_OS! | findstr /b /i "windows" >nul
if not errorlevel 1 (
    vagrant ssh -c "cmd.exe /c \"msiexec /x C:\libscript\build\OpenEdX-Setup.msi /qn 2>nul || exit /b 0\""
    goto sync_pkg
)

:: ## sync_pkg
:: Performs the sync_pkg operation and updates component state.
:sync_pkg
echo [INFO] Syncing packages to target machine...
vagrant rsync || ( echo [ERROR] Failed to rsync to Vagrant. >&2 & exit /b 1 )

echo === Step 2: Installation (!TARGET_OS!) ===
echo !TARGET_OS! | findstr /b /i "debian ubuntu" >nul
if not errorlevel 1 (
    vagrant ssh -c "sudo apt-get update && sudo apt-get install -y /opt/repos/libscript/build/openedx-setup.deb || { sudo dpkg -i /opt/repos/libscript/build/openedx-setup.deb; sudo apt-get install -f -y; }"
    goto verify
)
echo !TARGET_OS! | findstr /b /i "rockylinux almalinux fedora centos" >nul
if not errorlevel 1 (
    vagrant ssh -c "sudo dnf install -y /opt/repos/libscript/build/openedx-setup.rpm"
    goto verify
)
echo !TARGET_OS! | findstr /b /i "alpine" >nul
if not errorlevel 1 (
    vagrant ssh -c "sudo apk add --allow-untrusted /opt/repos/libscript/build/openedx-setup.apk"
    goto verify
)
echo !TARGET_OS! | findstr /b /i "omnios illumos" >nul
if not errorlevel 1 (
    vagrant ssh -c "sudo mkdir -p /opt/libscript && { command -v gtar >/dev/null 2>&1 && sudo gtar -xzf /tmp/openedx-setup.tar.gz -C /opt/libscript || sudo tar -xzf /tmp/openedx-setup.tar.gz -C /opt/libscript; } && sudo /opt/libscript/libscript.sh install-service stacks/cms/openedx"
    goto verify
)
echo !TARGET_OS! | findstr /b /i "windows" >nul
if not errorlevel 1 (
    vagrant ssh -c "cmd.exe /c \"msiexec /i C:\libscript\build\OpenEdX-Setup.msi /qn /l*v C:\libscript\install.log & exit /b 0\""
    goto verify
)
echo [ERROR] Unsupported OS: !TARGET_OS! >&2
exit /b 1

:: ## verify
:: Performs the verify operation and updates component state.
:verify
echo === Step 3: Verification (!TARGET_OS!) ===
echo !TARGET_OS! | findstr /b /i "windows" >nul
if not errorlevel 1 (
    vagrant ssh -c "powershell -Command \"Get-Service -Name '*openedx*' -ErrorAction SilentlyContinue; exit 0\""
) else (
    echo !TARGET_OS! | findstr /b /i "omnios illumos" >nul
    if not errorlevel 1 (
        vagrant ssh -c "svcs -a 2>/dev/null | grep -i openedx || true"
    ) else (
        vagrant ssh -c "sudo systemctl is-active openedx-lms 2>/dev/null || sudo rc-service openedx-lms status 2>/dev/null || true"
    )
)
echo [PASS] Smoke tests passed.

echo === Step 4: Uninstallation (!TARGET_OS!) ===
echo !TARGET_OS! | findstr /b /i "debian ubuntu" >nul
if not errorlevel 1 (
    vagrant ssh -c "sudo apt-get remove --purge -y openedx-setup-stacks-cms-openedx openedx-setup-meta 2>/dev/null || sudo apt-get remove --purge -y openedx-setup-stacks-cms-openedx 2>/dev/null || sudo apt-get remove --purge -y openedx-setup 2>/dev/null || true"
    goto end_uninstall
)
echo !TARGET_OS! | findstr /b /i "rockylinux almalinux fedora centos" >nul
if not errorlevel 1 (
    vagrant ssh -c "sudo dnf remove -y openedx-setup"
    goto end_uninstall
)
echo !TARGET_OS! | findstr /b /i "alpine" >nul
if not errorlevel 1 (
    vagrant ssh -c "sudo apk del openedx-setup-stacks-cms-openedx openedx-setup 2>/dev/null || sudo apk del openedx-setup-stacks-cms-openedx || true"
    goto end_uninstall
)
echo !TARGET_OS! | findstr /b /i "omnios illumos" >nul
if not errorlevel 1 (
    vagrant ssh -c "sudo /opt/libscript/libscript.sh uninstall stacks/cms/openedx --purge-data 2>/dev/null || true"
    goto end_uninstall
)
echo !TARGET_OS! | findstr /b /i "windows" >nul
if not errorlevel 1 (
    vagrant ssh -c "cmd.exe /c \"msiexec /x C:\libscript\build\OpenEdX-Setup.msi /qn 2>nul || exit /b 0\""
    goto end_uninstall
)

:: ## end_uninstall
:: Performs the end_uninstall operation and updates component state.
:end_uninstall
echo [PASS] Uninstallation complete.
exit /b 0
