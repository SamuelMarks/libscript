FROM ${image}

${ENV}

COPY . /scripts
WORKDIR /scripts

RUN export SCRIPT_NAME='/scripts/install_gen.sh' && \
    . "${SCRIPT_NAME}"
