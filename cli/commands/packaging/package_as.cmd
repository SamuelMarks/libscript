@echo off
setlocal EnableDelayedExpansion
set "is_docker="
if /i "%~2"=="docker" set "is_docker=1"
if /i "%~2"=="dockerfile" set "is_docker=1"

if defined is_docker (
    set "base_image=debian:bookworm-slim"
    set "layer_filter="
    set "artifact_type="
    shift
    shift
    
    :docker_parse_flags
    if /i "%~1"=="--artifact" (
        set "artifact_type=%~2"
        if /i "%~2"=="deb" set "base_image=debian:bookworm-slim"
        if /i "%~2"=="rpm" set "base_image=almalinux:9"
        if /i "%~2"=="apk" set "base_image=alpine:latest"
        if /i "%~2"=="txz" set "base_image=freebsd"
        if /i "%~2"=="msi" set "base_image=mcr.microsoft.com/windows/servercore:ltsc2022"
        if /i "%~2"=="exe" set "base_image=mcr.microsoft.com/windows/servercore:ltsc2022"
        shift
        shift
        goto docker_parse_flags
    )
    if /i "%~1"=="-a" (
        set "artifact_type=%~2"
        if /i "%~2"=="deb" set "base_image=debian:bookworm-slim"
        if /i "%~2"=="rpm" set "base_image=almalinux:9"
        if /i "%~2"=="apk" set "base_image=alpine:latest"
        if /i "%~2"=="txz" set "base_image=freebsd"
        if /i "%~2"=="msi" set "base_image=mcr.microsoft.com/windows/servercore:ltsc2022"
        if /i "%~2"=="exe" set "base_image=mcr.microsoft.com/windows/servercore:ltsc2022"
        shift
        shift
        goto docker_parse_flags
    )
    if /i "%~1"=="--base" (
        set "base_image=%~2"
        if /i "%~2"=="debian" set "base_image=debian:bookworm-slim"
    set "layer_filter="
        if /i "%~2"=="alpine" set "base_image=alpine:latest"
        shift
        shift
        goto docker_parse_flags
    )
    if /i "%~1"=="--layer" (
        set "layer_filter=%~2"
        shift
        shift
        goto docker_parse_flags
    )
    if /i "%~1"=="-l" (
        set "layer_filter=%~2"
        shift
        shift
        goto docker_parse_flags
    )
    if /i "%~1"=="--base-image" (
        set "base_image=%~2"
        if /i "%~2"=="debian" set "base_image=debian:bookworm-slim"
    set "layer_filter="
        if /i "%~2"=="alpine" set "base_image=alpine:latest"
        shift
        shift
        goto docker_parse_flags
    )

    echo FROM !base_image!
    echo ARG TARGETOS=windows
    echo ARG TARGETARCH=amd64
    echo ENV LC_ALL=C.UTF-8 LANG=C.UTF-8
    echo ENV LIBSCRIPT_ROOT_DIR="/opt/libscript"
    echo ENV LIBSCRIPT_BUILD_DIR="/opt/libscript_build"
    echo ENV LIBSCRIPT_DATA_DIR="/opt/libscript_data"
    echo ENV LIBSCRIPT_CACHE_DIR="/opt/libscript_cache"
    set "tmp_env_add=%temp%\libscript_env_add.tmp"
    set "tmp_run=%temp%\libscript_run.tmp"
    if exist "!tmp_env_add!" del "!tmp_env_add!"
    if exist "!tmp_run!" del "!tmp_run!"
    
    :docker_loop
    if not "%~1"=="" (
        set "pkg=%~1"
        set "ver=%~2"
        set "override=%~3"
        if "!ver!"=="" set "ver=latest"
        
        set "is_url="
        if not "!override!"=="" (
            echo !override! | findstr /b "http" >nul
            if not errorlevel 1 set "is_url=1"
        )
        
        set "pkg_up=!pkg!"
        for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_") do set "pkg_up=!pkg_up:%%~A!"
        
        echo ENV !pkg_up!_VERSION="!ver!">> "!tmp_env_add!"
        
        if defined is_url (
            echo ENV !pkg_up!_URL="!override!">> "!tmp_env_add!"
            for %%F in ("!override!") do set "filename=%%~nxF"
            if "!artifact_type!"=="" echo ADD ${!pkg_up!_URL} /opt/libscript_cache/!pkg!/!filename!>> "!tmp_env_add!"
            shift
            shift
            shift
        ) else (
            if not "%~2"=="" (
                shift
                shift
            ) else (
                shift
            )
        )
        
        if "!artifact_type!"=="deb" (
            echo RUN apt-get update ^&^& apt-get install -y /opt/libscript/*-!pkg!_*.deb>> "!tmp_run!"
        ) else if "!artifact_type!"=="rpm" (
            echo RUN dnf install -y /opt/libscript/*-!pkg!-*.rpm>> "!tmp_run!"
        ) else if "!artifact_type!"=="apk" (
            echo RUN apk add --allow-untrusted /opt/libscript/*-!pkg!-*.apk>> "!tmp_run!"
        ) else if "!artifact_type!"=="txz" (
            echo RUN pkg install -y /opt/libscript/*-!pkg!*.txz /opt/libscript/*-!pkg!*.pkg 2^>nul^|^|true>> "!tmp_run!"
        ) else if "!artifact_type!"=="msi" (
            echo RUN for %%I in ^(C:\opt\libscript\*-!pkg!-*.msi^) do msiexec /i "%%I" /qn /norestart>> "!tmp_run!"
        ) else if "!artifact_type!"=="exe" (
            echo RUN for %%I in ^(C:\opt\libscript\*-!pkg!-*.exe^) do "%%I" /SILENT /VERYSILENT>> "!tmp_run!"
        ) else (
            echo RUN ./libscript.sh install !pkg! ${!pkg_up!_VERSION}>> "!tmp_run!"
        )
        
        REM Call libscript.sh env to get docker formatted ENV vars, not cmd because we're emitting a linux dockerfile
        set "PREFIX=/opt/libscript/installed/!pkg!"
        for /f "delims=" %%i in ('call "%~dp0libscript.cmd" env !pkg! !ver! --format=docker 2^>nul') do (
            echo %%i | findstr /b /v "ENV STACK=" | findstr /b /v "ENV SCRIPT_NAME=">> "!tmp_run!"
        )
        goto docker_loop
    ) else (
        if exist "libscript.json" (
            jq --version >nul 2>&1
            if not errorlevel 1 (
                call "%~dp0scripts\resolve_stack.cmd" "libscript.json" > "libscript.resolved.json" 2>nul
                for /f "tokens=1,2,3" %%a in (\'jq -r ".selected[] | \"\(.name) \(.version // \\\"latest\\\") \(.override // \\\"\\\")\"" "libscript.resolved.json" 2^>nul\') do (
                    set "pkg_up=%%a"
                    for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_") do set "pkg_up=!pkg_up:%%~A!"
                    
                    if "%%b"=="" (
                        echo ENV !pkg_up!_VERSION="latest">> "!tmp_env_add!"
                    ) else if "%%b"=="null" (
                        echo ENV !pkg_up!_VERSION="latest">> "!tmp_env_add!"
                    ) else (
                        echo ENV !pkg_up!_VERSION="%%b">> "!tmp_env_add!"
                    )
                    
                    if not "%%c"=="" if not "%%c"=="null" (
                        echo ENV !pkg_up!_URL="%%c">> "!tmp_env_add!"
                        for %%F in ("%%c") do set "filename=%%~nxF"
                        if "!artifact_type!"=="" echo ADD ${!pkg_up!_URL} /opt/libscript_cache/%%a/!filename!>> "!tmp_env_add!"
                    )
                    
                    if "!artifact_type!"=="deb" (
                        echo RUN apt-get update ^&^& apt-get install -y /opt/libscript/*-%%a_*.deb>> "!tmp_run!"
                    ) else if "!artifact_type!"=="rpm" (
                        echo RUN dnf install -y /opt/libscript/*-%%a-*.rpm>> "!tmp_run!"
                    ) else if "!artifact_type!"=="apk" (
                        echo RUN apk add --allow-untrusted /opt/libscript/*-%%a-*.apk>> "!tmp_run!"
                    ) else if "!artifact_type!"=="txz" (
                        echo RUN pkg install -y /opt/libscript/*-%%a*.txz /opt/libscript/*-%%a*.pkg 2^>nul^|^|true>> "!tmp_run!"
                    ) else if "!artifact_type!"=="msi" (
                        echo RUN for %%%%I in ^(C:\opt\libscript\*-%%a-*.msi^) do msiexec /i "%%%%I" /qn /norestart>> "!tmp_run!"
                    ) else if "!artifact_type!"=="exe" (
                        echo RUN for %%%%I in ^(C:\opt\libscript\*-%%a-*.exe^) do "%%%%I" /SILENT /VERYSILENT>> "!tmp_run!"
                    ) else (
                        echo RUN ./libscript.sh install %%a ${!pkg_up!_VERSION}>> "!tmp_run!"
                    )
                    
                    set "PREFIX=/opt/libscript/installed/%%a"
                    for /f "delims=" %%i in ('call "%~dp0libscript.cmd" env %%a %%b --format=docker 2^>nul') do (
            echo %%i | findstr /b /v "ENV STACK=" | findstr /b /v "ENV SCRIPT_NAME=">> "!tmp_run!"
                    )
                )
                if exist "!json_file!.resolved.json" del "!json_file!.resolved.json"
            ) else (
                echo RUN ./install_gen.sh>> "!tmp_run!"
            )
        ) else (
                echo RUN ./install_gen.sh>> "!tmp_run!"
        )
    )
    if exist "!tmp_env_add!" type "!tmp_env_add!"
    echo COPY . /opt/libscript
    echo WORKDIR /opt/libscript
    if exist "!tmp_run!" type "!tmp_run!"

    if exist "!tmp_env_add!" del "!tmp_env_add!"
    if exist "!tmp_run!" del "!tmp_run!"
    exit /b 0
) else if /i "%~2"=="docker_compose" (
    set "base_image=debian:bookworm-slim"
    shift
    shift
    :docker_compose_parse_flags
    if /i "%~1"=="--base" (
        set "base_image=%~2"
        if /i "%~2"=="debian" set "base_image=debian:bookworm-slim"
        if /i "%~2"=="alpine" set "base_image=alpine:latest"
        shift
        shift
        goto docker_compose_parse_flags
    )
    if /i "%~1"=="--base-image" (
        set "base_image=%~2"
        if /i "%~2"=="debian" set "base_image=debian:bookworm-slim"
        if /i "%~2"=="alpine" set "base_image=alpine:latest"
        shift
        shift
        goto docker_compose_parse_flags
    )

    echo version: '3.8'
    echo services:
    
    set "prev_pkg="
    
    if not "%~1"=="" (
        :docker_compose_loop
        if not "%~1"=="" (
            set "pkg=%~1"
            set "ver=%~2"
            if "!ver!"=="" set "ver=latest"
            set "override="
            
            call :dc_gen_service "!pkg!" "!ver!" "!override!"
            
            if not "%~2"=="" (
                shift
                shift
            ) else (
                shift
            )
            goto docker_compose_loop
        )
    ) else (
        if exist "libscript.json" (
            jq --version >nul 2>&1
            if not errorlevel 1 (
                call "%~dp0scripts\resolve_stack.cmd" "libscript.json" > "libscript.resolved.json" 2>nul
                for /f "tokens=1,2,3" %%a in (\'jq -r ".selected[] | \"\(.name) \(.version // \\\"latest\\\") \(.override // \\\"\\\")\"" "libscript.resolved.json" 2^>nul\') do (
                    set "pkg=%%a"
                    set "ver=%%b"
                    set "override=%%c"
                    if "!ver!"=="" set "ver=latest"
                    if "!ver!"=="null" set "ver=latest"
                    if "!override!"=="null" set "override="
                    call :dc_gen_service "!pkg!" "!ver!" "!override!"
                )
                if exist "libscript.resolved.json" del "libscript.resolved.json"
            )
        )
    )
    exit /b 0
) else if /i "%~2"=="TUI" (
    echo @echo off
    echo setlocal EnableDelayedExpansion
    echo echo Creating interactive component selection...
    
    echo set "ps_script=$items = @("
    
    if not "%~3"=="" (
        shift
        shift
        :tui_loop
        if not "%~1"=="" (
            set "pkg=%~1"
            set "ver=%~2"
            if "!ver!"=="" set "ver=latest"
            echo set "ps_script=^!ps_script^![pscustomobject]@{Name='!pkg!';Version='!ver!'},"
            if not "%~2"=="" (
                shift
                shift
            ) else (
                shift
            )
            goto tui_loop
        )
    ) else (
        if exist "libscript.json" (
            jq --version >nul 2>&1
            if not errorlevel 1 (
                call "%~dp0scripts\resolve_stack.cmd" "libscript.json" > "libscript.resolved.json" 2>nul
                for /f "tokens=1,2" %%a in (\'jq -r ".selected[] | \"\(.name) \(.version // \\\"latest\\\")\"" "libscript.resolved.json" 2^>nul\') do (
                    echo set "ps_script=^!ps_script^![pscustomobject]@{Name='%%a';Version='%%b'},"
                )
                if exist "libscript.resolved.json" del "libscript.resolved.json"
            )
        ) else (
            for /f "delims=" %%f in ('dir /s /b /a:-d "%SCRIPT_DIR%\cli.cmd" 2^>nul') do (
                set "dir_path=%%~dpf"
                set "dir_path=^!dir_path:~0,-1^!"
                if exist "^!dir_path^!\vars.schema.json" (
                    set "rel_dir=^!dir_path:%SCRIPT_DIR%\=^!"
                    if "^!rel_dir^!" neq "" (
                        echo set "ps_script=^!ps_script^![pscustomobject]@{Name='^!rel_dir^!';Version='latest'},"
                    )
                )
            )
        )
    )
    
    echo set "ps_script=^!ps_script:~0,-1^!); $selected = $items | Out-GridView -Title 'LibScript Stack Builder - Select components' -PassThru; foreach ($s in $selected) { Write-Output \"$($s.Name) $($s.Version)\" }"
    echo set "items="
    echo set "tmp_sel=%%temp%%\libscript_tui_sel.txt"
    echo powershell -Command "^!ps_script^!" ^> "^!tmp_sel^!"
    echo for /f "usebackq tokens=1,2" %%%%a in ("^!tmp_sel^!") do ^(
    echo     if not "%%%%a"=="" set "items=^!items^! %%%%a %%%%b"
    echo ^)
    echo if "^!items^!"=="" exit /b 0
    echo echo.
    echo echo What would you like to produce?
    echo echo 1. Install locally now
    echo echo 2. Dockerfile
    echo echo 3. Dockerfiles + docker-compose
    echo echo 4. .msi installer
    echo echo 5. .exe (InnoSetup)
    echo echo 6. .exe (NSIS)
    echo echo 7. macOS .pkg installer
    echo echo 8. macOS .dmg installer
    echo echo 9. .deb package
    echo echo 0. .rpm package
    echo choice /c 1234567890 /n /m "Select option [1-0]:"
    echo set "act="
    echo if errorlevel 10 set act=rpm
    echo if errorlevel 9 set act=deb
    echo if errorlevel 8 set act=dmg
    echo if errorlevel 7 set act=pkg
    echo if errorlevel 6 set act=nsis
    echo if errorlevel 5 set act=innosetup
    echo if errorlevel 4 set act=msi
    echo if errorlevel 3 set act=docker_compose
    echo if errorlevel 2 if not errorlevel 3 set act=docker
    echo if errorlevel 1 if not errorlevel 2 set act=install
    echo echo.
    echo set "extra_args="
    echo choice /c YN /m "Enable --offline mode?"
    echo if errorlevel 1 if not errorlevel 2 set extra_args=--offline
    echo set "os_script=$os_list = @('windows','dos','linux','macos','bsd'); $selected = $os_list | Out-GridView -Title 'LibScript Stack Builder - Select OS Targets' -PassThru; foreach ($s in $selected) { Write-Output $s }"
    echo set "tmp_os=%%temp%%\libscript_tui_os.txt"
    echo powershell -Command "^!os_script^!" ^> "^!tmp_os^!"
    echo for /f "usebackq" %%%%a in ("^!tmp_os^!") do set "extra_args=^!extra_args^! --os-%%%%a"
    echo if exist "^!tmp_os^!" del "^!tmp_os^!"
    echo echo.
    echo if "^!act^!"=="install" ^(
    echo     for /f "usebackq tokens=1,2" %%%%a in ("^!tmp_sel^!") do call "%%~dp0libscript.cmd" install "%%%%a" "%%%%b"
    echo ^) else ^(
    echo     call "%%~dp0libscript.cmd" package_as "^!act^!" ^!items^! ^!extra_args^!
    echo ^)
    echo if exist "^!tmp_sel^!" del "^!tmp_sel^!"
    exit /b 0
) else if /i "%~2"=="msi" (
    goto install_gen_common
) else if /i "%~2"=="innosetup" (
    goto install_gen_common
) else if /i "%~2"=="nsis" (
    goto install_gen_common
) else if /i "%~2"=="pkg" (
    goto install_gen_common
) else if /i "%~2"=="dmg" (
    goto install_gen_common
) else (
    echo Error: Unsupported package format '%~2'. 1^>&2
    exit /b 1
)
exit /b 0

