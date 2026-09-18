#!/bin/sh
# ## Overview
# Mock HTTP/WSGI test server for Open edX registration and authentication testing.
# Provides mock LMS and Studio endpoints when running in lightweight or CI environments.
#
# ## Usage
# ./stacks/cms/openedx/test_server.sh [PORT]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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

PORT="${1:-18000}"

# ## start_server
# Launches HTTP server on the configured port using python runtime.
start_server() {
  _py=""
  if command -v python3 >/dev/null 2>&1; then
    _py="python3"
  elif command -v python >/dev/null 2>&1; then
    _py="python"
  fi

  if [ -n "$_py" ]; then
    exec "$_py" - "$PORT" << 'PYEOF'
import sys
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.parse


class OpenEdxHandler(BaseHTTPRequestHandler):
    """HTTP request handler for Open edX registration and login routes."""

    def log_message(self, format, *args):
        """Suppress default HTTP request logging."""
        pass

    def do_GET(self):
        """Handle GET requests for Open edX LMS web endpoints."""
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path in ("/", "/heartbeat"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "OK", "service": "Open edX LMS"}).encode("utf-8"))

        elif path == "/register":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            html = """<!DOCTYPE html>
<html>
<head><title>Open edX Registration</title></head>
<body>
  <h1>Create an Account</h1>
  <form id="register" class="register-form" method="POST" action="/api/user/v1/account/registration/">
    <input type="text" name="name" placeholder="Full Name" required />
    <input type="text" name="username" placeholder="Public Username" required />
    <input type="email" name="email" placeholder="Email Address" required />
    <input type="password" name="password" placeholder="Password" required />
    <button type="submit" id="register-button">Create Account</button>
  </form>
</body>
</html>"""
            self.wfile.write(html.encode("utf-8"))

        elif path in ("/login", "/signin"):
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            html = """<!DOCTYPE html>
<html>
<head><title>Open edX Login</title></head>
<body>
  <h1>Sign In to your account</h1>
  <form id="login" class="login-form" method="POST" action="/api/user/v1/account/login_session/">
    <input type="text" name="email_or_username" placeholder="Username or Email" required />
    <input type="password" name="password" placeholder="Password" required />
    <button type="submit" id="login-button">Sign In</button>
  </form>
</body>
</html>"""
            self.wfile.write(html.encode("utf-8"))

        elif path == "/dashboard":
            cookie = self.headers.get("Cookie", "")
            if "edx_sessionid=" in cookie or "sessionid=" in cookie:
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.end_headers()
                html = """<!DOCTYPE html>
<html>
<head><title>Student Dashboard - Open edX</title></head>
<body>
  <h1>Welcome to your Open edX Dashboard</h1>
  <div class="user-info">Logged in as: student</div>
  <div class="enrolled-courses"><h2>My Courses</h2><p>Demo Course 101: Introduction to Open edX</p></div>
</body>
</html>"""
                self.wfile.write(html.encode("utf-8"))
            else:
                self.send_response(302)
                self.send_header("Location", "/login")
                self.end_headers()

        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        """Handle POST requests for Open edX user registration and authentication."""
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode("utf-8") if length > 0 else ""

        if path in ("/api/user/v1/account/registration/", "/register"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Set-Cookie", "edx_sessionid=edx_test_session_token_12345; Path=/; HttpOnly")
            self.end_headers()
            resp = {
                "success": True,
                "user_id": 1001,
                "username": "student",
                "redirect_url": "/dashboard"
            }
            self.wfile.write(json.dumps(resp).encode("utf-8"))

        elif path in ("/api/user/v1/account/login_session/", "/login"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Set-Cookie", "edx_sessionid=edx_test_session_token_12345; Path=/; HttpOnly")
            self.end_headers()
            resp = {
                "success": True,
                "redirect_url": "/dashboard"
            }
            self.wfile.write(json.dumps(resp).encode("utf-8"))

        else:
            self.send_response(404)
            self.end_headers()


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 18000
    server = HTTPServer(("127.0.0.1", port), OpenEdxHandler)
    server.serve_forever()


if __name__ == "__main__":
    main()
PYEOF
  else
    printf '[ERROR] Neither python3 nor python found to launch mock server.
' >&2
    exit 1
  fi
}

start_server
