#!/bin/sh
CMD=$1
SVC=${2%.service}

if [ "$CMD" = "daemon-reload" ] || [ "$CMD" = "enable" ]; then
    exit 0
fi

if [ "$CMD" = "start" ]; then
    # Simple parse of ExecStart (assuming continuation lines with \)
    awk -v svc="$SVC" '
    BEGIN { in_exec = 0; cmd = "" }
    /^ExecStart=/ {
        in_exec = 1;
        sub(/^ExecStart=/, "");
    }
    in_exec {
        line = $0;
        if (line ~ /\\$/) {
            sub(/\\$/, "", line);
            cmd = cmd " " line;
        } else {
            cmd = cmd " " line;
            in_exec = 0;
            # Output the command wrapped in nohup
            print "nohup " cmd " > /var/log/" svc ".log 2>&1 &"
        }
    }
    ' "/etc/systemd/system/${SVC}.service" > "/tmp/start_${SVC}.sh"
    
    sh "/tmp/start_${SVC}.sh"
    exit 0
fi
