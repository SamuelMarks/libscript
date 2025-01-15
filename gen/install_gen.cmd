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
 echo [STOP]     processing "%this_file%"
 SET ERRORLEVEL=0
 goto end
) else (
 echo [CONTINUE] processing "%this_file%"
)

:: ##############################
:: #	Toolchain(s) [required]	#
:: ##############################

IF "%NODEJS_INSTALL_DIR%"=="1" (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_toolchain\nodejs\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      goto end
  )
  CALL "%SCRIPT_NAME%"
)

IF "%PYTHON_INSTALL_DIR%"=="1" (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_toolchain\python\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      goto end
  )
  CALL "%SCRIPT_NAME%"
)

IF "%RUST_INSTALL_DIR%"=="1" (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_toolchain\rust\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      goto end
  )
  CALL "%SCRIPT_NAME%"
)

:: ##############################
:: #	Database(s) [required]	#
:: ##############################

IF "%POSTGRES_URL%"=="1" (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_storage\postgres\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      goto end
  )
  CALL "%SCRIPT_NAME%"
)

IF "%REDIS_URL%"=="1" (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_storage\valkey\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      goto end
  )
  CALL "%SCRIPT_NAME%"
)

:: ##############################
:: #	Server(s) [required]	#
:: ##############################

IF "%SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD%"=="1" (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\app\third_party\serve-actix-diesel-auth-scaffold\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      goto end
  )
  CALL "%SCRIPT_NAME%"
)

IF "%JUPYTERHUB%"=="1" (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\app\third_party\jupyterhub\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      goto end
  )
  CALL "%SCRIPT_NAME%"
)

:: ##############################
:: #	Database(s) [required]	#
:: ##############################

IF "%AMQP_URL%"=="1" (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\_lib\_storage\rabbitmq\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      goto end
  )
  CALL "%SCRIPT_NAME%"
)

:: ##############################
:: #	      WWWROOT(s)      	#
:: ##############################

IF "%WWWROOT_example_com_INSTALL%"=="1" (
  SET "SCRIPT_NAME=%SCRIPT_ROOT_DIR%\wwwroot\example_com\setup.cmd"
      IF NOT EXIST "%SCRIPT_NAME%" (
      >&2 ECHO File not found "%SCRIPT_NAME%"
      SET ERRORLEVEL=2
      goto end
  )
  CALL "%SCRIPT_NAME%"
)

ENDLOCAL

:end
@%COMSPEC% /C exit %ERRORLEVEL% >nul

