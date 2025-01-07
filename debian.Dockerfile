FROM debian:bookworm-slim

COPY . /scripts
WORKDIR /scripts

RUN . ./conf-no-all.env.sh && \
    export JUPYTERHUB_INSTALL=1 && \
    export SCRIPT_NAME="$(pwd)"'/install.sh' && \
    . "${SCRIPT_NAME}"
