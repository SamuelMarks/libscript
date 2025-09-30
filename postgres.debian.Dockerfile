ARG IMAGE_BASE='debian'
ARG IMAGE_TAG='stable-slim'
FROM ${IMAGE_BASE}:${IMAGE_TAG}

ENV LC_ALL='C.UTF-8' LANG='C.UTF-8'
ENV RUNLEVEL=1

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'

ARG POSTGRES_URL=1
ARG POSTGRES_USER='rest_user'
ARG POSTGRES_PASSWORD='rest_pass'
ARG POSTGRES_HOST='localhost'
ARG POSTGRES_DB='rest_db'
ARG POSTGRES_PASSWORD_FILE='null'
ARG POSTGRES_VERSION=18

COPY . /scripts
WORKDIR /scripts

RUN <<-EOF
apt-get -qq update
apt-get -qq install ca-certificates procps
if [ "${POSTGRES_URL}" -eq 1 ]; then
  export SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_storage/postgres/setup.sh'
  . "${SCRIPT_NAME}"
fi
rm -rf /var/lib/apt/lists/*
EOF

CMD "${LIBSCRIPT_ROOT_DIR}"'/_lib/_storage/postgres/test.sh'

ENTRYPOINT ["/bin/sh"]
