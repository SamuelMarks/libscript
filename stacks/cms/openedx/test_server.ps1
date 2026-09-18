# ## Overview
# Mock HTTP/WSGI test server for Open edX registration and authentication testing on PowerShell.
# Provides mock LMS and Studio endpoints when running in lightweight or CI environments.
#
# ## Usage
# powershell -NoProfile -ExecutionPolicy Bypass -File test_server.ps1 [PORT]

<#
.SYNOPSIS
    Mock HTTP/WSGI test server for Open edX on PowerShell.
.DESCRIPTION
    Listens on 127.0.0.1 on the specified port and serves mock LMS and Studio responses
    for registration, login, session authentication, and dashboard navigation.
#>
param(
    [Parameter(Position = 0)]
    [int]$Port = 18000
)

# Prefer Python runtime if available for consistent cross-platform HTTP header handling
$pyCmd = $null
if (Get-Command "python3" -ErrorAction SilentlyContinue) {
    $pyCmd = "python3"
} elseif (Get-Command "python" -ErrorAction SilentlyContinue) {
    $pyCmd = "python"
} elseif (Get-Command "py" -ErrorAction SilentlyContinue) {
    $pyCmd = "py"
}

if ($pyCmd) {
    $pyScript = @'
import sys
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.parse


class OpenEdxHandler(BaseHTTPRequestHandler):
    """HTTP request handler for Open edX registration and login routes."""

    def log_message(self, format, *args):
        pass

    def do_GET(self):
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
'@
    & $pyCmd -c $pyScript "$Port"
    exit $LASTEXITCODE
}

# Fallback to pure PowerShell HttpListener when Python is not available
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Prefixes.Add("http://localhost:$Port/")

try {
    $listener.Start()
} catch {
    Write-Error "Failed to start HttpListener on port $Port`: $_"
    exit 1
}

$registerHtml = @"
<!DOCTYPE html>
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
</html>
"@

$loginHtml = @"
<!DOCTYPE html>
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
</html>
"@

$dashboardHtml = @"
<!DOCTYPE html>
<html>
<head><title>Student Dashboard - Open edX</title></head>
<body>
  <h1>Welcome to your Open edX Dashboard</h1>
  <div class="user-info">Logged in as: student</div>
  <div class="enrolled-courses"><h2>My Courses</h2><p>Demo Course 101: Introduction to Open edX</p></div>
</body>
</html>
"@

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
    } catch {
        break
    }

    $request = $context.Request
    $response = $context.Response
    $path = $request.Url.AbsolutePath
    $method = $request.HttpMethod

    if ($method -eq "GET") {
        if ($path -eq "/" -or $path -eq "/heartbeat") {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"status": "OK", "service": "Open edX LMS"}')
            $response.ContentType = "application/json"
            $response.StatusCode = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } elseif ($path -eq "/register") {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($registerHtml)
            $response.ContentType = "text/html; charset=utf-8"
            $response.StatusCode = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } elseif ($path -eq "/login" -or $path -eq "/signin") {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($loginHtml)
            $response.ContentType = "text/html; charset=utf-8"
            $response.StatusCode = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } elseif ($path -eq "/dashboard") {
            $hasCookie = $false
            $cookieHeader = $request.Headers["Cookie"]
            if ($cookieHeader -and ($cookieHeader.Contains("edx_sessionid=") -or $cookieHeader.Contains("sessionid="))) {
                $hasCookie = $true
            }
            if ($hasCookie) {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($dashboardHtml)
                $response.ContentType = "text/html; charset=utf-8"
                $response.StatusCode = 200
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $response.StatusCode = 302
                $response.RedirectLocation = "/login"
            }
        } else {
            $response.StatusCode = 404
        }
    } elseif ($method -eq "POST") {
        if ($path -eq "/api/user/v1/account/registration/" -or $path -eq "/register") {
            $response.Headers.Add("Set-Cookie", "edx_sessionid=edx_test_session_token_12345; Path=/; HttpOnly")
            $respJson = '{"success": true, "user_id": 1001, "username": "student", "redirect_url": "/dashboard"}'
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($respJson)
            $response.ContentType = "application/json"
            $response.StatusCode = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } elseif ($path -eq "/api/user/v1/account/login_session/" -or $path -eq "/login") {
            $response.Headers.Add("Set-Cookie", "edx_sessionid=edx_test_session_token_12345; Path=/; HttpOnly")
            $respJson = '{"success": true, "redirect_url": "/dashboard"}'
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($respJson)
            $response.ContentType = "application/json"
            $response.StatusCode = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
        }
    } else {
        $response.StatusCode = 404
    }

    $response.Close()
}
