FROM debian:bookworm-slim

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'

COPY . /scripts
WORKDIR /scripts

RUN . ./conf-no-all.env.sh && \
    export JUPYTERHUB_INSTALL=1 && \
    export SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/install.sh' && \
    . "${SCRIPT_NAME}"
