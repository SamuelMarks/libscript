FROM debian:bookworm-slim

COPY . /scripts
WORKDIR /scripts

RUN set -x && . ./conf-no-all.env.sh && \
    export JUPYTERHUB_INSTALL=1 && \
    ./install.sh
