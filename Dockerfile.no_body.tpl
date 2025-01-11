FROM ${image}

##### <ENV> #####

${ENV}

##### </ENV> #####

COPY . /scripts
WORKDIR /scripts

##### <BODY> #####

${BODY}

##### </BODY> #####
