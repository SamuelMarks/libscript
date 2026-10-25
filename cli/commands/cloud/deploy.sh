#!/bin/sh
# ## Overview
# Git-driven deployment workflow engine (`libscript deploy`).
# Supports cloning or pulling a Git repository at a specified branch/tag/commit,
# deploying applications locally via `libscript.json` or remotely via SSH (`--host`)
# or cloud providers (`--provider`), and generating `post-receive` Git push-to-deploy hooks.
#
# ## Usage
# libscript.sh deploy [<git_repo_or_path>] [--branch <ref>] [--host <user@host>] [--provider <cloud>] [--domain <domain>] [--install-hook <bare_repo_dir>]

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

# ## show_deploy_help
# Displays usage instructions for the Git-driven deployment workflow.
show_deploy_help() {
  printf '%s
' "LibScript Git-Driven Deployment Workflow (libscript deploy)"
  printf '%s
' "Usage: libscript.sh deploy [repo_url_or_path] [options]"
  printf '%s
' ""
  printf '%s
' "Options:"
  printf '%s
' "  --repo <url|path>         Git repository URL or local directory (default: .)"
  printf '%s
' "  --branch <ref>            Git branch, tag, or commit to checkout (default: main)"
  printf '%s
' "  --host <user@host>        Deploy over SSH to a remote host via deploy-remote"
  printf '%s
' "  --domain <domain>         Target domain for routing when deploying to a host"
  printf '%s
' "  --provider <cloud>        Provision and deploy to a cloud provider"
  printf '%s
' "  --install-hook <dir>      Install a Git post-receive push-to-deploy hook into <dir>"
  printf '%s
' "  --dry-run                 Print planned Git deployment actions without mutating state"
}

REPO_SOURCE="."
GIT_REF=""
TARGET_HOST=""
TARGET_DOMAIN="localhost"
CLOUD_PROVIDER=""
HOOK_DIR=""
DRY_RUN_MODE="${DRY_RUN:-0}"
PASSTHROUGH_ARGS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h|/\?|-\?)
      show_deploy_help
      exit 0
      ;;
    --repo=*) REPO_SOURCE="${1#*=}"; shift ;;
    --repo) REPO_SOURCE="${2:-.}"; shift 2 ;;
    --branch=*|--ref=*) GIT_REF="${1#*=}"; shift ;;
    --branch|--ref) GIT_REF="${2:-}"; shift 2 ;;
    --host=*|--target=*) TARGET_HOST="${1#*=}"; shift ;;
    --host|--target) TARGET_HOST="${2:-}"; shift 2 ;;
    --domain=*) TARGET_DOMAIN="${1#*=}"; shift ;;
    --domain) TARGET_DOMAIN="${2:-localhost}"; shift 2 ;;
    --provider=*) CLOUD_PROVIDER="${1#*=}"; PASSTHROUGH_ARGS="${PASSTHROUGH_ARGS} $1"; shift ;;
    --provider) CLOUD_PROVIDER="${2:-}"; PASSTHROUGH_ARGS="${PASSTHROUGH_ARGS} --provider ${2:-}"; shift 2 ;;
    --install-hook=*) HOOK_DIR="${1#*=}"; shift ;;
    --install-hook) HOOK_DIR="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN_MODE="1"; export DRY_RUN="true"; PASSTHROUGH_ARGS="${PASSTHROUGH_ARGS} --dry-run"; shift ;;
    --*)
      PASSTHROUGH_ARGS="${PASSTHROUGH_ARGS} $1"
      shift
      ;;
    *)
      if [ "$REPO_SOURCE" = "." ]; then
        REPO_SOURCE="$1"
      else
        PASSTHROUGH_ARGS="${PASSTHROUGH_ARGS} $1"
      fi
      shift
      ;;
  esac
done

# ## install_git_hook
# Generates an idempotent post-receive Git hook for push-to-deploy automation.
install_git_hook() {
  _hook_repo="$1"
  _hooks_path="${_hook_repo}/hooks"
  if [ -d "${_hook_repo}/.git/hooks" ]; then
    _hooks_path="${_hook_repo}/.git/hooks"
  fi
  mkdir -p "$_hooks_path"
  _post_receive="${_hooks_path}/post-receive"
  cat <<EOF > "$_post_receive"
#!/bin/sh
set -feu
while read -r oldrev newrev refname; do
  branch="\${refname#refs/heads/}"
  printf '[LIBSCRIPT DEPLOY] Received push for branch %s (%s -> %s)
' "\$branch" "\$oldrev" "\$newrev"
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" deploy "${_hook_repo}" --branch "\$branch"
done
EOF
  chmod +x "$_post_receive"
  printf '[OK] Installed Git post-receive deployment hook at %s
' "$_post_receive"
}

if [ -n "$HOOK_DIR" ]; then
  install_git_hook "$HOOK_DIR"
  exit 0
fi

if [ -n "$CLOUD_PROVIDER" ]; then
  # shellcheck disable=SC2086
  exec "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/deploy_cloud.sh" $PASSTHROUGH_ARGS "$REPO_SOURCE"
fi

WORK_DIR="$REPO_SOURCE"
case "$REPO_SOURCE" in
  http://*|https://*|git@*|ssh://*|*.git)
    APP_SLUG=$(basename "$REPO_SOURCE" .git)
    WORK_DIR="${LIBSCRIPT_HOME:-${HOME}/.libscript}/deployments/${APP_SLUG}"
    if [ "$DRY_RUN_MODE" = "1" ] || [ "$DRY_RUN_MODE" = "true" ]; then
      printf '[DRY_RUN] Would clone/update %s into %s (ref: %s)
' "$REPO_SOURCE" "$WORK_DIR" "${GIT_REF:-default}"
    else
      mkdir -p "$(dirname "$WORK_DIR")"
      if [ -d "${WORK_DIR}/.git" ]; then
        git -C "$WORK_DIR" fetch --all --prune
      else
        git clone "$REPO_SOURCE" "$WORK_DIR"
      fi
      if [ -n "$GIT_REF" ]; then
        git -C "$WORK_DIR" checkout "$GIT_REF"
        git -C "$WORK_DIR" pull --ff-only origin "$GIT_REF" 2>/dev/null || true
      fi
    fi
    ;;
  *)
    if [ -d "${WORK_DIR}/.git" ] && [ -n "$GIT_REF" ]; then
      if [ "$DRY_RUN_MODE" = "1" ] || [ "$DRY_RUN_MODE" = "true" ]; then
        printf '[DRY_RUN] Would checkout %s in %s
' "$GIT_REF" "$WORK_DIR"
      else
        git -C "$WORK_DIR" checkout "$GIT_REF" 2>/dev/null || true
      fi
    fi
    ;;
esac

COMMIT_SHA="unknown"
if [ -d "${WORK_DIR}/.git" ] && command -v git >/dev/null 2>&1; then
  COMMIT_SHA=$(git -C "$WORK_DIR" rev-parse --short HEAD 2>/dev/null || printf 'unknown')
fi

printf '[DEPLOY] Deploying %s (commit: %s)
' "$WORK_DIR" "$COMMIT_SHA"

if [ -n "$TARGET_HOST" ]; then
  if [ "$DRY_RUN_MODE" = "1" ] || [ "$DRY_RUN_MODE" = "true" ]; then
    printf '[DRY_RUN] Would execute deploy_remote.sh %s --app %s@%s
' "$TARGET_HOST" "$WORK_DIR" "$TARGET_DOMAIN"
    exit 0
  fi
  # shellcheck disable=SC2086
  exec "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/deploy_remote.sh" "$TARGET_HOST" --app "${WORK_DIR}@${TARGET_DOMAIN}" $PASSTHROUGH_ARGS
fi

if [ "$DRY_RUN_MODE" = "1" ] || [ "$DRY_RUN_MODE" = "true" ]; then
  printf '[DRY_RUN] Local Git-driven deployment validated for %s (commit: %s)
' "$WORK_DIR" "$COMMIT_SHA"
  exit 0
fi

if [ -f "${WORK_DIR}/libscript.json" ]; then
  (
    cd "$WORK_DIR"
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install-deps libscript.json
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" start libscript.json
  )
fi

printf '[OK] Deployment of %s (commit: %s) complete.
' "$WORK_DIR" "$COMMIT_SHA"
exit 0
