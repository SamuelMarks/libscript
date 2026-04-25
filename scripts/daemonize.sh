#!/bin/sh
# daemonize.sh <action> <json_file>
set -e
action="$1"
json_file="$2"

if [ ! -f "$json_file" ]; then exit 0; fi

services=$(jq -c '.services[]?' "$json_file" 2>/dev/null || true)
if [ -z "$services" ]; then exit 0; fi

OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')

echo "$services" | while read -r svc; do
    name=$(echo "$svc" | jq -r '.name // empty')
    cmd=$(echo "$svc" | jq -r '.command // empty')
    if [ -z "$name" ] || [ -z "$cmd" ]; then continue; fi

    # Create /data/name persistent directory if needed
    mkdir -p "/tmp/data/$name" 2>/dev/null || true # Fallback or use real persistent dir

    if [ "$action" = "start" ] || [ "$action" = "up" ]; then
        echo "Configuring service '$name'..."
        if [ "$OS_NAME" = "linux" ] && command -v systemctl >/dev/null 2>&1; then
            service_file="/etc/systemd/system/${name}.service"
            # generate systemd
            sudo sh -c "cat << 'SYSTEMD' > $service_file
[Unit]
Description=$name service managed by libscript
After=network.target

[Service]
ExecStart=/bin/sh -c \"$cmd\"
Restart=always
# Environment variables parsing here (simplified)
SYSTEMD
"
            # extract envs
            envs=$(echo "$svc" | jq -r '.env | to_entries[]? | "\(.key)=\(.value)"' 2>/dev/null || true)
            if [ -n "$envs" ]; then
                sudo sh -c "echo '[Service]' >> $service_file"
                echo "$envs" | while read -r e; do
                    sudo sh -c "echo 'Environment=\"$e\"' >> $service_file"
                done
            fi
            env_files=$(echo "$svc" | jq -r '.env_files[]?' 2>/dev/null || true)
            if [ -n "$env_files" ]; then
                echo "$env_files" | while read -r ef; do
                    # resolve path
                    ef_full=$(realpath "$ef" 2>/dev/null || echo "$ef")
                    if [ -f "$ef_full" ]; then
                        sudo sh -c "echo 'EnvironmentFile=$ef_full' >> $service_file"
                    fi
                done
            fi
            sudo systemctl daemon-reload
            sudo systemctl enable --now "$name"
        elif echo "$OS_NAME" | grep -q "darwin"; then
            plist_file="$HOME/Library/LaunchAgents/com.libscript.${name}.plist"
            mkdir -p "$HOME/Library/LaunchAgents"
            cat << PLIST > "$plist_file"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.libscript.${name}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>$cmd</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
PLIST
            envs=$(echo "$svc" | jq -r '.env | to_entries[]? | "\(.key)=\(.value)"' 2>/dev/null || true)
            if [ -n "$envs" ]; then
                # Needs dict injection for <key>EnvironmentVariables</key>
                # Simplified: just inline them in the command or add proper XML
                true
            fi
            launchctl load -w "$plist_file" 2>/dev/null || true
            launchctl start "com.libscript.${name}" 2>/dev/null || true
        else
            echo "Fallback: starting $name in background"
            eval "$cmd" &
        fi
    elif [ "$action" = "stop" ] || [ "$action" = "down" ]; then
        if [ "$OS_NAME" = "linux" ] && command -v systemctl >/dev/null 2>&1; then
            sudo systemctl stop "$name" || true
            sudo systemctl disable "$name" || true
        elif echo "$OS_NAME" | grep -q "darwin"; then
            launchctl stop "com.libscript.${name}" 2>/dev/null || true
            launchctl unload -w "$HOME/Library/LaunchAgents/com.libscript.${name}.plist" 2>/dev/null || true
        else
            pkill -f "$cmd" || true
        fi
    elif [ "$action" = "status" ]; then
        if [ "$OS_NAME" = "linux" ] && command -v systemctl >/dev/null 2>&1; then
            systemctl status "$name" --no-pager || true
        elif echo "$OS_NAME" | grep -q "darwin"; then
            launchctl list | grep "com.libscript.${name}" || true
        fi
    fi
done
