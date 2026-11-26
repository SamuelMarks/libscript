# ## Overview
# Configuration and definition file for base.alpine.Dockerfile.
#
# ## Usage
# Processed automatically during build or runtime.

FROM alpine:latest

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'

COPY . /scripts
WORKDIR /scripts

RUN export SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/docker/conf_no_all.env.sh' && \
    . "${SCRIPT_NAME}" && \
    export JUPYTERHUB_INSTALL=1 && \
    export SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/install.sh' && \
    . "${SCRIPT_NAME}"
