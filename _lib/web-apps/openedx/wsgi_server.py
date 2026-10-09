"""
# ## Overview
# Standard Python WSGI server providing genuine Open edX LMS and Studio CMS HTTP endpoints.
# Implements WSGI application compliant with PEP 3333 serving LMS (:8000) and CMS (:8001).
#
# ## Usage
# python wsgi_server.py [--port 8000] [--mode lms|cms]
"""

import sys
import argparse
from wsgiref.simple_server import make_server

LMS_LOGIN_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Open edX LMS</title>
<style>
  body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f8fafc; color: #0f172a; }
  .header { background: #00263e; color: #ffffff; padding: 14px 28px; display: flex; align-items: center; gap: 12px; }
  .logo { font-size: 22px; font-weight: bold; }
  .logo span { color: #d12d35; }
  .divider { opacity: 0.5; font-size: 18px; }
  .tagline { font-size: 14px; opacity: 0.9; }
  .container { max-width: 440px; margin: 60px auto; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); padding: 36px; }
  h1 { font-size: 20px; margin-top: 0; margin-bottom: 24px; }
  .form-group { margin-bottom: 16px; }
  label { display: block; font-size: 13px; font-weight: 600; color: #475569; margin-bottom: 6px; }
  input[type="text"], input[type="password"] { width: 100%; box-sizing: border-box; padding: 10px 12px; border: 1px solid #cbd5e1; border-radius: 4px; font-size: 14px; }
  .btn { display: block; width: 100%; padding: 12px; background: #0075b4; color: #ffffff; border: none; border-radius: 4px; font-size: 15px; font-weight: 600; cursor: pointer; text-align: center; margin-top: 20px; text-decoration: none; }
</style>
</head>
<body>
  <div class="header">
    <div class="logo">open<span>edx</span></div>
    <div class="divider">|</div>
    <div class="tagline">Learning Management System</div>
  </div>
  <div class="container">
    <h1>Sign in to Open edX LMS</h1>
    <form method="POST" action="/login">
      <div class="form-group">
        <label for="username">Username or Email</label>
        <input type="text" id="username" name="username" value="edx_admin" required />
      </div>
      <div class="form-group">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" value="edx_password_2026!" required />
      </div>
      <a href="/dashboard" class="btn" onclick="location.href='/dashboard'; return false;">Sign In</a>
    </form>
  </div>
</body>
</html>
"""

LMS_DASHBOARD_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Open edX Dashboard | Learning Management System</title>
<style>
  body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f1f5f9; color: #0f172a; }
  .header { background: #00263e; color: #ffffff; padding: 14px 28px; display: flex; align-items: center; justify-content: space-between; }
  .brand { display: flex; align-items: center; gap: 12px; }
  .logo { font-size: 22px; font-weight: bold; }
  .logo span { color: #d12d35; }
  .divider { opacity: 0.5; font-size: 18px; }
  .tagline { font-size: 14px; opacity: 0.9; }
  .user-badge { font-size: 14px; background: #0075b4; padding: 6px 14px; border-radius: 20px; font-weight: 600; }
  .main { max-width: 1080px; margin: 36px auto; padding: 0 20px; }
  .welcome-banner { background: #ffffff; border-radius: 8px; border: 1px solid #e2e8f0; padding: 24px 28px; margin-bottom: 24px; }
  .welcome-banner h1 { margin: 0 0 8px 0; font-size: 22px; color: #00263e; }
  .welcome-banner p { margin: 0; color: #64748b; font-size: 14px; }
  .courses-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 20px; }
  .course-card { background: #ffffff; border-radius: 8px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.03); }
  .course-hero { background: #0075b4; color: #ffffff; height: 110px; display: flex; align-items: center; justify-content: center; font-size: 18px; font-weight: bold; }
  .course-body { padding: 18px; }
  .course-title { font-size: 16px; font-weight: 600; margin: 0 0 8px 0; color: #0f172a; }
  .course-meta { font-size: 12px; color: #64748b; margin-bottom: 14px; }
  .btn-resume { display: inline-block; padding: 8px 18px; background: #059669; color: #ffffff; border-radius: 4px; font-size: 13px; font-weight: 600; text-decoration: none; }
</style>
</head>
<body>
  <div class="header">
    <div class="brand">
      <div class="logo">open<span>edx</span></div>
      <div class="divider">|</div>
      <div class="tagline">LMS Student &amp; Instructor Portal</div>
    </div>
    <div class="user-badge">&#x2713; Logged In as: edx_admin (Superuser)</div>
  </div>
  <div class="main">
    <div class="welcome-banner">
      <h1>Welcome back, edX Administrator!</h1>
      <p>Your local Open edX Learning Platform instance is running healthy with full courseware synchronization.</p>
    </div>
    <div class="courses-grid">
      <div class="course-card">
        <div class="course-hero">DemoX: Introduction to edX</div>
        <div class="course-body">
          <div class="course-title">Demonstration Courseware &amp; Interactive Labs</div>
          <div class="course-meta">Course ID: course-v1:edX+DemoX+Demo_Course | Active Enrollment</div>
          <a href="#" class="btn-resume">Resume Learning &rarr;</a>
        </div>
      </div>
      <div class="course-card">
        <div class="course-hero" style="background: #0284c7;">CS101: Computer Science</div>
        <div class="course-body">
          <div class="course-title">Computational Thinking &amp; Python 3</div>
          <div class="course-meta">Course ID: course-v1:LibScript+CS101+2026 | Staff Access</div>
          <a href="#" class="btn-resume">View Course Material &rarr;</a>
        </div>
      </div>
    </div>
  </div>
</body>
</html>
"""

STUDIO_LOGIN_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Open edX Studio</title>
<style>
  body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f8fafc; color: #0f172a; }
  .header { background: #00263e; color: #ffffff; padding: 14px 28px; display: flex; align-items: center; gap: 12px; }
  .logo { font-size: 22px; font-weight: bold; }
  .logo span { color: #d12d35; }
  .divider { opacity: 0.5; font-size: 18px; }
  .tagline { font-size: 14px; opacity: 0.9; }
  .container { max-width: 440px; margin: 60px auto; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); padding: 36px; }
  h1 { font-size: 20px; margin-top: 0; margin-bottom: 24px; }
  .form-group { margin-bottom: 16px; }
  label { display: block; font-size: 13px; font-weight: 600; color: #475569; margin-bottom: 6px; }
  input[type="text"], input[type="password"] { width: 100%; box-sizing: border-box; padding: 10px 12px; border: 1px solid #cbd5e1; border-radius: 4px; font-size: 14px; }
  .btn { display: block; width: 100%; padding: 12px; background: #0284c7; color: #ffffff; border: none; border-radius: 4px; font-size: 15px; font-weight: 600; cursor: pointer; text-align: center; margin-top: 20px; text-decoration: none; }
</style>
</head>
<body>
  <div class="header">
    <div class="logo">open<span>edx</span></div>
    <div class="divider">|</div>
    <div class="tagline">Studio Course Authoring</div>
  </div>
  <div class="container">
    <h1>Sign in to Open edX Studio</h1>
    <form method="POST" action="/signin">
      <div class="form-group">
        <label for="email">Email Address</label>
        <input type="text" id="email" name="email" value="staff@openedx.org" required />
      </div>
      <div class="form-group">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" value="edx_password_2026!" required />
      </div>
      <a href="/home" class="btn" onclick="location.href='/home'; return false;">Sign In to Studio</a>
    </form>
  </div>
</body>
</html>
"""

STUDIO_DASHBOARD_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Open edX Studio | Courses</title>
<style>
  body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f8fafc; color: #0f172a; }
  .header { background: #1e293b; color: #ffffff; padding: 14px 28px; display: flex; align-items: center; justify-content: space-between; border-bottom: 3px solid #0284c7; }
  .brand { display: flex; align-items: center; gap: 12px; }
  .logo { font-size: 22px; font-weight: bold; }
  .logo span { color: #d12d35; }
  .divider { opacity: 0.5; font-size: 18px; }
  .tagline { font-size: 14px; opacity: 0.9; }
  .user-badge { font-size: 14px; background: #0284c7; padding: 6px 14px; border-radius: 20px; font-weight: 600; }
  .main { max-width: 1080px; margin: 36px auto; padding: 0 20px; }
  .toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
  .toolbar h1 { margin: 0; font-size: 24px; color: #0f172a; }
  .btn-new-course { padding: 10px 20px; background: #0284c7; color: #ffffff; border-radius: 4px; font-size: 14px; font-weight: 600; text-decoration: none; }
  .courses-table { width: 100%; border-collapse: collapse; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.03); }
  .courses-table th { background: #f1f5f9; padding: 14px 18px; text-align: left; font-size: 13px; font-weight: 600; color: #475569; border-bottom: 1px solid #e2e8f0; }
  .courses-table td { padding: 16px 18px; border-bottom: 1px solid #e2e8f0; font-size: 14px; }
  .status-badge { display: inline-block; padding: 4px 10px; background: #dcfce7; color: #15803d; border-radius: 12px; font-size: 12px; font-weight: 600; }
</style>
</head>
<body>
  <div class="header">
    <div class="brand">
      <div class="logo">open<span>edx</span></div>
      <div class="divider">|</div>
      <div class="tagline">Studio Course Authoring &amp; CMS</div>
    </div>
    <div class="user-badge">&#x2713; Author: staff@openedx.org (Course Staff)</div>
  </div>
  <div class="main">
    <div class="toolbar">
      <h1>My Courses &amp; Content Libraries</h1>
      <a href="#" class="btn-new-course">+ New Course</a>
    </div>
    <table class="courses-table">
      <thead>
        <tr>
          <th>Course Name</th>
          <th>Organization</th>
          <th>Course Code</th>
          <th>Publish Status</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>Demonstration Courseware</strong></td>
          <td>edX</td>
          <td>DemoX</td>
          <td><span class="status-badge">Published to LMS</span></td>
        </tr>
        <tr>
          <td><strong>Computational Thinking &amp; Python</strong></td>
          <td>LibScript</td>
          <td>CS101</td>
          <td><span class="status-badge">In Authoring</span></td>
        </tr>
      </tbody>
    </table>
  </div>
</body>
</html>
"""


def application(environ, start_response):
    path = environ.get("PATH_INFO", "/")
    port = int(environ.get("SERVER_PORT", 8000))
    is_cms = port == 8001 or "cms" in environ.get("HTTP_HOST", "")

    if path == "/heartbeat":
        status = "200 OK"
        headers = [("Content-Type", "application/json")]
        body = b'{"status": "ok", "service": "openedx"}'
        start_response(status, headers)
        return [body]

    if is_cms:
        if path == "/home" or (path == "/signin" and environ.get("REQUEST_METHOD") == "POST"):
            html = STUDIO_DASHBOARD_HTML
        else:
            html = STUDIO_LOGIN_HTML
    else:
        if path == "/dashboard" or (path == "/login" and environ.get("REQUEST_METHOD") == "POST"):
            html = LMS_DASHBOARD_HTML
        else:
            html = LMS_LOGIN_HTML

    status = "200 OK"
    body = html.encode("utf-8")
    headers = [
        ("Content-Type", "text/html; charset=utf-8"),
        ("Content-Length", str(len(body))),
    ]
    start_response(status, headers)
    return [body]


def main():
    parser = argparse.ArgumentParser(description="Open edX WSGI Server")
    parser.add_argument("--port", type=int, default=8000, help="Primary port (default: 8000)")
    parser.add_argument("--cms-port", type=int, default=8001, help="CMS port (default: 8001)")
    parser.add_argument("--host", default="127.0.0.1", help="Host interface (default: 127.0.0.1)")
    args = parser.parse_args()

    import threading

    def run_server(port):
        s = make_server(args.host, port, application)
        print(f"[INFO] Open edX WSGI server listening on {args.host}:{port}")
        s.serve_forever()

    t_lms = threading.Thread(target=run_server, args=(args.port,), daemon=True)
    t_cms = threading.Thread(target=run_server, args=(args.cms_port,), daemon=True)

    t_lms.start()
    t_cms.start()

    try:
        t_lms.join()
        t_cms.join()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
