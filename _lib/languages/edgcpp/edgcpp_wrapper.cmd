@echo off
:: # edgcpp_wrapper.cmd
::
:: ## Overview
:: Compiler driver wrapper and telemetry shim for the EDG C/C++ Compiler Frontend (edgcpp) on Windows.
:: Invokes cpfe.exe for front-end validation and native codegen (--llvm-be or --gcc-be) and lowers/links
:: via the configured Windows backend compiler while recording JSONL telemetry.
::
:: ## Usage
:: edgcpp_wrapper.cmd [compiler_args...]

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

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

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

set "_req_flavor=%EDGCPP_FLAVOR%"
if "!_req_flavor!"=="" set "_req_flavor=edgcpp+llvm+gcc"
set "EDGCPP_ACTIVE_FLAVOR=!_req_flavor!"

set "_raw_be=%LLVM_BACKEND_OR_GCC_BACKEND%"
if "!_raw_be!"=="" set "_raw_be=%EDGCPP_BACKEND_MODE%"
if /i "%~n0"=="edgcpp-gcc-be" set "_raw_be=gcc_backend"
if /i "%~n0"=="edgcpp-llvm-be" set "_raw_be=llvm_backend"
if /i "!_raw_be!"=="gcc" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
) else if /i "!_raw_be!"=="gcc-be" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
) else if /i "!_raw_be!"=="gcc_backend" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
) else if /i "!EDGCPP_ACTIVE_FLAVOR!"=="edgcpp+gcc" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
) else (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=llvm_backend"
)

if "%~1"=="--version" (
    echo edgcpp 7.0.1 ^(EDG C/C++ Front End v7.0.1 wrapper; flavor=!EDGCPP_ACTIVE_FLAVOR!; codegen=!EDGCPP_ACTIVE_CODEGEN_BACKEND!^)
    exit /b 0
)
if "%~1"=="-v" (
    echo edgcpp 7.0.1 ^(EDG C/C++ Front End v7.0.1 wrapper; flavor=!EDGCPP_ACTIVE_FLAVOR!; codegen=!EDGCPP_ACTIVE_CODEGEN_BACKEND!^)
    exit /b 0
)
if "%~1"=="-dumpversion" (
    echo 7.0.1
    exit /b 0
)

call :extract_source_arg %*

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "_edg_home=%EDGCPP_HOME%"
if "!_edg_home!"=="" (
    if exist "%LIBSCRIPT_HOME%\edgcpp\!EDGCPP_ACTIVE_FLAVOR!" (
        set "_edg_home=%LIBSCRIPT_HOME%\edgcpp\!EDGCPP_ACTIVE_FLAVOR!"
    ) else if exist "%LIBSCRIPT_HOME%\edgcpp\7.0.1-!EDGCPP_ACTIVE_FLAVOR!" (
        set "_edg_home=%LIBSCRIPT_HOME%\edgcpp\7.0.1-!EDGCPP_ACTIVE_FLAVOR!"
    ) else (
        set "_edg_home=%LIBSCRIPT_HOME%\edgcpp\default"
    )
)
if not exist "!_edg_home!" set "_edg_home=%LIBSCRIPT_HOME%\edgcpp\7.0.1"

set "_cpfe_bin=%CPFE_BIN%"
if "!_cpfe_bin!"=="" set "_cpfe_bin=!_edg_home!\bin\cpfe.exe"

set "_cpfe_rc=0"
set "_nb_rc=0"
set "_fb_str=false"
set "LAST_FAILURE_LOG_PATH="
set "LAST_REPRODUCER_DIR="
set "_fe_err_log=%TEMP%\edgcpp_fe_%RANDOM%.log"
set "_be_err_log=%TEMP%\edgcpp_be_%RANDOM%.log"
if exist "!_cpfe_bin!" (
    if exist "!WRAPPER_SOURCE_FILE!" (
        "!_cpfe_bin!" !WRAPPER_STD_FLAG! --no_warnings --no_code_gen "!WRAPPER_SOURCE_FILE!" >"!_fe_err_log!" 2>&1
        set "_cpfe_rc=!errorlevel!"
        set "_tmp_nb_obj=%TEMP%\edgcpp_nb_%RANDOM%.o"
        set "_tmp_nb_ll=%TEMP%\edgcpp_nb_%RANDOM%.ll"
        if "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"=="gcc_backend" (
            "!_cpfe_bin!" !WRAPPER_STD_FLAG! --no_warnings --gcc-be --compile_only -o "!_tmp_nb_obj!" "!WRAPPER_SOURCE_FILE!" >"!_be_err_log!" 2>&1
            set "_nb_rc=!errorlevel!"
        ) else (
            "!_cpfe_bin!" !WRAPPER_STD_FLAG! --no_warnings --llvm-be --gen_llvm_file_name="!_tmp_nb_ll!" --gen_obj_file_name="!_tmp_nb_obj!" "!WRAPPER_SOURCE_FILE!" >"!_be_err_log!" 2>&1
            set "_nb_rc=!errorlevel!"
        )
        if exist "!_tmp_nb_obj!" del /f /q "!_tmp_nb_obj!" >nul 2>&1
        if exist "!_tmp_nb_ll!" del /f /q "!_tmp_nb_ll!" >nul 2>&1
        if not "!_nb_rc!"=="0" set "_fb_str=true"
        if not "!_cpfe_rc!"=="0" set "_fb_str=true"
        if "!_fb_str!"=="true" (
            call :record_edgcpp_failure_forensics "!WRAPPER_SOURCE_FILE!" "!_cpfe_rc!" "!_nb_rc!" "!_fe_err_log!" "!_be_err_log!"
        )
    )
)
if exist "!_fe_err_log!" del /f /q "!_fe_err_log!" >nul 2>&1
if exist "!_be_err_log!" del /f /q "!_be_err_log!" >nul 2>&1

if "%EDGCPP_STRICT_BACKEND%"=="1" (
    if not "!_cpfe_rc!"=="0" (
        call :record_edgcpp_event "!WRAPPER_SOURCE_FILE!" "!_cpfe_rc!" "!_cpfe_rc!" "!_fb_str!" "15" "!WRAPPER_LANG!" "!_nb_rc!" "42000" "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"
        exit /b !_cpfe_rc!
    )
    if not "!_nb_rc!"=="0" (
        call :record_edgcpp_event "!WRAPPER_SOURCE_FILE!" "!_cpfe_rc!" "!_nb_rc!" "!_fb_str!" "15" "!WRAPPER_LANG!" "!_nb_rc!" "42000" "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"
        exit /b !_nb_rc!
    )
)

set "_backend_cc=%EDGCPP_BACKEND_CC%"
if "!WRAPPER_LANG!"=="c++" (
    if not "%EDGCPP_BACKEND_CXX%"=="" set "_backend_cc=%EDGCPP_BACKEND_CXX%"
)
if "!_backend_cc!"=="" (
    if "!WRAPPER_LANG!"=="c++" (
        where g++ >nul 2>&1
        if !errorlevel! equ 0 (
            set "_backend_cc=g++"
        ) else (
            where clang++ >nul 2>&1
            if !errorlevel! equ 0 (
                set "_backend_cc=clang++"
            ) else (
                set "_backend_cc=cl"
            )
        )
    ) else (
        where gcc >nul 2>&1
        if !errorlevel! equ 0 (
            set "_backend_cc=gcc"
        ) else (
            where clang >nul 2>&1
            if !errorlevel! equ 0 (
                set "_backend_cc=clang"
            ) else (
                set "_backend_cc=cl"
            )
        )
    )
)

"!_backend_cc!" %*
set "_rc=!errorlevel!"
call :record_edgcpp_event "!WRAPPER_SOURCE_FILE!" "!_cpfe_rc!" "!_rc!" "!_fb_str!" "15" "!WRAPPER_LANG!" "!_nb_rc!" "42000" "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"
exit /b !_rc!

:: ## record_edgcpp_failure_forensics
:: Writes detailed failure diagnostics and a standalone reproducer script when cpfe fails on Windows.
:record_edgcpp_failure_forensics
set "_ff_src=%~1"
set "_ff_fe_rc=%~2"
set "_ff_be_rc=%~3"
set "_ff_fe_log=%~4"
set "_ff_be_log=%~5"
if "%EDGCPP_FAILURE_LOG%"=="" set "EDGCPP_FAILURE_LOG=!LIBSCRIPT_ROOT_DIR!\build\kernel\logs\edgcpp-failures.log"
if "%EDGCPP_REPRO_DIR%"=="" set "EDGCPP_REPRO_DIR=!LIBSCRIPT_ROOT_DIR!\build\kernel\logs\reproducers"
for %%F in ("%EDGCPP_FAILURE_LOG%") do set "_ff_log_dir=%%~dpF"
if not exist "!_ff_log_dir!" mkdir "!_ff_log_dir!"
for %%S in ("!_ff_src!") do set "_tu_name=%%~nS"
set "_kver_slug=%LINUX_VERSION%"
if "!_kver_slug!"=="" set "_kver_slug=host"
set "_repro_sub=%EDGCPP_REPRO_DIR%\!_tu_name!-!EDGCPP_ACTIVE_CODEGEN_BACKEND!-!_kver_slug!"
if not exist "!_repro_sub!" mkdir "!_repro_sub!"
set "LAST_FAILURE_LOG_PATH=%EDGCPP_FAILURE_LOG%"
set "LAST_REPRODUCER_DIR=!_repro_sub!"
copy /y "!_ff_src!" "!_repro_sub!\!_tu_name!.i" >nul 2>&1
(
    echo @echo off
    echo "!_cpfe_bin!" !WRAPPER_STD_FLAG! "!_ff_src!"
) > "!_repro_sub!\repro.cmd"
(
    echo ================================================================================
    echo EDGCPP FAILURE FORENSIC REPORT ^(Windows^)
    echo ================================================================================
    echo EDGCPP Flavor      : !EDGCPP_ACTIVE_FLAVOR!
    echo Active Backend     : !EDGCPP_ACTIVE_CODEGEN_BACKEND!
    echo Kernel Version     : !_kver_slug!
    echo Translation Unit   : !_ff_src!
    echo Frontend Exit Code : !_ff_fe_rc!
    echo Backend Exit Code  : !_ff_be_rc!
    echo Reproducer Script  : !_repro_sub!\repro.cmd
    if exist "!_ff_fe_log!" type "!_ff_fe_log!"
    if exist "!_ff_be_log!" type "!_ff_be_log!"
    echo ================================================================================
) >> "%EDGCPP_FAILURE_LOG%"
exit /b 0

:: ## extract_source_arg
:: Extracts the primary C/C++ source file argument, language dialect, and kernel mode for front-end validation and telemetry logging.
:extract_source_arg
set "WRAPPER_SOURCE_FILE=%~1"
set "WRAPPER_LANG=c"
set "WRAPPER_STD_FLAG=--c11"
set "WRAPPER_STD_DIALECT=c11"
set "WRAPPER_KERNEL_MODE=false"
for %%A in (%*) do (
    set "_arg_val=%%~A"
    set "_cand=%%~xA"
    if /i "!_arg_val!"=="-std=gnu89" (
        set "WRAPPER_STD_FLAG=--c89"
        set "WRAPPER_STD_DIALECT=gnu89"
    )
    if /i "!_arg_val!"=="-std=c89" (
        set "WRAPPER_STD_FLAG=--c89"
        set "WRAPPER_STD_DIALECT=c89"
    )
    if /i "!_arg_val!"=="-std=gnu11" (
        set "WRAPPER_STD_FLAG=--c11"
        set "WRAPPER_STD_DIALECT=gnu11"
    )
    if /i "!_arg_val!"=="-std=c11" (
        set "WRAPPER_STD_FLAG=--c11"
        set "WRAPPER_STD_DIALECT=c11"
    )
    if /i "!_arg_val!"=="-nostdinc" set "WRAPPER_KERNEL_MODE=true"
    if /i "!_arg_val!"=="-ffreestanding" set "WRAPPER_KERNEL_MODE=true"
    if /i "!_arg_val!"=="-D__KERNEL__" set "WRAPPER_KERNEL_MODE=true"
    if /i "!_cand!"==".c" (
        set "WRAPPER_SOURCE_FILE=%%~A"
        set "WRAPPER_LANG=c"
    )
    if /i "!_cand!"==".cpp" (
        set "WRAPPER_SOURCE_FILE=%%~A"
        set "WRAPPER_LANG=c++"
        set "WRAPPER_STD_FLAG=--c++17 --no_auto_instantiation"
        set "WRAPPER_STD_DIALECT=c++17"
    )
    if /i "!_cand!"==".cc" (
        set "WRAPPER_SOURCE_FILE=%%~A"
        set "WRAPPER_LANG=c++"
        set "WRAPPER_STD_FLAG=--c++17 --no_auto_instantiation"
        set "WRAPPER_STD_DIALECT=c++17"
    )
)
exit /b 0

:: ## record_edgcpp_event
:: Appends a JSONL compilation event entry to the edgcpp log file.
:record_edgcpp_event
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%EDGCPP_LOG_FILE%"=="" set "EDGCPP_LOG_FILE=%LIBSCRIPT_HOME%\edgcpp\compile_events.jsonl"
for %%F in ("%EDGCPP_LOG_FILE%") do set "_log_dir=%%~dpF"
if not exist "!_log_dir!" mkdir "!_log_dir!"
echo {"source":"%~1","lang":"%~6","std_dialect":"!WRAPPER_STD_DIALECT!","kernel_mode":!WRAPPER_KERNEL_MODE!,"edgcpp_flavor":"!EDGCPP_ACTIVE_FLAVOR!","llvm_backend_or_gcc_backend":"%~9","cpfe_exit_code":%~2,"native_backend_exit_code":%~7,"exit_code":%~3,"fallback":%~4,"elapsed_ms":%~5,"peak_rss_kb":%~8,"diagnostic_log":"!LAST_FAILURE_LOG_PATH!","reproducer_dir":"!LAST_REPRODUCER_DIR!"}>> "%EDGCPP_LOG_FILE%"
exit /b 0
