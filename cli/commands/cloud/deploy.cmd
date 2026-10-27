@echo off
:: # deploy.cmd
::
:: ## Overview
:: Git-driven deployment workflow engine (`libscript deploy`) on Windows.
:: Supports cloning or updating a Git repository, deploying applications locally
:: via `libscript.json` or remotely via SSH (`--host`) or cloud providers (`--provider`),
:: and installing Git `post-receive` hooks (`--install-hook`).
::
:: ## Usage
:: libscript.cmd deploy [<git_repo_or_path>] [--branch <ref>] [--host <user@host>] [--provider <cloud>] [--domain <domain>] [--install-hook <bare_repo_dir>]

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

if /i "%~1"=="deploy" shift

set "REPO_SOURCE=."
set "GIT_REF="
set "TARGET_HOST="
set "TARGET_DOMAIN=localhost"
set "CLOUD_PROVIDER="
set "HOOK_DIR="
set "DRY_RUN_MODE=0"
if /i "%DRY_RUN%"=="true" set "DRY_RUN_MODE=1"
if "%DRY_RUN%"=="1" set "DRY_RUN_MODE=1"

:: ## parse_args
:: Parses CLI flags for git-driven deployments.
:parse_args
if "%~1"=="" goto :args_done
set "_A=%~1"
if /i "!_A!"=="--help" goto :show_deploy_help
if /i "!_A!"=="-h" goto :show_deploy_help
if /i "!_A!"=="/?" goto :show_deploy_help
if /i "!_A!"=="--dry-run" (
    set "DRY_RUN_MODE=1"
    set "DRY_RUN=true"
    shift
    goto :parse_args
)
if /i "!_A:~0,7!"=="--repo=" (
    set "REPO_SOURCE=!_A:~7!"
    shift
    goto :parse_args
)
if /i "!_A!"=="--repo" (
    set "REPO_SOURCE=%~2"
    shift
    shift
    goto :parse_args
)
if /i "!_A:~0,9!"=="--branch=" (
    set "GIT_REF=!_A:~9!"
    shift
    goto :parse_args
)
if /i "!_A!"=="--branch" (
    set "GIT_REF=%~2"
    shift
    shift
    goto :parse_args
)
if /i "!_A:~0,6!"=="--ref=" (
    set "GIT_REF=!_A:~6!"
    shift
    goto :parse_args
)
if /i "!_A!"=="--ref" (
    set "GIT_REF=%~2"
    shift
    shift
    goto :parse_args
)
if /i "!_A:~0,7!"=="--host=" (
    set "TARGET_HOST=!_A:~7!"
    shift
    goto :parse_args
)
if /i "!_A!"=="--host" (
    set "TARGET_HOST=%~2"
    shift
    shift
    goto :parse_args
)
if /i "!_A:~0,9!"=="--domain=" (
    set "TARGET_DOMAIN=!_A:~9!"
    shift
    goto :parse_args
)
if /i "!_A!"=="--domain" (
    set "TARGET_DOMAIN=%~2"
    shift
    shift
    goto :parse_args
)
if /i "!_A:~0,11!"=="--provider=" (
    set "CLOUD_PROVIDER=!_A:~11!"
    shift
    goto :parse_args
)
if /i "!_A!"=="--provider" (
    set "CLOUD_PROVIDER=%~2"
    shift
    shift
    goto :parse_args
)
if /i "!_A:~0,15!"=="--install-hook=" (
    set "HOOK_DIR=!_A:~15!"
    shift
    goto :parse_args
)
if /i "!_A!"=="--install-hook" (
    set "HOOK_DIR=%~2"
    shift
    shift
    goto :parse_args
)
if "!REPO_SOURCE!"=="." (
    set "REPO_SOURCE=%~1"
)
shift
goto :parse_args

:: ## show_deploy_help
:: Displays usage instructions for the Git-driven deployment workflow.
:show_deploy_help
echo LibScript Git-Driven Deployment Workflow (libscript deploy)
echo Usage: libscript.cmd deploy [repo_url_or_path] [options]
echo.
echo Options:
echo   --repo ^<url^|path^>         Git repository URL or local directory (default: .)
echo   --branch ^<ref^>            Git branch, tag, or commit to checkout (default: main)
echo   --host ^<user@host^>        Deploy over SSH to a remote host via deploy-remote
echo   --domain ^<domain^>         Target domain for routing when deploying to a host
echo   --provider ^<cloud^>        Provision and deploy to a cloud provider
echo   --install-hook ^<dir^>      Install a Git post-receive push-to-deploy hook into ^<dir^>
echo   --dry-run                 Print planned Git deployment actions without mutating state
exit /b 0

:: ## args_done
:: Executes the git-driven deployment workflow after parsing flags.
:args_done
if not "!HOOK_DIR!"=="" (
    call :install_git_hook "!HOOK_DIR!"
    exit /b !ERRORLEVEL!
)

if not "!CLOUD_PROVIDER!"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\cloud\core\deploy_cloud.cmd" --provider "!CLOUD_PROVIDER!" "!REPO_SOURCE!"
    exit /b !ERRORLEVEL!
)

set "WORK_DIR=!REPO_SOURCE!"
set "_IS_REMOTE_GIT=0"
if /i "!REPO_SOURCE:~0,7!"=="http://" set "_IS_REMOTE_GIT=1"
if /i "!REPO_SOURCE:~0,8!"=="https://" set "_IS_REMOTE_GIT=1"
if /i "!REPO_SOURCE:~0,4!"=="git@" set "_IS_REMOTE_GIT=1"
if /i "!REPO_SOURCE:~0,6!"=="ssh://" set "_IS_REMOTE_GIT=1"
if /i "!REPO_SOURCE:~-4!"==".git" set "_IS_REMOTE_GIT=1"

if "!_IS_REMOTE_GIT!"=="1" (
    for %%N in ("!REPO_SOURCE:/=\!") do set "APP_SLUG=%%~nN"
    if "!APP_SLUG!"=="" set "APP_SLUG=app"
    set "_DEPLOY_BASE=%USERPROFILE%\.libscript\deployments"
    if defined LIBSCRIPT_HOME set "_DEPLOY_BASE=!LIBSCRIPT_HOME!\deployments"
    set "WORK_DIR=!_DEPLOY_BASE!\!APP_SLUG!"
    if "!DRY_RUN_MODE!"=="1" (
        set "_REF_DISP=!GIT_REF!"
        if "!_REF_DISP!"=="" set "_REF_DISP=default"
        echo [DRY_RUN] Would clone/update !REPO_SOURCE! into !WORK_DIR! ^(ref: !_REF_DISP!^)
    ) else (
        if not exist "!_DEPLOY_BASE!" mkdir "!_DEPLOY_BASE!"
        if exist "!WORK_DIR!\.git" (
            git -C "!WORK_DIR!" fetch --all --prune
        ) else (
            git clone "!REPO_SOURCE!" "!WORK_DIR!"
        )
        if not "!GIT_REF!"=="" (
            git -C "!WORK_DIR!" checkout "!GIT_REF!"
            git -C "!WORK_DIR!" pull --ff-only origin "!GIT_REF!" 2>nul
        )
    )
) else (
    if exist "!WORK_DIR!\.git" (
        if not "!GIT_REF!"=="" (
            if "!DRY_RUN_MODE!"=="1" (
                echo [DRY_RUN] Would checkout !GIT_REF! in !WORK_DIR!
            ) else (
                git -C "!WORK_DIR!" checkout "!GIT_REF!" 2>nul
            )
        )
    )
)

set "COMMIT_SHA=unknown"
if exist "!WORK_DIR!\.git" (
    for /f "delims=" %%H in ('git -C "!WORK_DIR!" rev-parse --short HEAD 2^>nul') do set "COMMIT_SHA=%%H"
)

echo [DEPLOY] Deploying !WORK_DIR! ^(commit: !COMMIT_SHA!^)

if not "!TARGET_HOST!"=="" (
    if "!DRY_RUN_MODE!"=="1" (
        echo [DRY_RUN] Would execute deploy_remote.cmd !TARGET_HOST! --app !WORK_DIR!@!TARGET_DOMAIN!
        exit /b 0
    )
    call "!LIBSCRIPT_ROOT_DIR!\_lib\cloud\core\deploy_remote.cmd" "!TARGET_HOST!" --app "!WORK_DIR!@!TARGET_DOMAIN!"
    exit /b !ERRORLEVEL!
)

if "!DRY_RUN_MODE!"=="1" (
    echo [DRY_RUN] Local Git-driven deployment validated for !WORK_DIR! ^(commit: !COMMIT_SHA!^)
    exit /b 0
)

if exist "!WORK_DIR!\libscript.json" (
    pushd "!WORK_DIR!"
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install-deps libscript.json
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" start libscript.json
    popd
)

echo [OK] Deployment of !WORK_DIR! ^(commit: !COMMIT_SHA!^) complete.
exit /b 0

:: ## install_git_hook
:: Installs a post-receive hook into the target repository hooks directory.
:install_git_hook
set "_H_REPO=%~1"
set "_H_PATH=!_H_REPO!\hooks"
if exist "!_H_REPO!\.git\hooks" set "_H_PATH=!_H_REPO!\.git\hooks"
if not exist "!_H_PATH!" mkdir "!_H_PATH!"
(
    echo @echo off
    echo for /f "tokens=1,2,3" %%%%A in ^('more'^) do ^(
    echo   set "refname=%%%%C"
    echo   call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" deploy "!_H_REPO!" --branch "%%%%~nxC"
    echo ^)
) > "!_H_PATH!\post-receive.cmd"
(
    echo #!/bin/sh
    echo set -feu
    echo while read -r oldrev newrev refname; do
    echo   branch="${refname#refs/heads/}"
    echo   if command -v cmd.exe ^>/dev/null 2^>^&1; then
    echo     cmd.exe /c "\"!LIBSCRIPT_ROOT_DIR!\libscript.cmd\" deploy \"!_H_REPO!\" --branch \"$branch\""
    echo   else
    echo     "!LIBSCRIPT_ROOT_DIR!/libscript.sh" deploy "!_H_REPO!" --branch "$branch"
    echo   fi
    echo done
) > "!_H_PATH!\post-receive"
echo [OK] Installed Git post-receive deployment hook at !_H_PATH!\post-receive
exit /b 0
