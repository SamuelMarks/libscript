FROM alpine:latest

ENV SCRIPT_ROOT_DIR='/scripts'


COPY . /scripts
WORKDIR /scripts

