#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
# daemonize.sh <action> <json_file>
set -e
ACTION="$1"
JSON_FILE="$2"

if [ ! -f "$JSON_FILE" ]; then exit 0; fi

SERVICES=$(jq -c '.services[]?' "$JSON_FILE" 2>/dev/null || true)
if [ -z "$SERVICES" ]; then exit 0; fi

OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')

echo "$SERVICES" | while read -r svc; do
    NAME=$(echo "$svc" | jq -r '.name // empty')
    CMD=$(echo "$svc" | jq -r '.command // empty')
    if [ -z "$NAME" ] || [ -z "$CMD" ]; then continue; fi

    # Create /data/name persistent directory if needed
    mkdir -p "/tmp/data/$NAME" 2>/dev/null || true # Fallback or use real persistent dir

    if [ "$ACTION" = "start" ] || [ "$ACTION" = "up" ]; then
        echo "Configuring service '$NAME'..."
        if [ "$OS_NAME" = "linux" ] && command -v systemctl >/dev/null 2>&1; then
            SERVICE_FILE="/etc/systemd/system/${NAME}.service"
            # generate systemd
            sudo sh -c "cat << 'SYSTEMD' > $SERVICE_FILE
[Unit]
Description=$NAME service managed by libscript
After=network.target

[Service]
ExecStart=/bin/sh -c \"$CMD\"
Restart=always
# Environment variables parsing here (simplified)
SYSTEMD
"
            # extract envs
            ENVS=$(echo "$svc" | jq -r '.env | to_entries[]? | "\(.key)=\(.value)"' 2>/dev/null || true)
            if [ -n "$ENVS" ]; then
                sudo sh -c "echo '[Service]' >> $SERVICE_FILE"
                echo "$ENVS" | while read -r e; do
                    sudo sh -c "echo 'Environment=\"$e\"' >> $SERVICE_FILE"
                done
            fi
            ENV_FILES=$(echo "$svc" | jq -r '.env_files[]?' 2>/dev/null || true)
            if [ -n "$ENV_FILES" ]; then
                echo "$ENV_FILES" | while read -r ef; do
                    # resolve path
                    EF_FULL=$(realpath "$ef" 2>/dev/null || echo "$ef")
                    if [ -f "$EF_FULL" ]; then
                        sudo sh -c "echo 'EnvironmentFile=$EF_FULL' >> $SERVICE_FILE"
                    fi
                done
            fi
            sudo systemctl daemon-reload
            sudo systemctl enable --now "$NAME"
        elif echo "$OS_NAME" | grep -q "darwin"; then
            PLIST_FILE="$HOME/Library/LaunchAgents/com.libscript.${NAME}.plist"
            mkdir -p "$HOME/Library/LaunchAgents"
            cat << PLIST > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.libscript.${NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>$CMD</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
PLIST
            ENVS=$(echo "$svc" | jq -r '.env | to_entries[]? | "\(.key)=\(.value)"' 2>/dev/null || true)
            if [ -n "$ENVS" ]; then
                # Needs dict injection for <key>EnvironmentVariables</key>
                # Simplified: just inline them in the command or add proper XML
                true
            fi
            launchctl load -w "$PLIST_FILE" 2>/dev/null || true
            launchctl start "com.libscript.${NAME}" 2>/dev/null || true
        else
            echo "Fallback: starting $NAME in background"
            eval "$CMD" &
        fi
    elif [ "$ACTION" = "stop" ] || [ "$ACTION" = "down" ]; then
        if [ "$OS_NAME" = "linux" ] && command -v systemctl >/dev/null 2>&1; then
            sudo systemctl stop "$NAME" || true
            sudo systemctl disable "$NAME" || true
        elif echo "$OS_NAME" | grep -q "darwin"; then
            launchctl stop "com.libscript.${NAME}" 2>/dev/null || true
            launchctl unload -w "$HOME/Library/LaunchAgents/com.libscript.${NAME}.plist" 2>/dev/null || true
        else
            pkill -f "$CMD" || true
        fi
    elif [ "$ACTION" = "status" ]; then
        if [ "$OS_NAME" = "linux" ] && command -v systemctl >/dev/null 2>&1; then
            systemctl status "$NAME" --no-pager || true
        elif echo "$OS_NAME" | grep -q "darwin"; then
            launchctl list | grep "com.libscript.${NAME}" || true
        fi
    fi
done
