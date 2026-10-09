#!/bin/sh
# ## Overview
# Orchestrates the Open edX Test Plan as defined in TEST_OPENEDX_PLAN.md.
# This script is idempotent and resolves paths using the standard `THIS_FILE=` dance.
#
# ## Usage
# ./tests/test_openedx_plan.sh [-o target_os] [step]
# Examples:
#   ./tests/test_openedx_plan.sh 0            # Run Step 0 on debian-13
#   ./tests/test_openedx_plan.sh -o macos-14-arm64 1  # Run Step 1 on macos

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

TARGET_OS="debian-13"
STEP="0"

while [ $# -gt 0 ]; do
  case "$1" in
    -o|--os) TARGET_OS="$2"; shift 2 ;;
    -o=*) TARGET_OS="${1#*=}"; shift 1 ;;
    [0-9]) STEP="$1"; shift 1 ;;
    *) printf "[ERROR] Unknown option %s\n" "$1" >&2; exit 1 ;;
  esac
done

VAGRANT_DIR="${LIBSCRIPT_ROOT_DIR}/vagrant/${TARGET_OS}"
export LIBSCRIPT_TEST_TARGET="openedx"

# ## run_step_0
# Executes Step 0 of the Open edX test plan: Provision local Vagrant machine
# and run basic sanity checks (SSH accessibility).
run_step_0() {
  printf '=== Step 0: Test locally on Vagrant (%s) ===\n' "${TARGET_OS}"
  
  if [ ! -d "${VAGRANT_DIR}" ]; then
    printf '[ERROR] Vagrant directory %s not found.\n' "${VAGRANT_DIR}" >&2
    exit 1
  fi
  
  cd "${VAGRANT_DIR}"
  
  printf '[INFO] Bringing up Vagrant machine (%s) without provisioner...\n' "${TARGET_OS}"
  # Idempotent: vagrant up is safe to run if the machine is already running
  if ! vagrant status | grep -q "running ("; then
    vagrant up --no-provision || { printf '[ERROR] Failed to bring up Vagrant machine\n' >&2; exit 1; }
  else
    printf '[INFO] Vagrant machine is already running.\n'
  fi
  
  printf '[INFO] Running basic sanity checks (SSH)...\n'
  if vagrant ssh -c "hostname"; then
    printf '[PASS] Vagrant machine is provisioned and accessible.\n'
  else
    printf '[ERROR] Failed to SSH into the Vagrant machine.\n' >&2
    exit 1
  fi
}

# ## run_step_1
# Executes Step 1 of the Open edX test plan: Rsync libscript over and install Open edX.
run_step_1() {
  printf '=== Step 1: Install Open edX via SSH (%s) ===\n' "${TARGET_OS}"
  
  cd "${VAGRANT_DIR}"
  
  printf '[INFO] Syncing libscript payload to target machine via Vagrant rsync...\n'
  vagrant rsync || { printf '[ERROR] Failed to rsync libscript payload.\n' >&2; exit 1; }
  
  printf '[INFO] Executing Open edX installation script on target machine...\n'
  case "${TARGET_OS}" in
    windows-*)
      vagrant ssh -c 'cmd.exe /c "C:\libscript\libscript.cmd install openedx"' || {
        printf '[ERROR] Installation failed.\n' >&2; exit 1;
      }
      ;;
    *)
      vagrant ssh -c "sudo /opt/repos/libscript/libscript.sh install openedx" || {
        printf '[ERROR] Installation failed.\n' >&2; exit 1;
      }
      ;;
  esac
  printf '[PASS] Installation complete.\n'
}

# ## run_step_2
# Executes Step 2 of the Open edX test plan: Show status & Component-Level Debugging.
run_step_2() {
  printf '=== Step 2: Show status & Component-Level Debugging (%s) ===\n' "${TARGET_OS}"
  
  cd "${VAGRANT_DIR}"
  
  case "${TARGET_OS}" in
    windows-*)
      printf '[INFO] Checking Toolchains (Python & Node.js)...\n'
      vagrant ssh -c 'powershell -Command "python --version; node --version"' || true

      printf '[INFO] Checking Databases (MongoDB & MySQL)...\n'
      vagrant ssh -c 'cmd.exe /c "call C:\libscript\_lib\databases\mongodb\status.cmd & call C:\libscript\_lib\databases\mysql\status.cmd"' || true

      printf '[INFO] Checking Message Brokers & Caching (RabbitMQ & Redis)...\n'
      vagrant ssh -c 'cmd.exe /c "call C:\libscript\_lib\message-brokers\rabbitmq\status.cmd & call C:\libscript\_lib\caches\redis\status.cmd & call C:\libscript\_lib\caches\memcached\status.cmd"' || true

      printf '[INFO] Checking Application Services (LMS & CMS)...\n'
      vagrant ssh -c 'cmd.exe /c "call C:\libscript\_lib\web-apps\openedx\cli.cmd status"' || true

      printf '[INFO] Checking General System Health...\n'
      vagrant ssh -c 'powershell -Command "Get-PSDrive -PSProvider FileSystem; hostname"' || true
      ;;
    *)
      printf '[INFO] Checking Toolchains (Python & Node.js)...\n'
      vagrant ssh -c "python3 --version && node --version || true"
      
      printf '[INFO] Checking Databases (MongoDB & MySQL)...\n'
      vagrant ssh -c "sudo /opt/repos/libscript/_lib/databases/mongodb/status.sh || true"
      vagrant ssh -c "sudo /opt/repos/libscript/_lib/databases/mysql/status.sh || true"

      printf '[INFO] Checking Message Brokers & Caching (RabbitMQ & Redis)...\n'
      vagrant ssh -c "sudo /opt/repos/libscript/_lib/message-brokers/rabbitmq/status.sh || true"
      vagrant ssh -c "sudo /opt/repos/libscript/_lib/caches/redis/status.sh || true"
      vagrant ssh -c "sudo /opt/repos/libscript/_lib/caches/memcached/status.sh || true"

      printf '[INFO] Checking Application Services (LMS & CMS)...\n'
      vagrant ssh -c "sudo /opt/repos/libscript/_lib/web-apps/openedx/cli.sh status || sudo systemctl status openedx-lms || sudo rc-service openedx-lms status || sudo service openedx-lms status || true"
      
      printf '[INFO] Checking General System Health...\n'
      vagrant ssh -c "df -h && free -m && uptime || true"
      ;;
  esac
  
  printf '[PASS] Component debugging status checks completed.\n'
}

# ## run_step_3
# Executes Step 3 of the Open edX test plan: Show logs.
run_step_3() {
  printf '=== Step 3: Show logs (%s) ===\n' "${TARGET_OS}"
  
  cd "${VAGRANT_DIR}"
  
  case "${TARGET_OS}" in
    windows-*)
      printf '[INFO] Checking Databases (MongoDB & MySQL)...\n'
      vagrant ssh -c 'cmd.exe /c "call C:\libscript\_lib\databases\mongodb\logs.cmd & call C:\libscript\_lib\databases\mysql\logs.cmd"' || true

      printf '[INFO] Checking Message Brokers & Caching (RabbitMQ & Redis)...\n'
      vagrant ssh -c 'cmd.exe /c "call C:\libscript\_lib\message-brokers\rabbitmq\logs.cmd & call C:\libscript\_lib\caches\redis\logs.cmd & call C:\libscript\_lib\caches\memcached\logs.cmd"' || true

      printf '[INFO] Checking Application Services (LMS & CMS)...\n'
      vagrant ssh -c 'cmd.exe /c "call C:\libscript\_lib\web-apps\openedx\logs.cmd"' || true
      ;;
    *)
      printf '[INFO] Checking Databases (MongoDB & MySQL)...\n'
      vagrant ssh -c "sudo /opt/repos/libscript/_lib/databases/mongodb/logs.sh || true"
      vagrant ssh -c "sudo /opt/repos/libscript/_lib/databases/mysql/logs.sh || true"

      printf '[INFO] Checking Message Brokers & Caching (RabbitMQ & Redis)...\n'
      vagrant ssh -c "sudo /opt/repos/libscript/_lib/message-brokers/rabbitmq/logs.sh || true"
      vagrant ssh -c "sudo /opt/repos/libscript/_lib/caches/redis/logs.sh || true"
      vagrant ssh -c "sudo /opt/repos/libscript/_lib/caches/memcached/logs.sh || true"

      printf '[INFO] Checking Application Services (LMS & CMS)...\n'
      vagrant ssh -c "sudo /opt/repos/libscript/_lib/web-apps/openedx/logs.sh || sudo journalctl -u openedx-lms --no-pager -n 50 || sudo tail -n 50 /var/log/openedx-lms.log || sudo tail -n 50 /var/svc/log/application-openedx-lms:default.log || true"
      ;;
  esac
  
  printf '[PASS] Log inspection completed.\n'
}

case "$STEP" in
  0) run_step_0 ;;
  1) run_step_1 ;;
  2) run_step_2 ;;
  3) run_step_3 ;;
  *)
    printf '[ERROR] Unknown step: %s\n' "$STEP" >&2
    exit 1
    ;;
esac

exit 0
