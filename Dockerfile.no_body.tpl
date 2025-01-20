FROM ${image}

ENV LIBSCRIPT_ROOT_DIR='/scripts'
${ENV}

COPY . /scripts
WORKDIR /scripts

${BODY}