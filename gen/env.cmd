SET "LIBSCRIPT_DATA_DIR=%LIBSCRIPT_DATA_DIR:~0,-1%"

:: ###########################
:: # Toolchain(s) [required] #
:: ###########################
SET NODEJS_INSTALL_DIR=1
SET NODEJS_VERSION="lts"

SET PYTHON_INSTALL_DIR=1
SET PYTHON_VERSION="3.10"

SET RUST_INSTALL_DIR=1
SET RUST_VERSION="nightly"

:: ##########################
:: # Database(s) [required] #
:: ##########################
SET POSTGRES_URL=1
SET POSTGRES_USER="rest_user"
SET POSTGRES_PASSWORD="rest_pass"
SET POSTGRES_DB="rest_db"
SET POSTGRES_PASSWORD_FILE=
SET POSTGRES_VERSION=17

SET REDIS_URL=1
SET VALKEY_VERSION="*"

:: ########################
:: # Server(s) [required] #
:: ########################
SET SADAS=1
SET SADAS_COMMANDS="git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold "${SADAS_DEST}""
SET SADAS_COMMAND_FOLDER="_lib/_server/rust"
SET SADAS_DEST="/opt/serve-actix-diesel-auth-scaffold"

:: ##########################
:: # Database(s) [optional] #
:: ##########################
SET AMQP_URL=0
SET RABBITMQ_VERSION="*"

:: ########################
:: # Server(s) [required] #
:: ########################
SET JUPYTERHUB=0

:: ##############
:: # WWWROOT(s) #
:: ##############
SET WWWROOT_example_com_INSTALL=0
SET example_com="./my_symlinked_wwwroot"
SET WWWROOT_example_com_COMMAND_FOLDER="_lib/_toolchain/nodejs"
SET WWWROOT_example_com_COMMANDS="npm i -g @angular/cli &&
npm i &&
ng build --configuration production"

