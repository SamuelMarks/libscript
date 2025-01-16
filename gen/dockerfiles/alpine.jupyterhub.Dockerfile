FROM alpine:latest

ENV SCRIPT_ROOT_DIR='/scripts'

COPY . /scripts
WORKDIR /scripts

ARG JUPYTERHUB=1
ARG JupyterHub_VERSION='*'

RUN <<-EOF

if [ "${JUPYTERHUB:-1}" -eq 1 ]; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/app/third_party/jupyterhub/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

EOF


