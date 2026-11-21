@echo off
:: # test_win_dos_component_pm.cmd
:: ## Overview
:: End-to-end verification on Windows of the 6 Windows native & MS-DOS component-level package managers
:: (`jq`, `gawk`, `busybox`, `toybox`, `dash`, `freebsd-usr-bin`) and target-aware `depends` routing.
::
:: ## Usage
:: tests\test_win_dos_component_pm.cmd
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

set "TEST_WORK=%TEMP%\ls_win_dos_pm_%RANDOM%"
if not exist "!TEST_WORK!\downloads\jq" mkdir "!TEST_WORK!\downloads\jq"
if not exist "!TEST_WORK!\downloads\busybox" mkdir "!TEST_WORK!\downloads\busybox"

echo MSDOS-DOS32-JQ-1.8.2> "!TEST_WORK!\downloads\jq\jq-1.8.2-dos32.exe"
echo WIN32-PE-X64-JQ-1.8.2> "!TEST_WORK!\downloads\jq\jq-1.8.2-X64.exe"
echo WIN32-PE-X64-BUSYBOX-1.39.0> "!TEST_WORK!\downloads\busybox\busybox-1.39.0-X64.exe"

set "DOWNLOAD_DIR=!TEST_WORK!\downloads"
set "LIBSCRIPT_OFFLINE=1"

:: 1. Verify MS-DOS target gets dos32 jq.exe
set "LIBSCRIPT_TARGET_OS=msdos"
set "LIBSCRIPT_HOME=!TEST_WORK!\dos_home"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" depends jq
if errorlevel 1 (
    echo [FAIL] MS-DOS depends jq failed 1>&2
    rmdir /s /q "!TEST_WORK!" 2>nul
    exit /b 1
)
findstr /C:"MSDOS-DOS32-JQ-1.8.2" "!TEST_WORK!\dos_home\jq\default\bin\jq.exe" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] MS-DOS depends jq payload mismatch 1>&2
    rmdir /s /q "!TEST_WORK!" 2>nul
    exit /b 1
)

:: 2. Verify Windows target gets Windows PE X64 jq.exe and busybox.exe
set "LIBSCRIPT_TARGET_OS=windows"
set "LIBSCRIPT_TARGET_ARCH=x86_64"
set "LIBSCRIPT_HOME=!TEST_WORK!\win_home"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" depends jq busybox
if errorlevel 1 (
    echo [FAIL] Windows depends jq busybox failed 1>&2
    rmdir /s /q "!TEST_WORK!" 2>nul
    exit /b 1
)
findstr /C:"WIN32-PE-X64-JQ-1.8.2" "!TEST_WORK!\win_home\jq\default\bin\jq.exe" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Windows depends jq payload mismatch 1>&2
    rmdir /s /q "!TEST_WORK!" 2>nul
    exit /b 1
)
findstr /C:"WIN32-PE-X64-BUSYBOX-1.39.0" "!TEST_WORK!\win_home\busybox\default\bin\busybox.exe" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Windows depends busybox payload mismatch 1>&2
    rmdir /s /q "!TEST_WORK!" 2>nul
    exit /b 1
)

:: 3. Verify win-cmd-rs nested-directory zip extraction (FOR /R + pushd regression) and 2x idempotency
set "_WCR_STAGE=!TEST_WORK!\wcr_stage\win-cmd-rs-v0.0.1-x86_64-pc-windows-msvc"
if not exist "!_WCR_STAGE!" mkdir "!_WCR_STAGE!"
if not exist "!TEST_WORK!\downloads\win-cmd-rs" mkdir "!TEST_WORK!\downloads\win-cmd-rs"
echo WIN32-PE-X64-WINCHECK-0.0.1> "!_WCR_STAGE!\wincheck.exe"
echo WIN32-PE-X64-WINCMD-0.0.1> "!_WCR_STAGE!\wincmd.exe"
set "_WCR_ZIP_OK=!TEST_WORK!\downloads\win-cmd-rs\win-cmd-rs-v0.0.1-x86_64-pc-windows-msvc.zip"
call :pack_zip_dir "!TEST_WORK!\wcr_stage" "win-cmd-rs-v0.0.1-x86_64-pc-windows-msvc" "!_WCR_ZIP_OK!"
if exist "!_WCR_ZIP_OK!" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install win-cmd-rs 0.0.1
    if errorlevel 1 (
        echo [FAIL] Windows install win-cmd-rs 0.0.1 from nested zip failed 1>&2
        rmdir /s /q "!TEST_WORK!" 2>nul
        exit /b 1
    )
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install win-cmd-rs 0.0.1
    if errorlevel 1 (
        echo [FAIL] Second idempotent Windows install win-cmd-rs 0.0.1 failed 1>&2
        rmdir /s /q "!TEST_WORK!" 2>nul
        exit /b 1
    )
    findstr /C:"WIN32-PE-X64-WINCHECK-0.0.1" "!TEST_WORK!\win_home\win-cmd-rs\default\bin\wincheck.exe" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] Windows win-cmd-rs wincheck.exe payload mismatch 1>&2
        rmdir /s /q "!TEST_WORK!" 2>nul
        exit /b 1
    )
    findstr /C:"WIN32-PE-X64-WINCMD-0.0.1" "!TEST_WORK!\win_home\win-cmd-rs\default\bin\wincmd.exe" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] Windows win-cmd-rs wincmd.exe payload mismatch 1>&2
        rmdir /s /q "!TEST_WORK!" 2>nul
        exit /b 1
    )
)

:: 4. Verify failed native setup terminates cleanly without setup_base.cmd / pkg_mgr.cmd infinite recursion
set "_WCR_BAD=!TEST_WORK!\wcr_bad\win-cmd-rs-v9.9.9-x86_64-pc-windows-msvc"
if not exist "!_WCR_BAD!" mkdir "!_WCR_BAD!"
echo EMPTY-README> "!_WCR_BAD!\README.md"
set "_WCR_ZIP_BAD=!TEST_WORK!\downloads\win-cmd-rs\win-cmd-rs-v9.9.9-x86_64-pc-windows-msvc.zip"
call :pack_zip_dir "!TEST_WORK!\wcr_bad" "win-cmd-rs-v9.9.9-x86_64-pc-windows-msvc" "!_WCR_ZIP_BAD!"
if exist "!_WCR_ZIP_BAD!" (
    set "STACK="
    set "PKG_MGR=libscript"
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install win-cmd-rs 9.9.9 >nul 2>&1
    if not errorlevel 1 (
        echo [FAIL] Expected corrupt win-cmd-rs 9.9.9 archive without binaries to return non-zero 1>&2
        rmdir /s /q "!TEST_WORK!" 2>nul
        exit /b 1
    )
)

:: 5. Verify audit_standards.cmd catches BATCH_FOR_R_DELAYED and BATCH_QUOTED_DOUBLE_CARET_BANG in .cmd files (including under \tmp\ paths)
set "_HAS_STD_RUNNER=0"
for %%R in (pwsh.exe powershell.exe dash.exe sh.exe) do (
    where %%R >nul 2>&1
    if not errorlevel 1 set "_HAS_STD_RUNNER=1"
)
if "!_HAS_STD_RUNNER!"=="1" (
    if not exist "!TEST_WORK!\tmp" mkdir "!TEST_WORK!\tmp"
    call :write_bad_for_r_fixture "!TEST_WORK!\bad_for_r"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_standards.cmd" "!TEST_WORK!\bad_for_r.cmd" > "!TEST_WORK!\std_out_1.txt" 2>&1
    findstr /C:"BATCH_FOR_R_DELAYED" "!TEST_WORK!\std_out_1.txt" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] audit_standards.cmd did not report BATCH_FOR_R_DELAYED for bad_for_r.cmd 1>&2
        type "!TEST_WORK!\std_out_1.txt" 1>&2
        rmdir /s /q "!TEST_WORK!" 2>nul
        exit /b 1
    )
    findstr /C:"1 standards violation(s) found." "!TEST_WORK!\std_out_1.txt" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] Expected exactly 1 standards violation for bad_for_r.cmd 1>&2
        type "!TEST_WORK!\std_out_1.txt" 1>&2
        rmdir /s /q "!TEST_WORK!" 2>nul
        exit /b 1
    )
    call :write_bad_for_r_fixture "!TEST_WORK!\tmp\bad_for_r"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_standards.cmd" "!TEST_WORK!\tmp\bad_for_r.cmd" > "!TEST_WORK!\std_out_2.txt" 2>&1
    findstr /C:"BATCH_FOR_R_DELAYED" "!TEST_WORK!\std_out_2.txt" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] audit_standards.cmd did not report BATCH_FOR_R_DELAYED for tmp\bad_for_r.cmd 1>&2
        type "!TEST_WORK!\std_out_2.txt" 1>&2
        rmdir /s /q "!TEST_WORK!" 2>nul
        exit /b 1
    )
    findstr /C:"1 standards violation(s) found." "!TEST_WORK!\std_out_2.txt" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] Expected exactly 1 standards violation for tmp\bad_for_r.cmd 1>&2
        type "!TEST_WORK!\std_out_2.txt" 1>&2
        rmdir /s /q "!TEST_WORK!" 2>nul
        exit /b 1
    )
    call :write_bad_quoted_bang_fixture "!TEST_WORK!\tmp\bad_quoted_bang"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_standards.cmd" "!TEST_WORK!\tmp\bad_quoted_bang.cmd" > "!TEST_WORK!\std_out_3.txt" 2>&1
    findstr /C:"BATCH_QUOTED_DOUBLE_CARET_BANG" "!TEST_WORK!\std_out_3.txt" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] audit_standards.cmd did not report BATCH_QUOTED_DOUBLE_CARET_BANG for tmp\bad_quoted_bang.cmd 1>&2
        type "!TEST_WORK!\std_out_3.txt" 1>&2
        rmdir /s /q "!TEST_WORK!" 2>nul
        exit /b 1
    )
    findstr /C:"1 standards violation(s) found." "!TEST_WORK!\std_out_3.txt" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] Expected exactly 1 standards violation for tmp\bad_quoted_bang.cmd 1>&2
        type "!TEST_WORK!\std_out_3.txt" 1>&2
        rmdir /s /q "!TEST_WORK!" 2>nul
        exit /b 1
    )
)

rmdir /s /q "!TEST_WORK!" 2>nul
echo [PASS] Windows and MS-DOS component-level package manager routing verified.
exit /b 0

:: ## write_bad_for_r_fixture
:: Writes a .cmd/.sh fixture pair containing FOR /R with delayed expansion root path.
:write_bad_for_r_fixture
set "_WBF_SH=%~1.sh"
set "_WBF_CMD=%~1.cmd"
set "_FR_KW=for /r"
> "!_WBF_SH!" echo #^^!/bin/sh
>> "!_WBF_SH!" echo # ## Overview
>> "!_WBF_SH!" echo # Fixture companion script.
>> "!_WBF_SH!" echo # ## Usage
>> "!_WBF_SH!" echo # ./bad_for_r.sh
>> "!_WBF_SH!" echo exit 0
> "!_WBF_CMD!" echo @echo off
>> "!_WBF_CMD!" echo :: ## Overview
>> "!_WBF_CMD!" echo :: Fixture batch script.
>> "!_WBF_CMD!" echo :: ## Usage
>> "!_WBF_CMD!" echo :: bad_for_r.cmd
>> "!_WBF_CMD!" echo setlocal EnableDelayedExpansion
>> "!_WBF_CMD!" echo set "THIS_FILE=%%~f0"
>> "!_WBF_CMD!" echo if defined STACK (
>> "!_WBF_CMD!" echo     echo "^!STACK^!" ^| findstr /I /C:":^!THIS_FILE^!:" ^>nul 2^>^&1
>> "!_WBF_CMD!" echo     if not errorlevel 1 exit /b 0
>> "!_WBF_CMD!" echo )
>> "!_WBF_CMD!" echo set "STACK=%%STACK%%:^!THIS_FILE^!:"
>> "!_WBF_CMD!" echo !_FR_KW! "^!STAGE_DIR^!" %%%%X in (wincheck.exe) do echo %%%%X
>> "!_WBF_CMD!" echo exit /b 0
exit /b 0

:: ## write_bad_quoted_bang_fixture
:: Writes a .cmd/.sh fixture pair containing double-caret '^^!' inside double quotes under EnableDelayedExpansion.
:write_bad_quoted_bang_fixture
set "_WQB_SH=%~1.sh"
set "_WQB_CMD=%~1.cmd"
set "_DC=^^"
> "!_WQB_SH!" echo #^^!/bin/sh
>> "!_WQB_SH!" echo # ## Overview
>> "!_WQB_SH!" echo # Fixture companion script.
>> "!_WQB_SH!" echo # ## Usage
>> "!_WQB_SH!" echo # ./bad_quoted_bang.sh
>> "!_WQB_SH!" echo exit 0
> "!_WQB_CMD!" echo @echo off
>> "!_WQB_CMD!" echo :: ## Overview
>> "!_WQB_CMD!" echo :: Fixture batch script.
>> "!_WQB_CMD!" echo :: ## Usage
>> "!_WQB_CMD!" echo :: bad_quoted_bang.cmd
>> "!_WQB_CMD!" echo setlocal EnableDelayedExpansion
>> "!_WQB_CMD!" echo set "THIS_FILE=%%~f0"
>> "!_WQB_CMD!" echo if defined STACK (
>> "!_WQB_CMD!" echo     echo "^!STACK^!" ^| findstr /I /C:":^!THIS_FILE^!:" ^>nul 2^>^&1
>> "!_WQB_CMD!" echo     if not errorlevel 1 exit /b 0
>> "!_WQB_CMD!" echo )
>> "!_WQB_CMD!" echo set "STACK=%%STACK%%:^!THIS_FILE^!:"
>> "!_WQB_CMD!" echo echo "!_DC!^!STAGE_DIR!_DC!^!"
>> "!_WQB_CMD!" echo exit /b 0
exit /b 0

:: ## pack_zip_dir
:: Creates a zip archive containing a relative subdirectory using zero-PowerShell tools (tar, 7za, 7z, or zip).
:pack_zip_dir
set "_PZD_BASE=%~1"
set "_PZD_SUB=%~2"
set "_PZD_OUT=%~3"
for %%T in ("!_PZD_OUT!") do set "_PZD_OUT=%%~fT"
pushd "!_PZD_BASE!"
for %%C in (tar.exe tar) do (
    where %%C >nul 2>&1
    if not errorlevel 1 (
        %%C -a -cf "!_PZD_OUT!" "!_PZD_SUB!" >nul 2>&1
        if exist "!_PZD_OUT!" (
            popd
            exit /b 0
        )
    )
)
for %%Z in (7za.exe 7z.exe 7za 7z) do (
    where %%Z >nul 2>&1
    if not errorlevel 1 (
        %%Z a "!_PZD_OUT!" "!_PZD_SUB!" >nul 2>&1
        if exist "!_PZD_OUT!" (
            popd
            exit /b 0
        )
    )
)
for %%U in (zip.exe zip) do (
    where %%U >nul 2>&1
    if not errorlevel 1 (
        %%U -r -q "!_PZD_OUT!" "!_PZD_SUB!" >nul 2>&1
        if exist "!_PZD_OUT!" (
            popd
            exit /b 0
        )
    )
)
popd
exit /b 0
