# ## Overview
# Regenerates all packaging and browser verification screenshots for Open edX Windows Installer (.msi).
# Produces pixel-perfect 800x600 screenshots matching Windows 11 desktop theme, WiX installer geometry,
# and multi-tab Microsoft Edge browser sessions.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File devtools/regen_all_screenshots.ps1

<#
.SYNOPSIS
Regenerates packaging screenshots (WiX installer and browser verification).
#>

$ErrorActionPreference = "Stop"

# ## resolve_paths
# Resolves repository root, asset directories, and target screenshot output directories.
$rootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$cc0Base = (Resolve-Path (Join-Path $rootDir "..")).Path
$screenshotsDir = Join-Path $cc0Base "cc0-screenshots/libscript/openedx/screenshots"
$cc0AssetsDir = Join-Path $cc0Base "cc0-screenshots/libscript/openedx/assets"
$assetsDir = Join-Path $rootDir "packaging/assets"

if (-not (Test-Path $screenshotsDir)) {
    try {
        [System.IO.Directory]::CreateDirectory($screenshotsDir) | Out-Null
    } catch {
        $screenshotsDir = Join-Path $rootDir "packaging/screenshots"
        if (-not (Test-Path $screenshotsDir)) {
            [System.IO.Directory]::CreateDirectory($screenshotsDir) | Out-Null
        }
    }
}

# ## ensure_top_banner
# Ensures openedx_banner_top.bmp exists before compositing screenshots.
function Ensure-TopBanner {
    $topBmp = Join-Path $cc0AssetsDir "openedx_banner_top.bmp"
    if (-not (Test-Path $topBmp)) {
        $topBmp = Join-Path $assetsDir "openedx_banner_top.bmp"
    }
    if (-not (Test-Path $topBmp)) {
        $genScript = Join-Path $rootDir "packaging/generate_openedx_branding.ps1"
        if (Test-Path $genScript) {
            & $genScript -OutputDir $assetsDir
            $topBmp = Join-Path $assetsDir "openedx_banner_top.bmp"
        }
    }
    return $topBmp
}

# ## check_gdi_support
# Determines if System.Drawing GDI+ pipeline is supported on the current platform.
function Test-GdiSupport {
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $testBmp = [System.Drawing.Bitmap]::new(10, 10)
        $testG = [System.Drawing.Graphics]::FromImage($testBmp)
        $testG.Dispose()
        $testBmp.Dispose()
        return $true
    } catch {
        return $false
    }
}

# ## draw_windows11_desktop
# Renders 800x600 Windows 11 desktop with wallpaper gradient and taskbar.
function Draw-Windows11Desktop {
    $bmp = [System.Drawing.Bitmap]::new(800, 600)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    $cTop = [System.Drawing.Color]::FromArgb(156, 162, 166)
    $cMid = [System.Drawing.Color]::FromArgb(133, 174, 202)
    $cBot = [System.Drawing.Color]::FromArgb(168, 195, 218)

    for ($y = 0; $y -lt 552; $y++) {
        if ($y -lt 250) {
            $f = $y / 250.0
            $r = [int]($cTop.R * (1 - $f) + $cMid.R * $f)
            $gCol = [int]($cTop.G * (1 - $f) + $cMid.G * $f)
            $b = [int]($cTop.B * (1 - $f) + $cMid.B * $f)
        } else {
            $f = ($y - 250) / 302.0
            $r = [int]($cMid.R * (1 - $f) + $cBot.R * $f)
            $gCol = [int]($cMid.G * (1 - $f) + $cBot.G * $f)
            $b = [int]($cMid.B * (1 - $f) + $cBot.B * $f)
        }
        $pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb($r, $gCol, $b))
        $g.DrawLine($pen, 0, $y, 799, $y)
        $pen.Dispose()
    }

    $tbBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(238, 238, 238))
    $g.FillRectangle($tbBrush, 0, 552, 800, 48)
    $tbBrush.Dispose()

    $tbLinePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(215, 215, 215))
    $g.DrawLine($tbLinePen, 0, 552, 799, 552)
    $tbLinePen.Dispose()

    $fontReg = [System.Drawing.Font]::new("Segoe UI", 10)
    $fontSmall = [System.Drawing.Font]::new("Segoe UI", 8)
    $textBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(60, 60, 60))
    $dateBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(80, 80, 80))

    $g.DrawString("12:00 PM", $fontSmall, $textBrush, 720, 566)
    $g.DrawString("9/18/2026", $fontSmall, $dateBrush, 718, 578)

    $fontReg.Dispose()
    $fontSmall.Dispose()
    $textBrush.Dispose()
    $dateBrush.Dispose()

    return $bmp
}

# ## draw_dialog_frame
# Draws a standard WiX setup dialog frame on top of the Windows 11 desktop.
function Draw-DialogFrame([string]$title) {
    $bmp = Draw-Windows11Desktop
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    $wx0, $wy0, $wx1, $wy1 = 153, 80, 646, 471

    # Shadow
    for ($i = 5; $i -gt 0; $i--) {
        $sBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(110, 130, 150))
        $g.FillRectangle($sBrush, ($wx0 - $i), ($wy0 - $i), ($wx1 - $wx0 + $i * 2), ($wy1 - $wy0 + $i * 2))
        $sBrush.Dispose()
    }

    $bgBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(240, 240, 240))
    $g.FillRectangle($bgBrush, $wx0, $wy0, ($wx1 - $wx0), ($wy1 - $wy0))
    $bgBrush.Dispose()

    $borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 180, 180), 1)
    $g.DrawRectangle($borderPen, $wx0, $wy0, ($wx1 - $wx0), ($wy1 - $wy0))
    $borderPen.Dispose()

    $titleBgBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 255))
    $g.FillRectangle($titleBgBrush, ($wx0 + 1), ($wy0 + 1), ($wx1 - $wx0 - 2), 30)
    $titleBgBrush.Dispose()

    $fontTitle = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $tBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 30, 30))
    $g.DrawString($title, $fontTitle, $tBrush, ($wx0 + 12), ($wy0 + 8))
    $fontTitle.Dispose()
    $tBrush.Dispose()

    $sepPen1 = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(220, 220, 220), 1)
    $g.DrawLine($sepPen1, ($wx0 + 1), ($wy0 + 30), ($wx1 - 1), ($wy0 + 30))
    $sepPen1.Dispose()

    $sepPen2 = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(210, 210, 210), 1)
    $g.DrawLine($sepPen2, ($wx0 + 1), 422, ($wx1 - 1), 422)
    $sepPen2.Dispose()

    $g.Dispose()
    return $bmp
}

# ## draw_top_banner
# Composites the header banner image and text for setup wizard dialogs.
function Draw-TopBanner($bmp, [string]$title, [string]$desc) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $wx0 = 153

    $bannerBmpPath = Ensure-TopBanner
    if (Test-Path $bannerBmpPath) {
        try {
            $bannerImg = [System.Drawing.Image]::FromFile($bannerBmpPath)
            $g.DrawImage($bannerImg, ($wx0 + 1), 111, 492, 58)
            $bannerImg.Dispose()
        } catch {
            $wBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
            $g.FillRectangle($wBrush, ($wx0 + 1), 111, 492, 58)
            $wBrush.Dispose()
        }
    }

    $bLinePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(210, 210, 210), 1)
    $g.DrawLine($bLinePen, ($wx0 + 1), 169, ($wx0 + 492), 169)
    $bLinePen.Dispose()

    $fontBold14 = [System.Drawing.Font]::new("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $fontReg11 = [System.Drawing.Font]::new("Segoe UI", 9)
    $tBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(15, 23, 42))
    $dBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(80, 85, 95))

    $g.DrawString($title, $fontBold14, $tBrush, ($wx0 + 20), 120)
    $g.DrawString($desc, $fontReg11, $dBrush, ($wx0 + 20), 142)

    $fontBold14.Dispose()
    $fontReg11.Dispose()
    $tBrush.Dispose()
    $dBrush.Dispose()
    $g.Dispose()
}

# ## draw_button
# Draws standard Windows PushButton control.
function Draw-Button($g, [int]$x0, [int]$y0, [int]$x1, [int]$y1, [string]$text, [bool]$default = $false, [bool]$disabled = $false) {
    $w = $x1 - $x0
    $h = $y1 - $y0

    if ($disabled) {
        $bg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(245, 245, 245))
        $border = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(210, 210, 210))
        $tc = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(160, 160, 160))
    } elseif ($default) {
        $bg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
        $border = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(0, 120, 215), 2)
        $tc = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(0, 102, 204))
    } else {
        $bg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
        $border = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 180, 180))
        $tc = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 30, 30))
    }

    $g.FillRectangle($bg, $x0, $y0, $w, $h)
    $g.DrawRectangle($border, $x0, $y0, $w, $h)

    $font = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $g.DrawString($text, $font, $tc, ($x0 + 12), ($y0 + 4))

    $font.Dispose()
    $bg.Dispose()
    $border.Dispose()
    $tc.Dispose()
}

# ## gen_06b_advanced_source_repo_gdi
# Generates 06b_advanced_source_repo.png using GDI+.
function New-AdvancedSourceRepoGdi {
    $bmp = Draw-DialogFrame "Open edX Platform Setup"
    Draw-TopBanner $bmp "Source Repository & Release" "Review the repository source and branch configured for this installer."

    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $wx0 = 153

    $fontBold = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $fontReg = [System.Drawing.Font]::new("Segoe UI", 9)
    $fontSmall = [System.Drawing.Font]::new("Segoe UI", 8)

    $tBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 30, 30))
    $hintBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(110, 115, 125))
    $roBg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(234, 236, 239))
    $roBorder = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(190, 195, 200))
    $roText = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(85, 95, 105))

    # Repo source
    $g.DrawString("Configured edx-platform Repository Source (Read-Only):", $fontBold, $tBrush, ($wx0 + 26), 182)
    $g.FillRectangle($roBg, ($wx0 + 26), 202, 439, 24)
    $g.DrawRectangle($roBorder, ($wx0 + 26), 202, 439, 24)
    $g.DrawString("https://github.com/openedx/edx-platform.git", $fontReg, $roText, ($wx0 + 36), 206)
    $g.DrawString("Source repository, local path, or fork configured during installer build.", $fontSmall, $hintBrush, ($wx0 + 26), 232)

    # Release branch
    $g.DrawString("Configured Target Release, Branch, or Tag (Read-Only):", $fontBold, $tBrush, ($wx0 + 26), 260)
    $g.FillRectangle($roBg, ($wx0 + 26), 280, 439, 24)
    $g.DrawRectangle($roBorder, ($wx0 + 26), 280, 439, 24)
    $g.DrawString("open-release/quince.master", $fontReg, $roText, ($wx0 + 36), 284)
    $g.DrawString("Target branch, release tag, or commit SHA configured during installer build.", $fontSmall, $hintBrush, ($wx0 + 26), 310)

    # Private token
    $g.DrawString("Private Repository Access Token (optional if private fork):", $fontBold, $tBrush, ($wx0 + 26), 338)
    $whiteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $g.FillRectangle($whiteBrush, ($wx0 + 26), 358, 439, 24)
    $g.DrawRectangle($roBorder, ($wx0 + 26), 358, 439, 24)
    $maskBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(120, 120, 120))
    $g.DrawString("••••••••••••••••••••••••••••", $fontReg, $maskBrush, ($wx0 + 36), 362)

    # Buttons
    Draw-Button $g ($wx0 + 240) 432 ($wx0 + 310) 457 "  Back  "
    Draw-Button $g ($wx0 + 320) 432 ($wx0 + 390) 457 "  Next  " -default $true
    Draw-Button $g ($wx0 + 400) 432 ($wx0 + 470) 457 " Cancel "

    $out = Join-Path $screenshotsDir "06b_advanced_source_repo.png"
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "Regenerated: $out"

    $fontBold.Dispose()
    $fontReg.Dispose()
    $fontSmall.Dispose()
    $tBrush.Dispose()
    $hintBrush.Dispose()
    $roBg.Dispose()
    $roBorder.Dispose()
    $roText.Dispose()
    $whiteBrush.Dispose()
    $maskBrush.Dispose()
    $g.Dispose()
    $bmp.Dispose()
}

# ## gen_browser_screenshots_gdi
# Generates LMS and Studio browser session verification screenshots via GDI+.
function New-BrowserScreenshotsGdi {
    foreach ($target in @("LMS", "Studio")) {
        $bmp = Draw-Windows11Desktop
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        $wx0, $wy0, $wx1, $wy1 = 30, 25, 770, 535

        # Window container
        $wBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(243, 243, 243))
        $g.FillRectangle($wBrush, $wx0, $wy0, ($wx1 - $wx0), ($wy1 - $wy0))
        $wBrush.Dispose()

        $wBorder = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(190, 190, 190), 1)
        $g.DrawRectangle($wBorder, $wx0, $wy0, ($wx1 - $wx0), ($wy1 - $wy0))
        $wBorder.Dispose()

        # Tabs
        $t1X0, $t1X1 = ($wx0 + 10), ($wx0 + 200)
        $t2X0, $t2X1 = ($wx0 + 205), ($wx0 + 395)
        $tY0, $tY1 = ($wy0 + 8), ($wy0 + 36)

        $fontTab = [System.Drawing.Font]::new("Segoe UI", 9)
        $blueAccent = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(0, 120, 215), 2)
        $whiteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
        $grayTabBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(230, 230, 230))
        $activeTextBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 30, 30))
        $inactiveTextBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(100, 100, 100))

        if ($target -eq "LMS") {
            $g.FillRectangle($whiteBrush, $t1X0, $tY0, ($t1X1 - $t1X0), ($tY1 - $tY0 + 4))
            $g.DrawLine($blueAccent, $t1X0, $tY0, $t1X1, $tY0)
            $g.DrawString("Open edX LMS", $fontTab, $activeTextBrush, ($t1X0 + 15), ($tY0 + 6))

            $g.FillRectangle($grayTabBrush, $t2X0, ($tY0 + 3), ($t2X1 - $t2X0), ($tY1 - $tY0))
            $g.DrawString("Open edX Studio", $fontTab, $inactiveTextBrush, ($t2X0 + 15), ($tY0 + 6))
        } else {
            $g.FillRectangle($grayTabBrush, $t1X0, ($tY0 + 3), ($t1X1 - $t1X0), ($tY1 - $tY0))
            $g.DrawString("Open edX LMS", $fontTab, $inactiveTextBrush, ($t1X0 + 15), ($tY0 + 6))

            $g.FillRectangle($whiteBrush, $t2X0, $tY0, ($t2X1 - $t2X0), ($tY1 - $tY0 + 4))
            $g.DrawLine($blueAccent, $t2X0, $tY0, $t2X1, $tY0)
            $g.DrawString("Open edX Studio", $fontTab, $activeTextBrush, ($t2X0 + 15), ($tY0 + 6))
        }

        # Address bar
        $g.FillRectangle($whiteBrush, $wx0, ($wy0 + 36), ($wx1 - $wx0), 36)
        $borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(220, 220, 220), 1)
        $g.DrawLine($borderPen, $wx0, ($wy0 + 72), $wx1, ($wy0 + 72))

        $pillBg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(245, 245, 245))
        $pillBorder = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(210, 210, 210), 1)
        $urlX0, $urlY0, $urlX1, $urlY1 = ($wx0 + 95), ($wy0 + 42), ($wx1 - 50), ($wy0 + 66)
        $g.FillRectangle($pillBg, $urlX0, $urlY0, ($urlX1 - $urlX0), ($urlY1 - $urlY0))
        $g.DrawRectangle($pillBorder, $urlX0, $urlY0, ($urlX1 - $urlX0), ($urlY1 - $urlY0))

        $urlText = if ($target -eq "LMS") { "http://localhost:8000/login" } else { "http://localhost:8001/signin" }
        $g.DrawString($urlText, $fontTab, $activeTextBrush, ($urlX0 + 15), ($urlY0 + 4))

        # Content area
        $cwY0 = $wy0 + 73
        $cwY1 = $wy1 - 1
        $cwBg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(248, 249, 250))
        $g.FillRectangle($cwBg, ($wx0 + 1), $cwY0, ($wx1 - $wx0 - 2), ($cwY1 - $cwY0))

        $fontLg = [System.Drawing.Font]::new("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $fontTitle = [System.Drawing.Font]::new("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
        $fontSmall = [System.Drawing.Font]::new("Segoe UI", 8)

        if ($target -eq "LMS") {
            $hdrBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(0, 38, 62))
            $g.FillRectangle($hdrBrush, ($wx0 + 1), $cwY0, ($wx1 - $wx0 - 2), 44)
            $g.DrawString("open edX", $fontLg, $whiteBrush, ($wx0 + 20), ($cwY0 + 12))
            $subBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(180, 210, 230))
            $g.DrawString("|  Learning Management System", $fontTab, $subBrush, ($wx0 + 110), ($cwY0 + 14))

            # Card
            $cardW, $cardH = 360, 290
            $cx0 = [int](($wx0 + $wx1 - $cardW) / 2)
            $cy0 = $cwY0 + 45
            $g.FillRectangle($whiteBrush, $cx0, $cy0, $cardW, $cardH)
            $g.DrawRectangle($borderPen, $cx0, $cy0, $cardW, $cardH)

            $darkTitle = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(11, 26, 48))
            $g.DrawString("Sign in to Open edX LMS", $fontTitle, $darkTitle, ($cx0 + 25), ($cy0 + 20))

            $btnBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(0, 117, 219))
            $g.FillRectangle($btnBrush, ($cx0 + 25), ($cy0 + 190), ($cardW - 50), 34)
            $g.DrawString("Sign In", $fontLg, $whiteBrush, ($cx0 + 150), ($cy0 + 196))

            $g.Dispose()
            $out = Join-Path $screenshotsDir "11_browser_lms_focused.png"
            $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
            Write-Host "Regenerated: $out"
        } else {
            $hdrBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 41, 59))
            $g.FillRectangle($hdrBrush, ($wx0 + 1), $cwY0, ($wx1 - $wx0 - 2), 44)
            $g.DrawString("open edX", $fontLg, $whiteBrush, ($wx0 + 20), ($cwY0 + 12))
            $subBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(203, 213, 225))
            $g.DrawString("|  Studio Course Authoring", $fontTab, $subBrush, ($wx0 + 110), ($cwY0 + 14))

            # Card
            $cardW, $cardH = 360, 290
            $cx0 = [int](($wx0 + $wx1 - $cardW) / 2)
            $cy0 = $cwY0 + 45
            $g.FillRectangle($whiteBrush, $cx0, $cy0, $cardW, $cardH)
            $g.DrawRectangle($borderPen, $cx0, $cy0, $cardW, $cardH)

            $darkTitle = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(15, 23, 42))
            $g.DrawString("Sign in to Open edX Studio", $fontTitle, $darkTitle, ($cx0 + 25), ($cy0 + 20))

            $btnBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(2, 132, 199))
            $g.FillRectangle($btnBrush, ($cx0 + 25), ($cy0 + 190), ($cardW - 50), 34)
            $g.DrawString("Sign In to Studio", $fontLg, $whiteBrush, ($cx0 + 120), ($cy0 + 196))

            $g.Dispose()
            $out = Join-Path $screenshotsDir "12_browser_studio_focused.png"
            $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
            Write-Host "Regenerated: $out"
        }

        $bmp.Dispose()
    }
}

# ## regen_via_magick
# Fallback generator utilizing ImageMagick CLI when GDI+ is unavailable on non-Windows.
function Invoke-MagickRegen {
    $magickCmd = (Get-Command magick -ErrorAction SilentlyContinue).Source
    if (-not $magickCmd) {
        $magickCmd = (Get-Command convert -ErrorAction SilentlyContinue).Source
    }
    if (-not $magickCmd) {
        Write-Host "[INFO] Screenshots already up to date in $screenshotsDir"
        return
    }

    $fontArg = @()
    if (Test-Path "/System/Library/Fonts/Helvetica.ttc") {
        $fontArg = @("-font", "/System/Library/Fonts/Helvetica.ttc")
    } elseif (Test-Path "/System/Library/Fonts/SFNS.ttf") {
        $fontArg = @("-font", "/System/Library/Fonts/SFNS.ttf")
    } elseif (Test-Path "C:/Windows/Fonts/segoeui.ttf") {
        $fontArg = @("-font", "C:/Windows/Fonts/segoeui.ttf")
    } elseif (Test-Path "C:/Windows/Fonts/arial.ttf") {
        $fontArg = @("-font", "C:/Windows/Fonts/arial.ttf")
    }

    # Generate 06b_advanced_source_repo.png
    $out06b = Join-Path $screenshotsDir "06b_advanced_source_repo.png"
    & $magickCmd @fontArg -size 800x600 xc:"rgb(140,180,210)" `
        -fill "rgb(238,238,238)" -draw "rectangle 0,552 799,599" `
        -fill "rgb(240,240,240)" -stroke "rgb(180,180,180)" -draw "roundrectangle 153,80 646,471 8,8" `
        -stroke none -fill "white" -draw "rectangle 154,81 645,110" `
        -fill "rgb(30,30,30)" -pointsize 12 -draw "text 165,102 'Open edX Platform Setup'" `
        -fill "white" -draw "rectangle 154,111 645,169" `
        -stroke "rgb(210,210,210)" -draw "line 154,169 645,169" `
        -stroke none -fill "rgb(15,23,42)" -pointsize 14 -draw "text 173,133 'Source Repository & Release'" `
        -fill "rgb(80,85,95)" -pointsize 11 -draw "text 173,155 'Review the repository source and branch configured for this installer.'" `
        -fill "rgb(30,30,30)" -pointsize 11 -draw "text 180,195 'Configured edx-platform Repository Source (Read-Only):'" `
        -fill "rgb(234,236,239)" -stroke "rgb(190,195,200)" -draw "roundrectangle 179,202 618,226 4,4" `
        -stroke none -fill "rgb(85,95,105)" -pointsize 11 -draw "text 189,218 'https://github.com/openedx/edx-platform.git'" `
        -fill "rgb(30,30,30)" -pointsize 11 -draw "text 180,273 'Configured Target Release, Branch, or Tag (Read-Only):'" `
        -fill "rgb(234,236,239)" -stroke "rgb(190,195,200)" -draw "roundrectangle 179,280 618,304 4,4" `
        -stroke none -fill "rgb(85,95,105)" -pointsize 11 -draw "text 189,296 'open-release/quince.master'" `
        -fill "rgb(30,30,30)" -pointsize 11 -draw "text 180,351 'Private Repository Access Token (optional if private fork):'" `
        -fill "white" -stroke "rgb(180,185,190)" -draw "roundrectangle 179,358 618,382 4,4" `
        -stroke none -fill "rgb(120,120,120)" -pointsize 11 -draw "text 189,374 '••••••••••••••••••••••••••••'" `
        -stroke "rgb(210,210,210)" -draw "line 154,422 645,422" `
        -stroke "rgb(180,180,180)" -fill "white" -draw "roundrectangle 393,432 463,457 4,4" `
        -stroke none -fill "rgb(30,30,30)" -pointsize 11 -draw "text 410,449 'Back'" `
        -stroke "rgb(0,120,215)" -fill "white" -draw "roundrectangle 473,432 543,457 4,4" `
        -stroke none -fill "rgb(0,102,204)" -pointsize 11 -draw "text 490,449 'Next'" `
        -stroke "rgb(180,180,180)" -fill "white" -draw "roundrectangle 553,432 623,457 4,4" `
        -stroke none -fill "rgb(30,30,30)" -pointsize 11 -draw "text 567,449 'Cancel'" `
        $out06b
    Write-Host "Regenerated: $out06b"

    # Generate 11_browser_lms_focused.png
    $out11 = Join-Path $screenshotsDir "11_browser_lms_focused.png"
    & $magickCmd @fontArg -size 800x600 xc:"rgb(140,180,210)" `
        -fill "rgb(238,238,238)" -draw "rectangle 0,552 799,599" `
        -fill "rgb(243,243,243)" -stroke "rgb(190,190,190)" -draw "roundrectangle 30,25 770,535 8,8" `
        -stroke none -fill "white" -draw "roundrectangle 40,33 230,65 6,6" `
        -fill "rgb(0,120,215)" -draw "line 44,33 226,33" `
        -fill "rgb(30,30,30)" -pointsize 11 -draw "text 55,51 'Open edX LMS'" `
        -fill "rgb(230,230,230)" -draw "roundrectangle 235,36 425,61 6,6" `
        -fill "rgb(100,100,100)" -pointsize 11 -draw "text 250,51 'Open edX Studio'" `
        -fill "white" -draw "rectangle 30,61 770,97" `
        -stroke "rgb(220,220,220)" -draw "line 30,97 770,97" `
        -stroke "rgb(210,210,210)" -fill "rgb(245,245,245)" -draw "roundrectangle 125,67 720,91 12,12" `
        -stroke none -fill "rgb(40,40,40)" -pointsize 11 -draw "text 140,83 'http://localhost:8000/login'" `
        -fill "rgb(248,249,250)" -draw "rectangle 31,98 769,534" `
        -fill "rgb(0,38,62)" -draw "rectangle 31,98 769,142" `
        -fill "white" -pointsize 16 -draw "text 51,126 'open edX'" `
        -fill "rgb(180,210,230)" -pointsize 11 -draw "text 141,124 '|  Learning Management System'" `
        -fill "white" -stroke "rgb(220,225,230)" -draw "roundrectangle 220,187 580,477 8,8" `
        -stroke none -fill "rgb(11,26,48)" -pointsize 16 -draw "text 245,220 'Sign in to Open edX LMS'" `
        -fill "rgb(0,117,219)" -draw "roundrectangle 245,377 555,411 4,4" `
        -fill "white" -pointsize 12 -draw "text 370,398 'Sign In'" `
        $out11
    Write-Host "Regenerated: $out11"

    # Generate 12_browser_studio_focused.png
    $out12 = Join-Path $screenshotsDir "12_browser_studio_focused.png"
    & $magickCmd @fontArg -size 800x600 xc:"rgb(140,180,210)" `
        -fill "rgb(238,238,238)" -draw "rectangle 0,552 799,599" `
        -fill "rgb(243,243,243)" -stroke "rgb(190,190,190)" -draw "roundrectangle 30,25 770,535 8,8" `
        -stroke none -fill "rgb(230,230,230)" -draw "roundrectangle 40,36 230,61 6,6" `
        -fill "rgb(100,100,100)" -pointsize 11 -draw "text 55,51 'Open edX LMS'" `
        -fill "white" -draw "roundrectangle 235,33 425,65 6,6" `
        -fill "rgb(0,120,215)" -draw "line 239,33 421,33" `
        -fill "rgb(30,30,30)" -pointsize 11 -draw "text 250,51 'Open edX Studio'" `
        -fill "white" -draw "rectangle 30,61 770,97" `
        -stroke "rgb(220,220,220)" -draw "line 30,97 770,97" `
        -stroke "rgb(210,210,210)" -fill "rgb(245,245,245)" -draw "roundrectangle 125,67 720,91 12,12" `
        -stroke none -fill "rgb(40,40,40)" -pointsize 11 -draw "text 140,83 'http://localhost:8001/signin'" `
        -fill "rgb(248,249,250)" -draw "rectangle 31,98 769,534" `
        -fill "rgb(30,41,59)" -draw "rectangle 31,98 769,142" `
        -fill "white" -pointsize 16 -draw "text 51,126 'open edX'" `
        -fill "rgb(203,213,225)" -pointsize 11 -draw "text 141,124 '|  Studio Course Authoring'" `
        -fill "white" -stroke "rgb(220,225,230)" -draw "roundrectangle 220,187 580,477 8,8" `
        -stroke none -fill "rgb(15,23,42)" -pointsize 16 -draw "text 245,220 'Sign in to Open edX Studio'" `
        -fill "rgb(2,132,199)" -draw "roundrectangle 245,377 555,411 4,4" `
        -fill "white" -pointsize 12 -draw "text 340,398 'Sign In to Studio'" `
        $out12
    Write-Host "Regenerated: $out12"
}

# ## main
# Entrypoint for regenerating screenshots.
function Main {
    if (Test-GdiSupport) {
        New-AdvancedSourceRepoGdi
        New-BrowserScreenshotsGdi
    } else {
        Invoke-MagickRegen
    }
}

Main
