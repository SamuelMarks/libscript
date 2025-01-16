FROM debian:bookworm-slim

ENV SCRIPT_ROOT_DIR='/scripts'

COPY . /scripts
WORKDIR /scripts

ARG PYTHON_INSTALL_DIR=1
ARG PYTHON_VERSION='3.10'

RUN <<-EOF

if [ "${PYTHON_INSTALL_DIR:-0}" -eq 1 ]; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_toolchain/python/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

EOF


