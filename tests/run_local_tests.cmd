@echo off
:: # run_local_tests.cmd
::
:: ## Overview
:: Runs local tests using Vagrant across all toolchains, languages, databases, and DOS targets
:: (including msdos-1.25, msdos-2.0, msdos-4.0, freedos-1.3, and freedos-1.4 via Bento COM1).
::
:: ## Usage
:: tests\run_local_tests.cmd [TARGETS...|all] [--os OS_NAME] [--reuse-vm] [--boot-only]

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

set "OS_TARGET=alpine-3.24"
set "REUSE_VM=0"
set "BOOT_ONLY=0"
set "COMPONENT_VERSION=latest"
set "PKG_MGR="
set "INSTALL_METHOD="
set "TOOLCHAIN="
set "SNAPSHOT_NAME=vanilla"
set "IDEMPOTENCY_RUNS=2"
set "ARGS="
goto :parse_args

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
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
if /I "%~1"=="--target-os" (
    set "OS_TARGET=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--component" (
    set "ARGS=!ARGS! %~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--components" (
    set "ARGS=!ARGS! %~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--version" (
    set "COMPONENT_VERSION=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--component-version" (
    set "COMPONENT_VERSION=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--pkg-mgr" (
    set "PKG_MGR=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--package-manager" (
    set "PKG_MGR=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--install-method" (
    set "INSTALL_METHOD=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--from-source" (
    set "INSTALL_METHOD=from-source"
    shift
    goto :parse_args
)
if /I "%~1"=="--toolchain" (
    set "TOOLCHAIN=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--snapshot" (
    set "SNAPSHOT_NAME=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--idempotency-runs" (
    set "IDEMPOTENCY_RUNS=%~2"
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
if /I "%~1"=="--boot-only" (
    set "BOOT_ONLY=1"
    set "REUSE_VM=1"
    shift
    goto :parse_args
)
set "ARGS=!ARGS! %1"
shift
goto :parse_args

:: ## done_args
:: Continues execution after command-line argument parsing completes.
:done_args

set "THIS_DIR=%SCRIPT_DIR%"
set "REPO_ROOT=%LIBSCRIPT_ROOT_DIR%"
set "TESTS_TMP_DIR=%REPO_ROOT%\tests_tmp"

if not exist "%TESTS_TMP_DIR%" mkdir "%TESTS_TMP_DIR%"

if "!ARGS!"=="" set "ARGS=databases caches languages toolchains"

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
    ) else if exist "%REPO_ROOT%\topologies\%%A\*" (
        set "TARGETS=!TARGETS! %%A"
    ) else if exist "%REPO_ROOT%\payloads\%%A\*" (
        for /d %%D in ("%REPO_ROOT%\payloads\%%A\*") do (
            set "TARGETS=!TARGETS! %%~nxD"
        )
    ) else (
        set "FOUND=0"
        for /d %%C in ("%REPO_ROOT%\_lib\*" "%REPO_ROOT%\topologies" "%REPO_ROOT%\payloads\*") do (
            if exist "%%C\%%A\*" (
                set "TARGETS=!TARGETS! %%A"
                set "FOUND=1"
            )
        )
        if "!FOUND!"=="0" echo Warning: Target '%%A' not found.
    )
)

for /f "tokens=1 delims=-" %%I in ("!OS_TARGET!") do set "OS_ID=%%I"
set "OS_TAG=!OS_ID!"
set "OS_FAMILY="
if /I "!OS_ID!"=="alpine" ( set "OS_TAG=linux.alpine" & set "OS_FAMILY=linux" )
if /I "!OS_ID!"=="debian" ( set "OS_TAG=linux.debian" & set "OS_FAMILY=linux" )
if /I "!OS_ID!"=="rhel" ( set "OS_TAG=linux.rhel" & set "OS_FAMILY=linux" )
if /I "!OS_ID!"=="almalinux" ( set "OS_TAG=linux.rhel" & set "OS_FAMILY=linux" )
if /I "!OS_ID!"=="rocky" ( set "OS_TAG=linux.rhel" & set "OS_FAMILY=linux" )
if /I "!OS_ID!"=="rockylinux" ( set "OS_TAG=linux.rhel" & set "OS_FAMILY=linux" )
if /I "!OS_ID!"=="freebsd" ( set "OS_TAG=freebsd" & set "OS_FAMILY=bsd" )
if /I "!OS_ID!"=="windows" ( set "OS_TAG=windows" & set "OS_FAMILY=windows" )
if /I "!OS_ID!"=="msdos" ( set "OS_TAG=msdos" & set "OS_FAMILY=dos" )
if /I "!OS_ID!"=="freedos" ( set "OS_TAG=msdos" & set "OS_FAMILY=dos" )
if /I "!OS_ID!"=="omnios" ( set "OS_TAG=sunos" & set "OS_FAMILY=sunos" )
if /I "!OS_ID!"=="sunos" ( set "OS_TAG=sunos" & set "OS_FAMILY=sunos" )
if /I "!OS_ID!"=="solaris" ( set "OS_TAG=sunos" & set "OS_FAMILY=sunos" )
if /I "!OS_ID!"=="illumos" ( set "OS_TAG=sunos" & set "OS_FAMILY=sunos" )
if /I "!OS_ID!"=="macos" ( set "OS_TAG=darwin" & set "OS_FAMILY=darwin" )
if /I "!OS_ID!"=="darwin" ( set "OS_TAG=darwin" & set "OS_FAMILY=darwin" )

if /I "!OS_FAMILY!"=="dos" (
    if "!BENTO_DIR!"=="" set "BENTO_DIR=%REPO_ROOT%\..\bento"
    if exist "!BENTO_DIR!\lib\" (
        for %%D in ("!BENTO_DIR!") do set "BENTO_DIR=%%~fD"
        echo ;!RUBYLIB!; | findstr /I /C:";!BENTO_DIR!\lib;" >nul 2>&1
        if errorlevel 1 (
            if "!RUBYLIB!"=="" ( set "RUBYLIB=!BENTO_DIR!\lib" ) else ( set "RUBYLIB=!BENTO_DIR!\lib;!RUBYLIB!" )
        )
    )
)

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
        ) else if /I "!OS_ID!"=="omnios" (
            vagrant ssh --no-tty -c "sudo pkg install --accept network/rsync developer/versioning/git" >nul 2>&1
        )
    )
    if /I not "!OS_FAMILY!"=="dos" (
        echo === Syncing LibScript repository to !OS_TARGET! ===
        vagrant rsync
    )
    if "!BOOT_ONLY!"=="1" (
        echo Boot-only check succeeded for !OS_TARGET!.
        exit /b 0
    )
)

for %%T in (!TARGETS!) do (
    set "TARGET_NAME=%%T"
    echo ============================================================
    echo Running test for !TARGET_NAME! on !OS_TARGET!...
    echo ============================================================

    set "STDOUT_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.!OS_TAG!.stdout"
    set "STDERR_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.!OS_TAG!.stderr"
    set "SUCCESS_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.!OS_TAG!.success"
    set "FAILURE_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.!OS_TAG!.failure"
    set "IDEMP_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.idempotent.success"

    if exist "!SUCCESS_FILE!" del /f "!SUCCESS_FILE!"
    if exist "!FAILURE_FILE!" del /f "!FAILURE_FILE!"

    if "!REUSE_VM!"=="1" (
        cd /d "%REPO_ROOT%\vagrant\!OS_TARGET!"
        if not "!SNAPSHOT_NAME!"=="" (
            vagrant snapshot restore "!SNAPSHOT_NAME!" --no-provision >nul 2>&1
        )
        if /I "!OS_FAMILY!"=="dos" (
            set "_DOS_STAGE=%REPO_ROOT%\vagrant\!OS_TARGET!\LIBSCRIP"
            set "_DOS_BAT=%REPO_ROOT%\vagrant\!OS_TARGET!\DOSVERF.BAT"
            if exist "!_DOS_STAGE!" rmdir /s /q "!_DOS_STAGE!" >nul 2>&1
            if exist "!_DOS_BAT!" del /f /q "!_DOS_BAT!" >nul 2>&1
            set "_DOS_OK=1"
            for /L %%P in (1,1,!IDEMPOTENCY_RUNS!) do (
                if "!_DOS_OK!"=="1" (
                    set "LIBSCRIPT_TARGET_OS=msdos"
                    set "LIBSCRIPT_DOS_83=1"
                    set "LIBSCRIPT_HOME=!_DOS_STAGE!"
                    set "STACK="
                    call "%REPO_ROOT%\libscript.cmd" install "!TARGET_NAME!" "!COMPONENT_VERSION!" >> "!STDOUT_FILE!" 2>> "!STDERR_FILE!"
                    if errorlevel 1 set "_DOS_OK=0"
                )
            )
            if "!_DOS_OK!"=="1" (
                (
                    echo @ECHO OFF
                    echo VER
                    echo DIR D:\LIBSCRIP
                    echo ECHO [PASS] DOS_COMPONENT_VERIFIED !TARGET_NAME!
                ) > "!_DOS_BAT!"
                vagrant ssh -c "D:\DOSVERF.BAT" >> "!STDOUT_FILE!" 2>> "!STDERR_FILE!"
                if errorlevel 1 set "_DOS_OK=0"
            )
            if exist "!_DOS_STAGE!" rmdir /s /q "!_DOS_STAGE!" >nul 2>&1
            if exist "!_DOS_BAT!" del /f /q "!_DOS_BAT!" >nul 2>&1
            if "!_DOS_OK!"=="1" (
                echo Success > "!SUCCESS_FILE!"
                echo Success > "!IDEMP_FILE!"
                echo [OK] !TARGET_NAME! ^(!COMPONENT_VERSION!^)
            ) else (
                echo Failure > "!FAILURE_FILE!"
                echo [FAILED] !TARGET_NAME! ^(!COMPONENT_VERSION!^)
            )
        ) else if /I "!OS_ID!"=="windows" (
            vagrant ssh --no-tty -c "Set-Location C:\libscript; cmd.exe /c \"C:\libscript\libscript.cmd install !TARGET_NAME! !COMPONENT_VERSION!\" ; $iExit = $LASTEXITCODE; cmd.exe /c \"C:\libscript\libscript.cmd test !TARGET_NAME!\" ; $tExit = $LASTEXITCODE; if ($tExit -ne 0) { exit $tExit } elseif ($iExit -ne 0) { exit $iExit }" > "!STDOUT_FILE!" 2> "!STDERR_FILE!"
            if "!errorlevel!"=="0" (
                echo Success > "!SUCCESS_FILE!"
                echo [OK] !TARGET_NAME! ^(!COMPONENT_VERSION!^)
            ) else (
                echo Failure > "!FAILURE_FILE!"
                echo [FAILED] !TARGET_NAME! ^(!COMPONENT_VERSION!^)
            )
            vagrant ssh --no-tty -c "powershell -Command \"cd C:\libscript; cmd.exe /c C:\libscript\libscript.cmd uninstall !TARGET_NAME! *> $null; Remove-Item -Recurse -Force '$env:USERPROFILE\.libscript\!TARGET_NAME!' -ErrorAction SilentlyContinue\"" >nul 2>&1
        ) else (
            vagrant ssh --no-tty -c "export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a LIBSCRIPT_ROOT_DIR=/opt/repos/libscript LIBSCRIPT_PKG_MGR='!PKG_MGR!' LIBSCRIPT_GLOBAL_INSTALL_METHOD='!INSTALL_METHOD!' LIBSCRIPT_BUILD_TOOLCHAIN='!TOOLCHAIN!'; timeout 300 /opt/repos/libscript/libscript.sh install !TARGET_NAME! !COMPONENT_VERSION! && timeout 120 /opt/repos/libscript/libscript.sh test !TARGET_NAME!" > "!STDOUT_FILE!" 2> "!STDERR_FILE!"
            if "!errorlevel!"=="0" (
                echo Success > "!SUCCESS_FILE!"
                echo [OK] !TARGET_NAME! ^(!COMPONENT_VERSION!^)
            ) else (
                echo Failure > "!FAILURE_FILE!"
                echo [FAILED] !TARGET_NAME! ^(!COMPONENT_VERSION!^)
            )
            if "%REMOTE_TMPDIR%"=="" set "REMOTE_TMPDIR=/tmp"
            vagrant ssh --no-tty -c "export LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; /opt/repos/libscript/libscript.sh uninstall !TARGET_NAME! >/dev/null 2>&1 || true; rm -rf \"$HOME/.libscript/!TARGET_NAME!\" !REMOTE_TMPDIR!/libscript_pkg_mgr_lock 2>/dev/null || true" >nul 2>&1
        )
    ) else (
        set "LIBSCRIPT_TEST_TARGET=!TARGET_NAME!"
        set "LIBSCRIPT_REPO_ROOT=%REPO_ROOT%"
        set "RUN_DIR=%TESTS_TMP_DIR%\runs\!TARGET_NAME!-!OS_TARGET!"
        if not exist "!RUN_DIR!" mkdir "!RUN_DIR!"
        copy /Y "%REPO_ROOT%\vagrant\!OS_TARGET!\Vagrantfile" "!RUN_DIR!\Vagrantfile" >nul
        cd /d "!RUN_DIR!"
        vagrant destroy -f >nul 2>&1
        timeout /t 2 /nobreak >nul
        vagrant up > "!STDOUT_FILE!" 2> "!STDERR_FILE!"
        if "!errorlevel!" equ "0" (
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
echo Usage: %~nx0 [TARGETS...^|all] [--os OS_NAME] [--reuse-vm] [--boot-only] [--fast]
echo.
echo Runs local tests using Vagrant across specified categories or individual targets
echo to verify libscript installation, testing, and 2x idempotency.
endlocal
exit /b 0
