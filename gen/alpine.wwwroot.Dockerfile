FROM alpine:latest

COPY . /scripts
WORKDIR /scripts

ARG WWWROOT_example_com_INSTALL=0
ARG WWWROOT_example_com_INSTALL_VERSION='0.0.1'

RUN <<-EOF

if [ "${WWWROOT_example_com_INSTALL:-0}" -eq 1 ]; then
  WWWROOT_NAME='example.com'
  WWWROOT_VENDOR='nginx'
  WWWROOT_PATH='./my_symlinked_wwwroot'
  WWWROOT_LISTEN='80'
  if [ "${WWWROOT_VENDOR:-nginx}" = 'nginx' ]; then
    SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_server/nginx/setup.sh'
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
fi
EOF


