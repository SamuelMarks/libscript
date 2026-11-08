@echo off
:: # remote_sync.cmd
:: ## Overview
:: Unified gitignore-aware, build-cache-preserving remote synchronization and VM public IP TTL caching utilities for LibScript on Windows.
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\remote_sync.cmd" :libscript_sync_app_to_remote <src_dir> <user@host> <remote_dest>

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

set "SSH_BASE_OPTS=-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30"

if "%~1"=="" exit /b 0
set "_rs_sub=%~1"
if "!_rs_sub:~0,1!"==":" (
    shift
    goto !_rs_sub!
)
if /i "!_rs_sub!"=="sync-app" (
    shift
    goto :libscript_sync_app_to_remote
)
if /i "!_rs_sub!"=="sync-runtime" (
    shift
    goto :libscript_sync_runtime_to_remote
)
if /i "!_rs_sub!"=="scp-to" (
    shift
    goto :libscript_scp_to_remote
)
if /i "!_rs_sub!"=="scp-from" (
    shift
    goto :libscript_scp_from_remote
)
if /i "!_rs_sub!"=="ssh-opts" (
    shift
    goto :libscript_ssh_mux_opts
)
if /i "!_rs_sub!"=="compute-hash" (
    shift
    goto :libscript_compute_tree_hash
)
exit /b 0

:: ## libscript_ssh_mux_opts
:: Prints OpenSSH connection and ControlMaster multiplexing options with a short ControlPath.
:libscript_ssh_mux_opts
if "%LIBSCRIPT_DISABLE_SSH_MUX%"=="1" (
    echo !SSH_BASE_OPTS!
    exit /b 0
)
set "_smo_tmp=%TMPDIR%"
if "!_smo_tmp!"=="" set "_smo_tmp=%TEMP%"
if "!_smo_tmp!"=="" set "_smo_tmp=/tmp"
if "!_smo_tmp:~-1!"=="\" set "_smo_tmp=!_smo_tmp:~0,-1!"
if "!_smo_tmp:~-1!"=="/" set "_smo_tmp=!_smo_tmp:~0,-1!"
if not "%LIBSCRIPT_SSH_MUX_DIR%"=="" (
    set "_smo_dir=%LIBSCRIPT_SSH_MUX_DIR%"
) else if not "!_smo_tmp:~36,1!"=="" (
    set "_smo_short=%LIBSCRIPT_SHORT_TMPDIR%"
    if "!_smo_short!"=="" set "_smo_short=/tmp"
    set "_smo_dir=!_smo_short!/ls_mux"
) else (
    set "_smo_dir=!_smo_tmp!/ls_mux"
)
echo !SSH_BASE_OPTS! -o ControlMaster=auto -o ControlPersist=60s -o ControlPath=!_smo_dir!/%%C
exit /b 0

:: ## libscript_sync_app_to_remote
:: Synchronizes a local application directory to a remote host destination using rsync (with tar-over-ssh fallback).
:: Removes remote files and directories that no longer exist locally (--delete), respects .gitignore (--filter=':- .gitignore'),
:: and protects remote build/cache directories (./build, ./cmake-build-debug, ./cmake-build-release, ./cmake-build-*, ./node_modules, ./target, ./.venv, etc.) from deletion.
:libscript_sync_app_to_remote
set "_sar_src=%~1"
set "_sar_target=%~2"
set "_sar_dest=%~3"
if "!_sar_src!"=="" (
    echo [ERROR] Usage: remote_sync.cmd :libscript_sync_app_to_remote ^<src_dir^> ^<user@host^> ^<remote_dest^> 1>&2
    exit /b 1
)
if not exist "!_sar_src!" (
    echo [ERROR] Local source directory does not exist: !_sar_src! 1>&2
    exit /b 1
)
if "!_sar_src:~-1!"=="\" set "_sar_src=!_sar_src:~0,-1!"
if "!_sar_src:~-1!"=="/" set "_sar_src=!_sar_src:~0,-1!"
set "_sar_rsync_dest=~/%_sar_dest%/"
if "!_sar_dest:~0,1!"=="/" set "_sar_rsync_dest=%_sar_dest%/"
if "!_sar_dest:~0,1!"=="~" set "_sar_rsync_dest=%_sar_dest%/"

set "_sar_hash_dir=%USERPROFILE%\.cache\libscript\sync_hashes"
if not exist "!_sar_hash_dir!" mkdir "!_sar_hash_dir!" 2>nul
set "_sar_key=!_sar_target!_!_sar_dest!"
set "_sar_key=!_sar_key:/=_!"
set "_sar_key=!_sar_key:\=_!"
set "_sar_key=!_sar_key::=_!"
set "_sar_key=!_sar_key:@=_!"
set "_sar_hash_file=!_sar_hash_dir!\!_sar_key!.sha256"
set "_sar_cur_hash="
for /f "delims=" %%H in ('call "!THIS_FILE!" compute-hash "!_sar_src!" 2^>nul') do set "_sar_cur_hash=%%H"
set "_sar_bypass=0"
if "!FORCE_REINSTALL!"=="1" set "_sar_bypass=1"
if "!FORCE_REBUILD!"=="1" set "_sar_bypass=1"
if "!FORCE_UPLOAD!"=="1" set "_sar_bypass=1"
if "!_sar_bypass!"=="0" if exist "!_sar_hash_file!" (
    set "_sar_cached="
    for /f "delims=" %%C in ("!_sar_hash_file!") do set "_sar_cached=%%C"
    if "!_sar_cached!"=="!_sar_cur_hash!" (
        ssh !SSH_BASE_OPTS! "!_sar_target!" "[ -d !_sar_dest! ]" >nul 2>&1
        if not errorlevel 1 (
            echo [REUSE] Remote directory !_sar_target!:!_sar_dest! matches local tree hash ^(!_sar_cur_hash!^); skipping sync.
            exit /b 0
        )
    )
)

ssh !SSH_BASE_OPTS! "!_sar_target!" "mkdir -p !_sar_dest!"

where rsync >nul 2>&1
if not errorlevel 1 (
    set "_sar_excl_file=%TEMP%\libscript_sar_excl_%RANDOM%.txt"
    git -C "!_sar_src!" rev-parse --is-inside-work-tree >nul 2>&1
    if not errorlevel 1 (
        git -C "!_sar_src!" ls-files --others -i --exclude-standard --directory > "!_sar_excl_file!" 2>nul
        set "_sar_gi_arg=--exclude-from=!_sar_excl_file!"
    ) else (
        set "_sar_gi_arg=--filter=:- .gitignore"
    )
    rsync -avz --delete --filter="P build" --filter="P coverage" --filter="P .coverage" --filter="P .nyc_output" --filter="P composeApp/build" --filter="P cmake-build-debug" --filter="P cmake-build-release" --filter="P cmake-build-relwithdebinfo" --filter="P cmake-build-minsizerel" --filter="P cmake-build-*" --filter="P CMakeFiles" --filter="P CMakeCache.txt" --filter="P node_modules" --filter="P target" --filter="P .venv" --filter="P venv" --filter="P dist" --filter="P out" --filter="P webroot" --filter="P .angular" --filter="P .vite" --filter="P .next" --filter="P .nuxt" --filter="P .turbo" --filter="P .parcel-cache" --filter="P .gradle" --filter="P .kotlin" --filter="P .cache" --filter="P __pycache__" --filter="P .pytest_cache" --filter="P .mypy_cache" --filter="P .ruff_cache" --filter="P .tox" --filter="P .nox" --filter="P .terraform" --filter="P .env" --filter="P .env.secrets" --filter="P .env.libscript" --filter="P .libscript_build.sha256" --filter="P .libscript_src_hash" --filter="P .libscript_py_hash" --filter="P .libscript_kmp_build.sha256" --filter="P data" --filter="P logs" --filter="P *.duckdb" --filter="P *.duckdb.wal" "!_sar_gi_arg!" --exclude=".git" --exclude="build" --exclude="coverage/" --exclude=".coverage" --exclude=".nyc_output/" --exclude="composeApp/build/" --exclude="cmake-build-debug" --exclude="cmake-build-release" --exclude="cmake-build-relwithdebinfo" --exclude="cmake-build-minsizerel" --exclude="cmake-build-*" --exclude="CMakeFiles" --exclude="CMakeCache.txt" --exclude="node_modules" --exclude="target" --exclude=".venv" --exclude="venv" --exclude="dist" --exclude="out" --exclude="webroot" --exclude=".angular" --exclude=".vite" --exclude=".next" --exclude=".nuxt" --exclude=".turbo" --exclude=".parcel-cache" --exclude=".gradle" --exclude=".kotlin" --exclude=".cache" --exclude="__pycache__" --exclude="*.pyc" --exclude="*.pyo" --exclude=".pytest_cache" --exclude=".mypy_cache" --exclude=".ruff_cache" --exclude=".tox" --exclude=".nox" --exclude=".terraform" --exclude=".DS_Store" --exclude="logs" --exclude="*.log" --exclude="*.duckdb" --exclude="*.duckdb.wal" --exclude=".env.libscript" -e "ssh !SSH_BASE_OPTS!" "!_sar_src!/" "!_sar_target!:!_sar_rsync_dest!"
    if not errorlevel 1 (
        > "!_sar_hash_file!" echo !_sar_cur_hash!
        exit /b 0
    )
)

ssh !SSH_BASE_OPTS! "!_sar_target!" "find !_sar_dest! -mindepth 1 \( -name build -o -name cmake-build-debug -o -name cmake-build-release -o -name cmake-build-relwithdebinfo -o -name cmake-build-minsizerel -o -name 'cmake-build-*' -o -name CMakeFiles -o -name node_modules -o -name target -o -name .venv -o -name venv -o -name dist -o -name out -o -name webroot -o -name .angular -o -name .vite -o -name .next -o -name .nuxt -o -name .turbo -o -name .parcel-cache -o -name .gradle -o -name .kotlin -o -name .cache -o -name __pycache__ -o -name .pytest_cache -o -name .mypy_cache -o -name .ruff_cache -o -name .tox -o -name .nox -o -name .terraform -o -name data -o -name logs \) -prune -o -type f ! -name '.env*' ! -name 'CMakeCache.txt' ! -name '.libscript_*' ! -name '*.duckdb*' -exec rm -f {} + 2>/dev/null || true; find !_sar_dest! -mindepth 1 -depth \( -name build -o -name cmake-build-debug -o -name cmake-build-release -o -name cmake-build-relwithdebinfo -o -name cmake-build-minsizerel -o -name 'cmake-build-*' -o -name CMakeFiles -o -name node_modules -o -name target -o -name .venv -o -name venv -o -name dist -o -name out -o -name webroot -o -name .angular -o -name .vite -o -name .next -o -name .nuxt -o -name .turbo -o -name .parcel-cache -o -name .gradle -o -name .kotlin -o -name .cache -o -name __pycache__ -o -name .pytest_cache -o -name .mypy_cache -o -name .ruff_cache -o -name .tox -o -name .nox -o -name .terraform -o -name data -o -name logs \) -prune -o -type d -empty -exec rmdir {} + 2>/dev/null || true"

where tar >nul 2>&1
if not errorlevel 1 (
    tar -czf - --exclude=".git" --exclude="build" --exclude="coverage" --exclude=".coverage" --exclude=".nyc_output" --exclude="composeApp/build" --exclude="cmake-build-debug" --exclude="cmake-build-release" --exclude="cmake-build-relwithdebinfo" --exclude="cmake-build-minsizerel" --exclude="cmake-build-*" --exclude="CMakeFiles" --exclude="CMakeCache.txt" --exclude="node_modules" --exclude="target" --exclude=".venv" --exclude="venv" --exclude="dist" --exclude="out" --exclude="webroot" --exclude=".angular" --exclude=".vite" --exclude=".next" --exclude=".nuxt" --exclude=".turbo" --exclude=".parcel-cache" --exclude=".gradle" --exclude=".kotlin" --exclude=".cache" --exclude="__pycache__" --exclude="*.pyc" --exclude="*.pyo" --exclude=".pytest_cache" --exclude=".mypy_cache" --exclude=".ruff_cache" --exclude=".tox" --exclude=".nox" --exclude=".terraform" --exclude=".DS_Store" --exclude="logs" --exclude="*.log" --exclude="*.duckdb" --exclude="*.duckdb.wal" --exclude=".env.libscript" -C "!_sar_src!" . | ssh !SSH_BASE_OPTS! "!_sar_target!" "tar -xzf - -C !_sar_dest!"
    if not errorlevel 1 (
        > "!_sar_hash_file!" echo !_sar_cur_hash!
        exit /b 0
    )
    exit /b 1
)

scp !SSH_BASE_OPTS! -r "!_sar_src!\*" "!_sar_target!:!_sar_rsync_dest!"
if not errorlevel 1 (
    > "!_sar_hash_file!" echo !_sar_cur_hash!
    exit /b 0
)
exit /b 1

:: ## libscript_sync_runtime_to_remote
:: Synchronizes LIBSCRIPT_ROOT_DIR to ~/libscript on a remote node, honoring .gitignore, removing stale remote directories, and preserving remote cache/build directories.
:libscript_sync_runtime_to_remote
set "_srr_target=%~1"
set "_srr_dest=%~2"
if "!_srr_dest!"=="" set "_srr_dest=~/libscript"
if "!_srr_target!"=="" (
    echo [ERROR] Usage: remote_sync.cmd :libscript_sync_runtime_to_remote ^<user@host^> [remote_dest] 1>&2
    exit /b 1
)
set "_srr_src=!LIBSCRIPT_ROOT_DIR!"
if "!_srr_src:~-1!"=="\" set "_srr_src=!_srr_src:~0,-1!"

set "_srr_hash_dir=%USERPROFILE%\.cache\libscript\sync_hashes"
if not exist "!_srr_hash_dir!" mkdir "!_srr_hash_dir!" 2>nul
set "_srr_key=runtime_!_srr_target!_!_srr_dest!"
set "_srr_key=!_srr_key:/=_!"
set "_srr_key=!_srr_key:\=_!"
set "_srr_key=!_srr_key::=_!"
set "_srr_key=!_srr_key:@=_!"
set "_srr_hash_file=!_srr_hash_dir!\!_srr_key!.sha256"
set "_srr_cur_hash="
for /f "delims=" %%H in ('call "!THIS_FILE!" compute-hash "!_srr_src!" 2^>nul') do set "_srr_cur_hash=%%H"
set "_srr_bypass=0"
if "!FORCE_REINSTALL!"=="1" set "_srr_bypass=1"
if "!FORCE_REBUILD!"=="1" set "_srr_bypass=1"
if "!FORCE_UPLOAD!"=="1" set "_srr_bypass=1"
if "!_srr_bypass!"=="0" if exist "!_srr_hash_file!" (
    set "_srr_cached="
    for /f "delims=" %%C in ("!_srr_hash_file!") do set "_srr_cached=%%C"
    if "!_srr_cached!"=="!_srr_cur_hash!" (
        ssh !SSH_BASE_OPTS! "!_srr_target!" "[ -x !_srr_dest!/libscript.sh ]" >nul 2>&1
        if not errorlevel 1 (
            echo [REUSE] Remote LibScript runtime !_srr_target!:!_srr_dest! matches local tree hash ^(!_srr_cur_hash!^); skipping sync.
            exit /b 0
        )
    )
)

ssh !SSH_BASE_OPTS! "!_srr_target!" "mkdir -p !_srr_dest!"

where rsync >nul 2>&1
if not errorlevel 1 (
    set "_srr_excl_file=%TEMP%\libscript_srr_excl_%RANDOM%.txt"
    git -C "!_srr_src!" rev-parse --is-inside-work-tree >nul 2>&1
    if not errorlevel 1 (
        git -C "!_srr_src!" ls-files --others -i --exclude-standard --directory > "!_srr_excl_file!" 2>nul
        set "_srr_gi_arg=--exclude-from=!_srr_excl_file!"
    ) else (
        set "_srr_gi_arg=--filter=:- .gitignore"
    )
    rsync -avz --delete --filter="P cache" --filter="P build" --filter="P cmake-build-debug" --filter="P cmake-build-release" --filter="P cmake-build-*" --filter="P target" --filter="P node_modules" --filter="P .venv" --filter="P venv" --filter="P logs" --filter="P tmp" --filter="P tests_tmp" "!_srr_gi_arg!" --exclude=".git" --exclude="cache" --exclude="build" --exclude="cmake-build-debug" --exclude="cmake-build-release" --exclude="cmake-build-*" --exclude="target" --exclude="node_modules" --exclude=".venv" --exclude="venv" --exclude="logs" --exclude="tmp" --exclude="tests_tmp" --exclude=".vagrant" --exclude="*.iso" --exclude="*.img" --exclude="*.qcow2" --exclude="*.vhdx" --exclude="*.vmdk" --exclude="*.msi" --exclude=".DS_Store" -e "ssh !SSH_BASE_OPTS!" "!_srr_src!/" "!_srr_target!:!_srr_dest!/"
    if not errorlevel 1 (
        > "!_srr_hash_file!" echo !_srr_cur_hash!
        exit /b 0
    )
)

where tar >nul 2>&1
if not errorlevel 1 (
    ssh !SSH_BASE_OPTS! "!_srr_target!" "find !_srr_dest! -mindepth 1 \( -name cache -o -name build -o -name cmake-build-debug -o -name cmake-build-release -o -name 'cmake-build-*' -o -name target -o -name node_modules -o -name .venv -o -name venv -o -name logs -o -name tmp -o -name tests_tmp \) -prune -o -type f -exec rm -f {} + 2>/dev/null || true; find !_srr_dest! -mindepth 1 -depth \( -name cache -o -name build -o -name cmake-build-debug -o -name cmake-build-release -o -name 'cmake-build-*' -o -name target -o -name node_modules -o -name .venv -o -name venv -o -name logs -o -name tmp -o -name tests_tmp \) -prune -o -type d -empty -exec rmdir {} + 2>/dev/null || true"
    tar -czf - --exclude=".git" --exclude="cache" --exclude="build" --exclude="cmake-build-debug" --exclude="cmake-build-release" --exclude="cmake-build-*" --exclude="target" --exclude="node_modules" --exclude=".venv" --exclude="venv" --exclude="logs" --exclude="tmp" --exclude="tests_tmp" --exclude=".vagrant" --exclude="*.iso" --exclude="*.img" --exclude="*.qcow2" --exclude="*.vhdx" --exclude="*.vmdk" --exclude="*.msi" --exclude=".DS_Store" -C "!_srr_src!" . | ssh !SSH_BASE_OPTS! "!_srr_target!" "tar -xzf - -C !_srr_dest!"
    if not errorlevel 1 (
        > "!_srr_hash_file!" echo !_srr_cur_hash!
        exit /b 0
    )
    exit /b 1
)

scp !SSH_BASE_OPTS! -r "!_srr_src!\*" "!_srr_target!:!_srr_dest!/"
if not errorlevel 1 (
    > "!_srr_hash_file!" echo !_srr_cur_hash!
    exit /b 0
)
exit /b 1

:: ## libscript_compute_tree_hash
:: Computes a deterministic digest for a local directory on Windows.
:libscript_compute_tree_hash
set "_cth_dir=%~1"
if "!_cth_dir!"=="" set "_cth_dir=."
set "_cth_git=nogit"
for /f "delims=" %%G in ('git -C "!_cth_dir!" rev-parse HEAD 2^>nul') do set "_cth_git=%%G"
set "_cth_dirty=clean"
for /f "delims=" %%D in ('git -C "!_cth_dir!" status --porcelain 2^>nul') do set "_cth_dirty=dirty"
set "_cth_m=nom"
if exist "!_cth_dir!\libscript.json" (
    for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!_cth_dir!\libscript.json" SHA256 2^>nul') do (
        if "!_cth_m!"=="nom" set "_cth_m=%%H"
    )
)
set "_cth_lock_tmp=%TEMP%\libscript_cth_locks_%RANDOM%.txt"
if exist "!_cth_lock_tmp!" del /f /q "!_cth_lock_tmp!" >nul 2>&1
for %%L in ("!_cth_dir!\package.json" "!_cth_dir!\package-lock.json" "!_cth_dir!\pnpm-lock.yaml" "!_cth_dir!\yarn.lock" "!_cth_dir!\requirements.txt" "!_cth_dir!\requirements-prod.txt" "!_cth_dir!\pyproject.toml" "!_cth_dir!\uv.lock" "!_cth_dir!\angular.json" "!_cth_dir!\vite.config.*") do (
    if exist "%%~fL" type "%%~fL" >> "!_cth_lock_tmp!" 2>nul
)
for /d %%S in ("!_cth_dir!\*") do (
    for %%L in ("%%~fS\package.json" "%%~fS\package-lock.json" "%%~fS\pnpm-lock.yaml" "%%~fS\yarn.lock" "%%~fS\requirements*.txt" "%%~fS\pyproject.toml" "%%~fS\uv.lock" "%%~fS\angular.json" "%%~fS\vite.config.*") do (
        if exist "%%~fL" type "%%~fL" >> "!_cth_lock_tmp!" 2>nul
    )
)
set "_cth_locks=nolocks"
if exist "!_cth_lock_tmp!" (
    for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!_cth_lock_tmp!" SHA256 2^>nul') do (
        if "!_cth_locks!"=="nolocks" set "_cth_locks=%%H"
    )
    del /f /q "!_cth_lock_tmp!" >nul 2>&1
)
echo !_cth_git!-!_cth_dirty!-!_cth_m!-!_cth_locks!
exit /b 0

:: ## libscript_scp_to_remote
:: Uploads a local file or directory to a remote host destination on Windows.
:libscript_scp_to_remote
set "_str_src=%~1"
set "_str_target=%~2"
set "_str_dest=%~3"
if "!_str_src!"=="" (
    echo [ERROR] Usage: remote_sync.cmd :libscript_scp_to_remote ^<src^> ^<user@host^> ^<remote_dest^> 1>&2
    exit /b 1
)
if exist "!_str_src!\*" (
    goto :libscript_sync_app_to_remote
)
scp !SSH_BASE_OPTS! -r "!_str_src!" "!_str_target!:!_str_dest!"
exit /b !errorlevel!

:: ## libscript_scp_from_remote
:: Downloads a remote file or directory from a remote host to a local destination on Windows.
:libscript_scp_from_remote
set "_sfr_target=%~1"
set "_sfr_src=%~2"
set "_sfr_dest=%~3"
if "!_sfr_target!"=="" (
    echo [ERROR] Usage: remote_sync.cmd :libscript_scp_from_remote ^<user@host^> ^<remote_src^> ^<local_dest^> 1>&2
    exit /b 1
)
for %%D in ("!_sfr_dest!") do (
    if not "%%~dpD"=="" if not exist "%%~dpD" mkdir "%%~dpD"
)
scp !SSH_BASE_OPTS! -r "!_sfr_target!:!_sfr_src!" "!_sfr_dest!"
exit /b !errorlevel!
