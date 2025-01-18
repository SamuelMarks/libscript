FROM debian:bookworm-slim

ENV SCRIPT_ROOT_DIR='/scripts'


COPY . /scripts
WORKDIR /scripts

