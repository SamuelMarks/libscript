@echo off
:: ## Overview
:: Runs local tests using Vagrant across all toolchains, languages, and databases
::
:: ## Usage
:: Run this script to verify libscript installation and testing on isolated Vagrant VMs.
:: Results are written to the tests_tmp directory.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "OS_TARGET=alpine-3.24"
set "REUSE_VM=0"
set "ARGS="

:: ## parse_args
:: Executes parse_args functionality.
:parse_args
if "%~1"=="" goto :done_args
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="--os" (
    set "OS_TARGET=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--reuse-vm" (
    set "REUSE_VM=1"
    shift
    goto :parse_args
)
if /I "%~1"=="--fast" (
    set "REUSE_VM=1"
    shift
    goto :parse_args
)
set "ARGS=!ARGS! %1"
shift
goto :parse_args

:: ## done_args
:: Executes done_args functionality.
:done_args

set "THIS_DIR=%~dp0"
:: Remove trailing slash
set "THIS_DIR=%THIS_DIR:~0,-1%"

set "REPO_ROOT=%THIS_DIR%\.."
set "TESTS_TMP_DIR=%REPO_ROOT%\tests_tmp"

if not exist "%TESTS_TMP_DIR%" mkdir "%TESTS_TMP_DIR%"

if "!ARGS!"=="" set "ARGS=databases languages toolchains"

if not exist "%REPO_ROOT%\vagrant\!OS_TARGET!\Vagrantfile" (
    echo Error: Vagrant environment '!OS_TARGET!' not found in %REPO_ROOT%\vagrant\
    exit /b 1
)

set "TARGETS="
for %%A in (!ARGS!) do (
    if /I "%%A"=="all" (
        for /d %%C in ("%REPO_ROOT%\_lib\*") do (
            if /I not "%%~nxC"=="_common" (
                for /d %%D in ("%%C\*") do (
                    set "TARGETS=!TARGETS! %%~nxD"
                )
            )
        )
    ) else if exist "%REPO_ROOT%\_lib\%%A\*" (
        for /d %%D in ("%REPO_ROOT%\_lib\%%A\*") do (
            set "TARGETS=!TARGETS! %%~nxD"
        )
    ) else (
        set "FOUND=0"
        for /d %%C in ("%REPO_ROOT%\_lib\*") do (
            if exist "%%C\%%A\*" (
                set "TARGETS=!TARGETS! %%A"
                set "FOUND=1"
            )
        )
        if "!FOUND!"=="0" echo Warning: Target '%%A' not found.
    )
)

:: Extract OS_ID for log naming (e.g. alpine from alpine-3.24)
for /f "tokens=1 delims=-" %%I in ("!OS_TARGET!") do set "OS_ID=%%I"
set "OS_TAG=!OS_ID!"
if /I "!OS_ID!"=="alpine" set "OS_TAG=linux.alpine"
if /I "!OS_ID!"=="debian" set "OS_TAG=linux.debian"
if /I "!OS_ID!"=="rhel" set "OS_TAG=linux.rhel"
if /I "!OS_ID!"=="almalinux" set "OS_TAG=linux.rhel"
if /I "!OS_ID!"=="rocky" set "OS_TAG=linux.rhel"
if /I "!OS_ID!"=="rockylinux" set "OS_TAG=linux.rhel"
if /I "!OS_ID!"=="freebsd" set "OS_TAG=freebsd"
if /I "!OS_ID!"=="windows" set "OS_TAG=windows"

if "!REUSE_VM!"=="1" (
    echo === Ensuring !OS_TARGET! Vagrant VM is running ===
    cd /d "%REPO_ROOT%\vagrant\!OS_TARGET!"
    vagrant status 2>&1 | findstr /i "running" >nul
    if errorlevel 1 (
        echo Starting !OS_TARGET! Vagrant VM...
        vagrant up --no-provision
        if /I "!OS_ID!"=="debian" (
            vagrant ssh --no-tty -c "sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq -y apt-utils curl jq rsync" >nul 2>&1
        ) else if /I "!OS_ID!"=="rocky" (
            vagrant ssh --no-tty -c "sudo dnf install -y -q curl jq rsync findutils which" >nul 2>&1
        ) else if /I "!OS_ID!"=="rockylinux" (
            vagrant ssh --no-tty -c "sudo dnf install -y -q curl jq rsync findutils which" >nul 2>&1
        ) else if /I "!OS_ID!"=="rhel" (
            vagrant ssh --no-tty -c "sudo dnf install -y -q curl jq rsync findutils which" >nul 2>&1
        ) else if /I "!OS_ID!"=="almalinux" (
            vagrant ssh --no-tty -c "sudo dnf install -y -q curl jq rsync findutils which" >nul 2>&1
        )
    )
    echo === Syncing LibScript repository to !OS_TARGET! ===
    vagrant rsync
)

:: Enumerate targets and test them
for %%T in (!TARGETS!) do (
    set "TARGET_NAME=%%T"
    
    echo ============================================================
    echo Running test for !TARGET_NAME! on !OS_TARGET!...
    echo ============================================================
        
    set "STDOUT_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.!OS_TAG!.stdout"
    set "STDERR_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.!OS_TAG!.stderr"
    set "SUCCESS_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.!OS_TAG!.success"
    set "FAILURE_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.!OS_TAG!.failure"
    
    if exist "!SUCCESS_FILE!" del /f "!SUCCESS_FILE!"
    if exist "!FAILURE_FILE!" del /f "!FAILURE_FILE!"

    if "!REUSE_VM!"=="1" (
        cd /d "%REPO_ROOT%\vagrant\!OS_TARGET!"
        if /I "!OS_ID!"=="windows" (
            vagrant ssh --no-tty -c "Set-Location C:\libscript; cmd.exe /c \"C:\libscript\libscript.cmd install !TARGET_NAME!\" ; $iExit = $LASTEXITCODE; cmd.exe /c \"C:\libscript\libscript.cmd test !TARGET_NAME!\" ; $tExit = $LASTEXITCODE; if ($tExit -ne 0) { exit $tExit } elseif ($iExit -ne 0) { exit $iExit }" > "!STDOUT_FILE!" 2> "!STDERR_FILE!"
            if !errorlevel! equ 0 (
                echo Success > "!SUCCESS_FILE!"
                echo [OK] !TARGET_NAME!
            ) else (
                echo Failure > "!FAILURE_FILE!"
                echo [FAILED] !TARGET_NAME!
            )
            vagrant ssh --no-tty -c "powershell -Command \"cd C:\libscript; & C:\libscript\libscript.cmd uninstall !TARGET_NAME! *>&1 | Out-Null; Remove-Item -Recurse -Force \"\"\"$env:USERPROFILE\.libscript\!TARGET_NAME!\"\"\" -ErrorAction SilentlyContinue\"" >nul 2>&1
        ) else (
            vagrant ssh --no-tty -c "export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; timeout 300 /opt/repos/libscript/libscript.sh install !TARGET_NAME! && timeout 120 /opt/repos/libscript/libscript.sh test !TARGET_NAME!" > "!STDOUT_FILE!" 2> "!STDERR_FILE!"
            if !errorlevel! equ 0 (
                echo Success > "!SUCCESS_FILE!"
                echo [OK] !TARGET_NAME!
            ) else (
                echo Failure > "!FAILURE_FILE!"
                echo [FAILED] !TARGET_NAME!
            )
            vagrant ssh --no-tty -c "export LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; /opt/repos/libscript/libscript.sh uninstall !TARGET_NAME! >/dev/null 2>&1 || true; rm -rf \"$HOME/.libscript/!TARGET_NAME!\" /tmp/libscript_pkg_mgr_lock 2>/dev/null || true" >nul 2>&1
        )
    ) else (
        set "LIBSCRIPT_TEST_TARGET=!TARGET_NAME!"
        set "LIBSCRIPT_REPO_ROOT=%REPO_ROOT%"
        
        :: Create an isolated environment for this run
        set "RUN_DIR=%TESTS_TMP_DIR%\runs\!TARGET_NAME!-!OS_TARGET!"
        if not exist "!RUN_DIR!" mkdir "!RUN_DIR!"
        copy /Y "%REPO_ROOT%\vagrant\!OS_TARGET!\Vagrantfile" "!RUN_DIR!\Vagrantfile" >nul
        
        cd /d "!RUN_DIR!"
        
        :: Ensure clean state (in case of previous aborted runs in this dir)
        vagrant destroy -f >nul 2>&1
        timeout /t 2 /nobreak >nul
        
        vagrant up > "!STDOUT_FILE!" 2> "!STDERR_FILE!"
        if !errorlevel! equ 0 (
            echo Success > "!SUCCESS_FILE!"
            echo [OK] !TARGET_NAME!
        ) else (
            echo Failure > "!FAILURE_FILE!"
            echo [FAILED] !TARGET_NAME!
        )
        
        vagrant destroy -f >nul 2>&1
        timeout /t 2 /nobreak >nul
    )

    if exist "%THIS_DIR%\update_results.cmd" (
        call "%THIS_DIR%\update_results.cmd"
    )
)

echo All tests complete. Results are in %TESTS_TMP_DIR%.
goto :eof

:: ## show_help
:: Displays command-line help and options.
:show_help
echo Usage: %~nx0 [TARGETS...^|all] [--os OS_NAME] [--reuse-vm] [--fast]
echo.
echo Runs local tests using Vagrant across specified categories or individual targets
echo to verify libscript installation and testing.
echo.
echo Arguments:
echo   TARGETS...     A list of categories (e.g., databases, languages) or specific targets.
echo                  If no arguments are provided, defaults to: databases languages toolchains
echo   all            Run tests across all categories in the _lib directory.
echo   --os OS_NAME   The OS environment to use from the vagrant/ folder (default: alpine-3.24).
echo                  Example: --os debian-13
echo   --reuse-vm     Reuse a running VM instead of creating/destroying a new VM per target.
echo   --fast         Alias for --reuse-vm.
echo   --help, -h, /? Show this help message.
echo.
echo Results are written to the tests_tmp directory.
endlocal
