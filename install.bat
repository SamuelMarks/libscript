@echo on

SET "SCRIPT_ROOT_DIR=%~dp0"
SET "SCRIPT_ROOT_DIR=%SCRIPT_ROOT_DIR:~0,-1%"

:: Initialize STACK variable
IF NOT DEFINED STACK (
    SET "STACK=;%~nx0;"
) ELSE (
    SET "STACK=%STACK%%~nx0;"
)

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET this_file=%~nx0
SET "searchVal=;%this_file%;"
IF NOT x!str1:%searchVal%=!"=="x%str1% (
  echo [STOP]     processing "%this_file%"
  SET ERRORLEVEL=0
  goto end
) else (
  echo [CONTINUE] processing "%this_file%"
)

:: ------------------------------------------------------------------------------
::                             Toolchains [Required]
:: ------------------------------------------------------------------------------

IF "%NODEJS_INSTALL_DIR%"=="1" (
    SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_toolchain\nodejs\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup Node.js toolchain, as file not found "%SCRIPT_NAME%"
        SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

IF "%PYTHON_INSTALL_DIR%"=="1" (
    SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_toolchain\python\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup Python toolchain, as file not found "%SCRIPT_NAME%"
        SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

IF "%RUST_INSTALL_DIR%"=="1" (
    SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_toolchain\rust\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup Rust toolchain, as file not found "%SCRIPT_NAME%"
        SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

:: ------------------------------------------------------------------------------
::                           Databases [Required]
:: ------------------------------------------------------------------------------

IF "%POSTGRES_URL%"=="1" (
    SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_storage\postgres\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup PostgreSQL, as file not found "%SCRIPT_NAME%"
        SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

:: Check and set up Redis
IF "%REDIS_URL%"=="1" (
    SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_storage\valkey\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup Valkey, as file not found "%SCRIPT_NAME%"
        SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

:: ------------------------------------------------------------------------------
::                             Servers [Required]
:: ------------------------------------------------------------------------------

IF "%SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD%"=="1" (
    SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\app\third_party\serve-actix-diesel-auth-scaffold\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup serve-actix-diesel-auth-scaffold, as file not found "%SCRIPT_NAME%"
        SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

IF "%JUPYTERHUB%"=="1" (
    SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\app\third_party\jupyterhub\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup JupyterHub, as file not found "%SCRIPT_NAME%"
        SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

:: ------------------------------------------------------------------------------
::                           Databases [Optional]
:: ------------------------------------------------------------------------------

IF "%AMQP_URL%"=="1" (
    SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_storage\rabbitmq\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup RabbitMQ, as file not found "%SCRIPT_NAME%"
        SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

:: ------------------------------------------------------------------------------
::                            WWWroot(s)
:: ------------------------------------------------------------------------------

:: Check and set up WWW root for example.com
IF "%WWWROOT_example_com_INSTALL%"=="1" (
    :: Set default values if variables are not defined
    IF NOT DEFINED WWWROOT_NAME SET "WWWROOT_NAME=example.com"
    IF NOT DEFINED WWWROOT_VENDOR SET "WWWROOT_VENDOR=nginx"
    IF NOT DEFINED WWWROOT_PATH SET "WWWROOT_PATH=.\my_symlinked_wwwroot"
    IF NOT DEFINED WWWROOT_LISTEN SET "WWWROOT_LISTEN=80"
    IF NOT DEFINED WWWROOT_HTTPS_PROVIDER SET "WWWROOT_HTTPS_PROVIDER=letsencrypt"

    ECHO Setting up WWW root for "%WWWROOT_NAME%" with vendor "%WWWROOT_VENDOR%"

    :: Check if the vendor is nginx
    IF /I "%WWWROOT_VENDOR%"=="nginx" (
        SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_server\nginx\setup.cmd"
        IF NOT EXIST "%SCRIPT_NAME%" (
            >&2 ECHO Unable to setup NGINX, as file not found "%SCRIPT_NAME%"
            SET ERRORLEVEL=2
            goto end
        )
        CALL "%SCRIPT_NAME%"
    )
)

ENDLOCAL

:end
@%COMSPEC% /C exit %ERRORLEVEL% >nul
