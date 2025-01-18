FROM ${image}

ENV SCRIPT_ROOT_DIR='/scripts'
${ENV}

COPY . /scripts
WORKDIR /scripts

${BODY}