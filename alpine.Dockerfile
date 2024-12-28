FROM alpine:latest

COPY . /scripts
WORKDIR /scripts

RUN ./install.sh
#   . ./conf-no-all.env.sh && \
