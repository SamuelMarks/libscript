#!/bin/sh
set -feu

echo "Running merge unit tests..."

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT QUIT TERM

cat << 'CONF' > "$TMP_DIR/existing.conf"
server {
    listen 80;
    server_name example.com;

    location / {
        return 200 "hello";
    }
}

server {
    listen 443 ssl http2;
    server_name  "example.com"
                 alias.example.com;

    # This is a comment {
    location /old {
        return 200 "old";
    }

    location ~ "^/regex/[0-9]{1,3}$" {
        return 200 "regex";
    }
}
CONF

cat << 'CONF' > "$TMP_DIR/new.conf"
location ~ "^/regex/[0-9]{1,3}$" {
    return 200 "new regex";
}
CONF

# test script logic
. ./_lib/web-servers/nginx/merge_location_into_server.sh
merge_location_into_server "$TMP_DIR/existing.conf" "$TMP_DIR/new.conf" "example.com"

if grep -q '"new regex"' "$TMP_DIR/existing.conf"; then
    echo "Test 1 Passed: Overwrote existing location block."
else
    echo "Test 1 Failed: Did not overwrite existing location block."
    cat "$TMP_DIR/existing.conf"
    exit 1
fi

if grep -q '"regex"' "$TMP_DIR/existing.conf"; then
    echo "Test 2 Failed: Old regex still present."
    exit 1
else
    echo "Test 2 Passed: Old regex block completely removed."
fi

cat << 'CONF' > "$TMP_DIR/new2.conf"
location /new {
    return 201;
}
CONF

merge_location_into_server "$TMP_DIR/existing.conf" "$TMP_DIR/new2.conf" "example.com"

if grep -q 'return 201' "$TMP_DIR/existing.conf"; then
    echo "Test 3 Passed: Injected new location block."
else
    echo "Test 3 Failed: Did not inject new location block."
    exit 1
fi

echo "All tests passed."
