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

# Start pure PowerShell HttpListener for mock Open edX server
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
