FROM debian:bookworm-slim

COPY . /scripts
WORKDIR /scripts

ENV FOO="bar \
can"

RUN . ./conf-no-all.env.sh && \
    export JUPYTERHUB_INSTALL=1 && \
    export SCRIPT_NAME="$(pwd)"'/install.sh' && \
    . "${SCRIPT_NAME}"
