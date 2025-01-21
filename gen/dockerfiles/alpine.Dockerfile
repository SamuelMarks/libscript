FROM alpine:latest

###########################
# Toolchain(s) [required] #
###########################
ARG NODEJS_INSTALL_DIR=1
ARG NODEJS_VERSION='lts'

ARG PYTHON_INSTALL_DIR=1
ARG PYTHON_VERSION='3.10'

ARG RUST_INSTALL_DIR=1
ARG RUST_VERSION='nightly'

ARG POSTGRES_URL=1

ARG POSTGRES_USER='rest_user'
ARG POSTGRES_PASSWORD='rest_pass'
ARG POSTGRES_DB='rest_db'
ARG POSTGRES_PASSWORD_FILE
ARG POSTGRES_VERSION=17


ARG REDIS_URL=1
ARG VALKEY_VERSION='*'

ARG SADAS=1

ARG SADAS_COMMANDS_BEFORE='git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold "${SADAS_DEST}"'
ARG SADAS_COMMAND_FOLDER='_lib/_server/rust'
ARG SADAS_DEST='/tmp/serve-actix-diesel-auth-scaffold'

ARG NODEJS_HTTP_SERVER=1

ARG nodejs_http_server_COMMANDS_BEFORE='git_get https://github.com/mohammadhasanii/Node-HTTP3 "${NODEJS_HTTP_SERVER_DEST}"'
ARG nodejs_http_server_COMMAND_FOLDER='_lib/_server/nodejs'
ARG NODEJS_HTTP_SERVER_DEST='/tmp/nodejs-http-server'

ARG PYTHON_SERVER=1

ARG python_server_COMMANDS_BEFORE='git_get https://github.com/digitalocean/sample-python "${PYTHON_SERVER_DEST}" \
uv venv --python 3.12 venv-3-12 \
venv-3-12/bin/python -m ensurepip \
venv-3-12/bin/python -m pip install -r requirements.txt'
ARG python_server_COMMAND_FOLDER='_lib/_server/python'
ARG PYTHON_SERVER_DEST='/tmp/python-server'

ARG AMQP_URL=0
ARG RABBITMQ_VERSION='*'

ARG JUPYTERHUB=0

ARG WWWROOT_example_com_NAME='example.com'
ARG WWWROOT_example_com_VENDOR='nginx'
ARG WWWROOT_example_com_PATH='./my_symlinked_wwwroot'
ARG WWWROOT_example_com_LISTEN=80
ARG WWWROOT_example_com_INSTALL=0

ARG example_com='./my_symlinked_wwwroot'
ARG WWWROOT_example_com_COMMAND_FOLDER='_lib/_toolchain/nodejs'
ARG WWWROOT_example_com_COMMANDS_BEFORE='npm i -g @angular/cli && \
npm i && \
ng build --configuration production'



COPY . /scripts
WORKDIR /scripts

RUN export SCRIPT_NAME='/scripts/install_gen.sh' && \
    . "${SCRIPT_NAME}"
