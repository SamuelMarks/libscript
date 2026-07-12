FROM ${image}

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'
${ENV}

COPY . /scripts
WORKDIR /scripts

RUN export SCRIPT_NAME='/scripts/install_gen.sh' && \
    . "${SCRIPT_NAME}"
