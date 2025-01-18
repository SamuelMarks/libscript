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
SET SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD=1
SET SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST="/tmp/serve-actix-diesel-auth-scaffold"

:: ##########################
:: # Database(s) [optional] #
:: ##########################
SET RABBITMQ_VERSION="*"

:: ########################
:: # Server(s) [required] #
:: ########################

:: ##############
:: # WWWROOT(s) #
:: ##############
SET WWWROOT_example_com_COMMAND_FOLDER="_lib\_toolchain\nodejs"
SET WWWROOT_example_com_COMMAND_FOLDER="_lib/_toolchain/nodejs"

