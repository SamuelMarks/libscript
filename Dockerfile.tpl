FROM ${image}

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'
${ENV}

COPY . /scripts
WORKDIR /scripts

RUN export SCRIPT_NAME='/scripts/install_gen.sh' && \
    . "${SCRIPT_NAME}"
