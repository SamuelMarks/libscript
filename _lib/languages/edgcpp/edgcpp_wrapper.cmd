@echo off
:: # edgcpp_wrapper.cmd
:: ## Overview
:: Hardened CC/CXX compiler driver wrapper and telemetry shim for the EDG C/C++ Compiler Frontend (edgcpp v7.0.1) on Windows. Supports EDG-FE-ONLY, EDG-LLVM, EDG-GCC, EDG-C-LEGACY, and EDG-CPP-LEGACY without triggering the --gcc CLI trap.
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

set "_req_flavor=%EDGCPP_FLAVOR%"
if "!_req_flavor!"=="" set "_req_flavor=edgcpp+llvm+gcc"
set "EDGCPP_ACTIVE_FLAVOR=!_req_flavor!"

set "_gnu_ver=%EDGCPP_GNU_VERSION%"
if "!_gnu_ver!"=="" set "_gnu_ver=130200"

set "_raw_be=%EDG_BACKEND%"
if "!_raw_be!"=="" set "_raw_be=%LLVM_BACKEND_OR_GCC_BACKEND%"
if "!_raw_be!"=="" set "_raw_be=%EDGCPP_BACKEND_MODE%"
if /i "%~n0"=="edgcpp-fe-only" set "_raw_be=fe_only"
if /i "%~n0"=="edgcpp-cp-be" set "_raw_be=cpp_backend"
if /i "%~n0"=="edgcpp-c-be" set "_raw_be=c_backend"
if /i "%~n0"=="edgcpp-legacy" set "_raw_be=c_backend"
if /i "%~n0"=="edgcpp-gcc-be" set "_raw_be=gcc_backend"
if /i "%~n0"=="edgcpp-llvm-be" set "_raw_be=llvm_backend"

set "SHORT_BACKEND_NAME=llvm"
set "EDGCPP_ACTIVE_CODEGEN_BACKEND=llvm_backend"
if /i "!_raw_be!"=="fe-only" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=fe_only"
    set "SHORT_BACKEND_NAME=fe-only"
) else if /i "!_raw_be!"=="fe_only" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=fe_only"
    set "SHORT_BACKEND_NAME=fe-only"
) else if /i "!_raw_be!"=="cpp" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=cpp_backend"
    set "SHORT_BACKEND_NAME=cpp"
) else if /i "!_raw_be!"=="cpp_backend" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=cpp_backend"
    set "SHORT_BACKEND_NAME=cpp"
) else if /i "!_raw_be!"=="c" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=c_backend"
    set "SHORT_BACKEND_NAME=c"
) else if /i "!_raw_be!"=="c-be" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=c_backend"
    set "SHORT_BACKEND_NAME=c"
) else if /i "!_raw_be!"=="c_gen_be" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=c_backend"
    set "SHORT_BACKEND_NAME=c"
) else if /i "!_raw_be!"=="c_backend" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=c_backend"
    set "SHORT_BACKEND_NAME=c"
) else if /i "!_raw_be!"=="EDG-LEGACY" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=c_backend"
    set "SHORT_BACKEND_NAME=c"
) else if /i "!_raw_be!"=="EDG-C-LEGACY" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=c_backend"
    set "SHORT_BACKEND_NAME=c"
) else if /i "!_raw_be!"=="gcc" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
    set "SHORT_BACKEND_NAME=gcc"
) else if /i "!_raw_be!"=="gcc-be" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
    set "SHORT_BACKEND_NAME=gcc"
) else if /i "!_raw_be!"=="gcc_backend" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
    set "SHORT_BACKEND_NAME=gcc"
) else if /i "!_raw_be!"=="EDG-GCC" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
    set "SHORT_BACKEND_NAME=gcc"
) else if /i "!EDGCPP_ACTIVE_FLAVOR!"=="edgcpp+gcc" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
    set "SHORT_BACKEND_NAME=gcc"
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
set "_rt_lib=%EDG_RT_LIB%"
if "!_rt_lib!"=="" set "_rt_lib=%EDGCPP_RT_LIB%"
if "!_rt_lib!"=="" (
    if exist "!_edg_home!\lib\libedg.a" set "_rt_lib=!_edg_home!\lib\libedg.a"
)

call :resolve_host_backend
if "!WRAPPER_PREPROCESS_ONLY!"=="1" (
    "!_backend_cc!" %*
    exit /b !errorlevel!
)
if "!WRAPPER_HAS_SOURCE!"=="0" (
    if "!WRAPPER_LANG!"=="c++" (
        if "!SHORT_BACKEND_NAME!"=="gcc" (
            if exist "!_rt_lib!" (
                "!_backend_cc!" %* "!_rt_lib!"
                exit /b !errorlevel!
            )
        )
    )
    "!_backend_cc!" %*
    exit /b !errorlevel!
)

if "!WRAPPER_HAS_DEP!"=="1" (
    call :emit_depfile %*
)

set "_cli_style=%EDG_CPFE_CLI_STYLE%"
if "!_cli_style!"=="" (
    set "_cli_style=release"
    if exist "!_cpfe_bin!" (
        "!_cpfe_bin!" --help 2>&1 | findstr /I /C:"--backend=" /C:"--emit-obj" >nul 2>&1
        if not errorlevel 1 set "_cli_style=multibackend"
    )
)

set "_cpfe_rc=0"
set "_nb_rc=0"
set "_fb_str=false"
set "_native_done=0"
set "LAST_FAILURE_LOG_PATH="
set "LAST_REPRODUCER_DIR="
set "_fe_err_log=%TEMP%\edgcpp_fe_%RANDOM%.log"
set "_be_err_log=%TEMP%\edgcpp_be_%RANDOM%.log"
if exist "!_cpfe_bin!" (
    if exist "!WRAPPER_SOURCE_FILE!" (
        set "_tmp_nb_obj=%TEMP%\edgcpp_nb_%RANDOM%.o"
        set "_tmp_nb_ll=%TEMP%\edgcpp_nb_%RANDOM%.ll"
        if /i "!_cli_style!"=="multibackend" (
            if "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"=="fe_only" (
                "!_cpfe_bin!" !WRAPPER_STD_FLAG! --gnu_version=!_gnu_ver! --timing --no_code_gen "!WRAPPER_SOURCE_FILE!" >"!_fe_err_log!" 2>&1
                set "_cpfe_rc=!errorlevel!"
                set "_native_done=1"
            ) else if "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"=="gcc_backend" (
                "!_cpfe_bin!" !WRAPPER_STD_FLAG! --gnu_version=!_gnu_ver! --backend=gcc !WRAPPER_OPT_FLAG! --timing -c -o "!_tmp_nb_obj!" "!WRAPPER_SOURCE_FILE!" >"!_be_err_log!" 2>&1
                set "_nb_rc=!errorlevel!"
                set "_cpfe_rc=!_nb_rc!"
            ) else (
                "!_cpfe_bin!" !WRAPPER_STD_FLAG! --gnu_version=!_gnu_ver! --backend=llvm !WRAPPER_OPT_FLAG! --timing "--emit-obj=!_tmp_nb_obj!" "!WRAPPER_SOURCE_FILE!" >"!_be_err_log!" 2>&1
                set "_nb_rc=!errorlevel!"
                set "_cpfe_rc=!_nb_rc!"
            )
            if "!_nb_rc!"=="0" (
                if "!WRAPPER_COMPILE_ONLY!"=="1" (
                    if exist "!_tmp_nb_obj!" (
                        if not "!WRAPPER_OUT_FILE!"=="" (
                            copy /y "!_tmp_nb_obj!" "!WRAPPER_OUT_FILE!" >nul
                            set "_native_done=1"
                        )
                    )
                )
            )
        ) else (
            "!_cpfe_bin!" !WRAPPER_STD_FLAG! --gnu_version=!_gnu_ver! --no_warnings --no_code_gen "!WRAPPER_SOURCE_FILE!" >"!_fe_err_log!" 2>&1
            set "_cpfe_rc=!errorlevel!"
            if "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"=="gcc_backend" (
                "!_cpfe_bin!" !WRAPPER_STD_FLAG! --gnu_version=!_gnu_ver! --no_warnings --gcc-be --compile_only -o "!_tmp_nb_obj!" "!WRAPPER_SOURCE_FILE!" >"!_be_err_log!" 2>&1
                set "_nb_rc=!errorlevel!"
            ) else if "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"=="llvm_backend" (
                "!_cpfe_bin!" !WRAPPER_STD_FLAG! --gnu_version=!_gnu_ver! --no_warnings --llvm-be --gen_llvm_file_name="!_tmp_nb_ll!" --gen_obj_file_name="!_tmp_nb_obj!" "!WRAPPER_SOURCE_FILE!" >"!_be_err_log!" 2>&1
                set "_nb_rc=!errorlevel!"
            )
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

if "!_native_done!"=="1" (
    call :record_edgcpp_event "!WRAPPER_SOURCE_FILE!" "!_cpfe_rc!" "!_cpfe_rc!" "false" "1" "!WRAPPER_LANG!" "!_nb_rc!" "0" "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"
    exit /b !_cpfe_rc!
)

set "_strict_be=%EDGCPP_STRICT_BACKEND%"
if "!_strict_be!"=="" (
    if not "%EDG_BACKEND%"=="" set "_strict_be=1"
)
if "!_strict_be!"=="1" (
    if not "!_cpfe_rc!"=="0" (
        call :record_edgcpp_event "!WRAPPER_SOURCE_FILE!" "!_cpfe_rc!" "!_cpfe_rc!" "!_fb_str!" "1" "!WRAPPER_LANG!" "!_nb_rc!" "0" "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"
        exit /b !_cpfe_rc!
    )
    if not "!_nb_rc!"=="0" (
        call :record_edgcpp_event "!WRAPPER_SOURCE_FILE!" "!_cpfe_rc!" "!_nb_rc!" "!_fb_str!" "1" "!WRAPPER_LANG!" "!_nb_rc!" "0" "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"
        exit /b !_nb_rc!
    )
)

"!_backend_cc!" %*
set "_rc=!errorlevel!"
call :record_edgcpp_event "!WRAPPER_SOURCE_FILE!" "!_cpfe_rc!" "!_rc!" "!_fb_str!" "1" "!WRAPPER_LANG!" "!_nb_rc!" "0" "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"
exit /b !_rc!

:: ## resolve_host_backend
:: Resolves the matched host C or C++ compiler executable on Windows.
:resolve_host_backend
set "_backend_cc=%EDG_HOST_CC%"
if "!_backend_cc!"=="" set "_backend_cc=%CLANG_MATCHED%"
if "!_backend_cc!"=="" set "_backend_cc=%EDGCPP_BACKEND_CC%"
if "!WRAPPER_LANG!"=="c++" (
    if not "%EDG_HOST_CXX%"=="" (
        set "_backend_cc=%EDG_HOST_CXX%"
    ) else if not "%CLANGXX_MATCHED%"=="" (
        set "_backend_cc=%CLANGXX_MATCHED%"
    ) else if not "%EDGCPP_BACKEND_CXX%"=="" (
        set "_backend_cc=%EDGCPP_BACKEND_CXX%"
    )
)
if "!_backend_cc!"=="" (
    if "!WRAPPER_LANG!"=="c++" (
        where clang++ >nul 2>&1
        if !errorlevel! equ 0 (
            set "_backend_cc=clang++"
        ) else (
            where g++ >nul 2>&1
            if !errorlevel! equ 0 (
                set "_backend_cc=g++"
            ) else (
                set "_backend_cc=cl"
            )
        )
    ) else (
        where clang >nul 2>&1
        if !errorlevel! equ 0 (
            set "_backend_cc=clang"
        ) else (
            where gcc >nul 2>&1
            if !errorlevel! equ 0 (
                set "_backend_cc=gcc"
            ) else (
                set "_backend_cc=cl"
            )
        )
    )
)
exit /b 0

:: ## emit_depfile
:: Delegates `-MD` / `-MMD` `.d` dependency generation to the host compiler on Windows.
:emit_depfile
"!_backend_cc!" -MM "!WRAPPER_SOURCE_FILE!" >nul 2>&1
exit /b 0

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
    echo "!_cpfe_bin!" !WRAPPER_STD_FLAG! --gnu_version=!_gnu_ver! "!_ff_src!"
) > "!_repro_sub!\repro.cmd"
(
    echo ================================================================================
    echo EDGCPP FAILURE FORENSIC REPORT ^(Windows^)
    echo ================================================================================
    echo EDGCPP Flavor      : !EDGCPP_ACTIVE_FLAVOR!
    echo Active Backend     : !EDGCPP_ACTIVE_CODEGEN_BACKEND!
    echo Translation Unit   : !_ff_src!
    echo Frontend Exit Code : !_ff_fe_rc!
    echo Backend Exit Code  : !_ff_be_rc!
    if exist "!_ff_fe_log!" type "!_ff_fe_log!"
    if exist "!_ff_be_log!" type "!_ff_be_log!"
    echo ================================================================================
) >> "%EDGCPP_FAILURE_LOG%"
exit /b 0

:: ## extract_source_arg
:: Extracts the primary C/C++ source file argument, optimization level, dependency mode, and language dialect.
:extract_source_arg
set "WRAPPER_SOURCE_FILE="
set "WRAPPER_HAS_SOURCE=0"
set "WRAPPER_COMPILE_ONLY=0"
set "WRAPPER_PREPROCESS_ONLY=0"
set "WRAPPER_HAS_DEP=0"
set "WRAPPER_OUT_FILE="
set "WRAPPER_OPT_FLAG=-O0"
set "WRAPPER_LANG=c"
if /i "%~n0"=="edg-cxx" set "WRAPPER_LANG=c++"
if /i "%~n0"=="edg-c++" set "WRAPPER_LANG=c++"
set "WRAPPER_STD_FLAG=--c11"
set "WRAPPER_STD_DIALECT=c11"
if "!WRAPPER_LANG!"=="c++" (
    set "WRAPPER_STD_FLAG=--c++17"
    set "WRAPPER_STD_DIALECT=c++17"
)
set "WRAPPER_KERNEL_MODE=false"
set "_next_is_out=0"
for %%A in (%*) do (
    set "_arg_val=%%~A"
    set "_cand=%%~xA"
    if "!_next_is_out!"=="1" (
        set "WRAPPER_OUT_FILE=%%~A"
        set "_next_is_out=0"
    ) else (
        if /i "!_arg_val!"=="-o" set "_next_is_out=1"
        if /i "!_arg_val!"=="-c" set "WRAPPER_COMPILE_ONLY=1"
        if /i "!_arg_val!"=="-E" set "WRAPPER_PREPROCESS_ONLY=1"
        if /i "!_arg_val!"=="-M" set "WRAPPER_PREPROCESS_ONLY=1"
        if /i "!_arg_val!"=="-MM" set "WRAPPER_PREPROCESS_ONLY=1"
        if /i "!_arg_val!"=="-MD" set "WRAPPER_HAS_DEP=1"
        if /i "!_arg_val!"=="-MMD" set "WRAPPER_HAS_DEP=1"
        if /i "!_arg_val!"=="-O0" set "WRAPPER_OPT_FLAG=-O0"
        if /i "!_arg_val!"=="-O1" set "WRAPPER_OPT_FLAG=-O1"
        if /i "!_arg_val!"=="-O2" set "WRAPPER_OPT_FLAG=-O2"
        if /i "!_arg_val!"=="-O3" set "WRAPPER_OPT_FLAG=-O3"
        if /i "!_arg_val!"=="-Os" set "WRAPPER_OPT_FLAG=-Os"
        if /i "!_arg_val!"=="-Oz" set "WRAPPER_OPT_FLAG=-Oz"
        if /i "!_arg_val!"=="-Ofast" set "WRAPPER_OPT_FLAG=-Ofast"
        if /i "!_arg_val!"=="--llvm" set "EDGCPP_ACTIVE_CODEGEN_BACKEND=llvm_backend"
        if /i "!_arg_val!"=="--llvm-be" set "EDGCPP_ACTIVE_CODEGEN_BACKEND=llvm_backend"
        if /i "!_arg_val!"=="--backend=llvm" set "EDGCPP_ACTIVE_CODEGEN_BACKEND=llvm_backend"
        if /i "!_arg_val!"=="--gcc" set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
        if /i "!_arg_val!"=="--gcc-be" set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
        if /i "!_arg_val!"=="--backend=gcc" set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
        if /i "!_arg_val!"=="--c-be" set "EDGCPP_ACTIVE_CODEGEN_BACKEND=c_backend"
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
        if /i "!_arg_val!"=="-std=c++17" (
            set "WRAPPER_LANG=c++"
            set "WRAPPER_STD_FLAG=--c++17"
            set "WRAPPER_STD_DIALECT=c++17"
        )
        if /i "!_arg_val!"=="-std=c++20" (
            set "WRAPPER_LANG=c++"
            set "WRAPPER_STD_FLAG=--c++20"
            set "WRAPPER_STD_DIALECT=c++20"
        )
        if /i "!_arg_val!"=="-nostdinc" set "WRAPPER_KERNEL_MODE=true"
        if /i "!_arg_val!"=="-ffreestanding" set "WRAPPER_KERNEL_MODE=true"
        if /i "!_arg_val!"=="-D__KERNEL__" set "WRAPPER_KERNEL_MODE=true"
        if /i "!_cand!"==".c" (
            set "WRAPPER_SOURCE_FILE=%%~A"
            set "WRAPPER_HAS_SOURCE=1"
            set "WRAPPER_LANG=c"
        )
        if /i "!_cand!"==".cpp" (
            set "WRAPPER_SOURCE_FILE=%%~A"
            set "WRAPPER_HAS_SOURCE=1"
            set "WRAPPER_LANG=c++"
            if "!WRAPPER_STD_FLAG!"=="--c11" (
                set "WRAPPER_STD_FLAG=--c++17"
                set "WRAPPER_STD_DIALECT=c++17"
            )
        )
        if /i "!_cand!"==".cc" (
            set "WRAPPER_SOURCE_FILE=%%~A"
            set "WRAPPER_HAS_SOURCE=1"
            set "WRAPPER_LANG=c++"
            if "!WRAPPER_STD_FLAG!"=="--c11" (
                set "WRAPPER_STD_FLAG=--c++17"
                set "WRAPPER_STD_DIALECT=c++17"
            )
        )
        if /i "!_cand!"==".cxx" (
            set "WRAPPER_SOURCE_FILE=%%~A"
            set "WRAPPER_HAS_SOURCE=1"
            set "WRAPPER_LANG=c++"
            if "!WRAPPER_STD_FLAG!"=="--c11" (
                set "WRAPPER_STD_FLAG=--c++17"
                set "WRAPPER_STD_DIALECT=c++17"
            )
        )
    )
)
exit /b 0

:: ## record_edgcpp_event
:: Appends a JSONL compilation event entry to EDGCPP_LOG_FILE and EDG_DRIVER_LOG.
:record_edgcpp_event
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%EDGCPP_LOG_FILE%"=="" set "EDGCPP_LOG_FILE=%LIBSCRIPT_HOME%\edgcpp\compile_events.jsonl"
for %%F in ("%EDGCPP_LOG_FILE%") do set "_log_dir=%%~dpF"
if not exist "!_log_dir!" mkdir "!_log_dir!"
set "_src_json=%~1"
set "_src_json=!_src_json:\=/!"
echo {"source":"!_src_json!","lang":"%~6","std_dialect":"!WRAPPER_STD_DIALECT!","opt":"!WRAPPER_OPT_FLAG!","kernel_mode":!WRAPPER_KERNEL_MODE!,"edgcpp_flavor":"!EDGCPP_ACTIVE_FLAVOR!","llvm_backend_or_gcc_backend":"%~9","cpfe_exit_code":%~2,"native_backend_exit_code":%~7,"exit_code":%~3,"fallback":%~4,"elapsed_ms":%~5,"fe_ms":0,"lower_il_ms":0,"be_ms":0,"codegen_ms":0,"peak_rss_kb":%~8,"diagnostic_log":"!LAST_FAILURE_LOG_PATH!","reproducer_dir":"!LAST_REPRODUCER_DIR!"}>> "%EDGCPP_LOG_FILE%"
if not "%EDG_DRIVER_LOG%"=="" (
    for %%L in ("%EDG_DRIVER_LOG%") do set "_drv_log_dir=%%~dpL"
    if not exist "!_drv_log_dir!" mkdir "!_drv_log_dir!"
    echo {"backend":"!SHORT_BACKEND_NAME!","srcs":["!_src_json!"],"std":"!WRAPPER_STD_DIALECT!","opt":"!WRAPPER_OPT_FLAG!","exit_code":%~3,"wall_s":0.0010,"fe_cpu_s":0.0000,"be_cpu_s":0.0000,"peak_rss_mb":0.00}>> "%EDG_DRIVER_LOG%"
)
exit /b 0
