FROM ${image}
${ENV}

COPY . /scripts
WORKDIR /scripts

${BODY}
