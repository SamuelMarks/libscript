SET "SCRIPT_ROOT_DIR=%~dp0"
SET "SCRIPT_ROOT_DIR=%SCRIPT_ROOT_DIR:~0,-1%"

:: Initialize STACK variable
IF NOT DEFINED STACK (
   SET "STACK=;%~nx0;"
) ELSE (
   SET "STACK=%STACK%%~nx0;"
)

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET "searchVal=;%this_file%;"
IF NOT x!str1:%searchVal%=!"=="x%str1% (
 ECHO [STOP]     processing "%this_file%"
 SET ERRORLEVEL=0
 GOTO end
) ELSE (
 ECHO [CONTINUE] processing "%this_file%"
)

:: ##############################
:: #	Toolchain(s) [required]	#
:: ##############################

IF NOT DEFINED NODEJS_INSTALL_DIR ( SET NODEJS_INSTALL_DIR=1 )
IF "%NODEJS_INSTALL_DIR%"==1 (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_toolchain\nodejs\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      GOTO end
  )
  CALL "%SCRIPT_NAME%"
)

IF NOT DEFINED PYTHON_INSTALL_DIR ( SET PYTHON_INSTALL_DIR=1 )
IF "%PYTHON_INSTALL_DIR%"==1 (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_toolchain\python\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      GOTO end
  )
  CALL "%SCRIPT_NAME%"
)

IF NOT DEFINED RUST_INSTALL_DIR ( SET RUST_INSTALL_DIR=1 )
IF "%RUST_INSTALL_DIR%"==1 (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_toolchain\rust\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      GOTO end
  )
  CALL "%SCRIPT_NAME%"
)

:: ##############################
:: #	Database(s) [required]	#
:: ##############################

IF NOT DEFINED POSTGRES_URL ( SET POSTGRES_URL=1 )
IF "%POSTGRES_URL%"==1 (
  SET POSTGRES_USER="rest_user"
  SET POSTGRES_PASSWORD="rest_pass"
  SET POSTGRES_DB="rest_db"
  SET POSTGRES_PASSWORD_FILE

  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_storage\postgres\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      GOTO end
  )
  CALL "%SCRIPT_NAME%"
)

IF NOT DEFINED REDIS_URL ( SET REDIS_URL=1 )
IF "%REDIS_URL%"==1 (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_storage\valkey\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      GOTO end
  )
  CALL "%SCRIPT_NAME%"
)

:: ##############################
:: #	Server(s) [required]	#
:: ##############################

IF NOT DEFINED SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD ( SET SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD=1 )
IF "%SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD%"==1 (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\app\third_party\serve-actix-diesel-auth-scaffold\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      GOTO end
  )
  CALL "%SCRIPT_NAME%"
)

IF NOT DEFINED JUPYTERHUB ( SET JUPYTERHUB=1 )
IF "%JUPYTERHUB%"==1 (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\app\third_party\jupyterhub\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      GOTO end
  )
  CALL "%SCRIPT_NAME%"
)

:: ##############################
:: #	Database(s) [optional]	#
:: ##############################

IF NOT DEFINED "AMQP_URL" ( SET AMQP_URL=0 )
IF "%AMQP_URL%"==1 (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_storage\rabbitmq\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      GOTO end
  )
  CALL "%SCRIPT_NAME%"
)

:: ##############################
:: #	      WWWROOT(s)      	#
:: ##############################

IF NOT DEFINED "WWWROOT_example_com_INSTALL" ( SET WWWROOT_example_com_INSTALL=0 )
IF "%WWWROOT_example_com_INSTALL%"==1 (
  IF NOT DEFINED WWWROOT_NAME ( SET WWWROOT_NAME="example.com" )
  IF NOT DEFINED WWWROOT_VENDOR ( SET WWWROOT_VENDOR="nginx" )
  IF NOT DEFINED WWWROOT_PATH ( SET WWWROOT_PATH="./my_symlinked_wwwroot" )
  IF NOT DEFINED WWWROOT_LISTEN ( SET WWWROOT_LISTEN="80" )

  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\wwwroot\example_com\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      GOTO end
  )
  CALL "%SCRIPT_NAME%"
)

ENDLOCAL

:end
@%COMSPEC% /C exit %ERRORLEVEL% >nul

