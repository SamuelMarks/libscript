FROM alpine:latest

COPY . /scripts
WORKDIR /scripts

RUN set -x && . ./conf-no-all.env.sh && \
    export JUPYTER_NOTEBOOK_INSTALL=1 && \
    ./install.sh
