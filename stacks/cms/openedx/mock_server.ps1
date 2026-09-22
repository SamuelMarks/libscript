# ## Overview
# Lightweight mock HTTP listener serving Open edX LMS and Studio CMS login pages.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File stacks/cms/openedx/mock_server.ps1

$lmsHtml = @"
<!DOCTYPE html>
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
  .btn { display: block; width: 100%; padding: 12px; background: #0075b4; color: #ffffff; border: none; border-radius: 4px; font-size: 15px; font-weight: 600; cursor: pointer; text-align: center; }
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
    <button class="btn">Sign In</button>
  </div>
</body>
</html>
"@

$studioHtml = @"
<!DOCTYPE html>
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
  .btn { display: block; width: 100%; padding: 12px; background: #0284c7; color: #ffffff; border: none; border-radius: 4px; font-size: 15px; font-weight: 600; cursor: pointer; text-align: center; }
</style>
</head>
<body>
  <div class="header">
    <div class="logo">open<span>edx</span></div>
    <div class="divider">|</div>
    <div class="tagline">Studio Course Authoring</div>
  </div>
  <div class="container">
    <h1>Sign in to Studio</h1>
    <button class="btn">Sign In to Studio</button>
  </div>
</body>
</html>
"@

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:8000/")
$listener.Prefixes.Add("http://127.0.0.1:8000/")
$listener.Prefixes.Add("http://localhost:8001/")
$listener.Prefixes.Add("http://127.0.0.1:8001/")
$listener.Start()

while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
        $isStudio = ($ctx.Request.Url.Port -eq 8001)
        $html = if ($isStudio) { $studioHtml } else { $lmsHtml }
        $buf = [System.Text.Encoding]::UTF8.GetBytes($html)
        $ctx.Response.ContentType = "text/html; charset=utf-8"
        $ctx.Response.ContentLength64 = $buf.Length
        $ctx.Response.OutputStream.Write($buf, 0, $buf.Length)
        $ctx.Response.Close()
    } catch {
        break
    }
}
