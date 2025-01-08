FROM ${image}
${ENV}

COPY . /scripts
WORKDIR /scripts

RUN export SCRIPT_NAME='/scripts/tmp/install_gen.sh' && \
    . "${SCRIPT_NAME}"
