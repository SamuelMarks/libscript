# ## Overview
# Generates official Open edX branded bitmaps, multi-resolution icons, and
# license agreements conforming to WiX MSI packaging specifications on the fly.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/generate_openedx_branding.ps1 [-OutputDir DIR]

<#
.SYNOPSIS
Generates official Open edX branding assets (BMP banners, ICO, and RTF EULA).
#>

[CmdletBinding()]
param(
    [Alias("o")]
    [string]$OutputDir
)

$NAVY = @(0, 38, 62)        # #00263E
$BLUE = @(0, 117, 180)      # #0075B4
$RED = @(178, 6, 0)         # #B20600
$WHITE = @(255, 255, 255)
$LIGHT_GRAY = @(220, 226, 232)
$LINE_GRAY = @(200, 205, 210)

# ## resolve_output_dir
# Resolves the target asset output directory from parameter or defaults.
function Resolve-OutputDir {
    if (-not $OutputDir) {
        for ($i = 0; $i -lt $args.Count; $i++) {
            if ($args[$i] -eq "--output-dir" -or $args[$i] -eq "-o") {
                if ($i + 1 -lt $args.Count) {
                    $script:OutputDir = $args[$i + 1]
                    break
                }
            }
        }
    }
    if (-not $OutputDir) {
        $script:OutputDir = Join-Path $PSScriptRoot "assets"
    }
    if (-not (Test-Path $OutputDir)) {
        [System.IO.Directory]::CreateDirectory($OutputDir) | Out-Null
    }
}

# ## new_bmp_raw
# Creates an uncompressed 24-bit RGB BMP byte stream without external dependencies.
function New-BmpRaw([int]$width, [int]$height, [scriptblock]$colorFunc) {
    $rowBytes = $width * 3
    $padding = (4 - ($rowBytes % 4)) % 4
    $imageSize = ($rowBytes + $padding) * $height
    $fileSize = 54 + $imageSize

    $ms = [System.IO.MemoryStream]::new()
    $bw = [System.IO.BinaryWriter]::new($ms)

    # BITMAPFILEHEADER (14 bytes)
    $bw.Write([byte]0x42) # 'B'
    $bw.Write([byte]0x4D) # 'M'
    $bw.Write([uint32]$fileSize)
    $bw.Write([uint16]0)
    $bw.Write([uint16]0)
    $bw.Write([uint32]54)

    # BITMAPINFOHEADER (40 bytes)
    $bw.Write([uint32]40)
    $bw.Write([int32]$width)
    $bw.Write([int32]$height)
    $bw.Write([uint16]1)   # planes
    $bw.Write([uint16]24)  # bpp
    $bw.Write([uint32]0)   # compression (BI_RGB)
    $bw.Write([uint32]$imageSize)
    $bw.Write([int32]2835) # X pixels per meter
    $bw.Write([int32]2835) # Y pixels per meter
    $bw.Write([uint32]0)   # colors used
    $bw.Write([uint32]0)   # colors important

    $padBytes = [byte[]]::new($padding)

    # BMP pixels stored bottom-up
    for ($y = $height - 1; $y -ge 0; $y--) {
        for ($x = 0; $x -lt $width; $x++) {
            $col = & $colorFunc $x $y $width $height
            # BGR byte order
            $bw.Write([byte]$col[2])
            $bw.Write([byte]$col[1])
            $bw.Write([byte]$col[0])
        }
        if ($padding -gt 0) {
            $bw.Write($padBytes)
        }
    }

    $bw.Flush()
    $data = $ms.ToArray()
    $bw.Dispose()
    $ms.Dispose()
    return $data
}

# ## new_ico_raw
# Creates a multi-resolution ICO file without external dependencies.
function New-IcoRaw([int[]]$sizes, [scriptblock]$colorFunc) {
    $ms = [System.IO.MemoryStream]::new()
    $bw = [System.IO.BinaryWriter]::new($ms)

    # ICO Header: 6 bytes (Reserved=0, Type=1, Count=len(sizes))
    $bw.Write([uint16]0)
    $bw.Write([uint16]1)
    $bw.Write([uint16]$sizes.Length)

    $offset = 6 + $sizes.Length * 16
    $imagesData = [System.Collections.Generic.List[byte[]]]::new()

    foreach ($s in $sizes) {
        $imgMs = [System.IO.MemoryStream]::new()
        $imgBw = [System.IO.BinaryWriter]::new($imgMs)

        $width = $s
        $height = $s
        $rowBytes = $width * 4
        $imageSize = $rowBytes * $height
        $maskRow = [int](([math]::Floor(($width + 31) / 32)) * 4)
        $maskSize = $maskRow * $height

        # DIB header with height * 2 for XOR + AND masks
        $imgBw.Write([uint32]40)
        $imgBw.Write([int32]$width)
        $imgBw.Write([int32]($height * 2))
        $imgBw.Write([uint16]1)
        $imgBw.Write([uint16]32)
        $imgBw.Write([uint32]0)
        $imgBw.Write([uint32]($imageSize + $maskSize))
        $imgBw.Write([int32]0)
        $imgBw.Write([int32]0)
        $imgBw.Write([uint32]0)
        $imgBw.Write([uint32]0)

        for ($y = $height - 1; $y -ge 0; $y--) {
            for ($x = 0; $x -lt $width; $x++) {
                $col = & $colorFunc $x $y $s
                # BGRA order
                $imgBw.Write([byte]$col[2])
                $imgBw.Write([byte]$col[1])
                $imgBw.Write([byte]$col[0])
                $imgBw.Write([byte]$col[3])
            }
        }

        $andMask = [byte[]]::new($maskSize)
        $imgBw.Write($andMask)

        $imgBw.Flush()
        $imgBlob = $imgMs.ToArray()
        $imgBw.Dispose()
        $imgMs.Dispose()

        $imagesData.Add($imgBlob)

        # Directory entry (16 bytes)
        $wByte = if ($s -ge 256) { [byte]0 } else { [byte]$s }
        $hByte = if ($s -ge 256) { [byte]0 } else { [byte]$s }
        $bw.Write($wByte)
        $bw.Write($hByte)
        $bw.Write([byte]0)
        $bw.Write([byte]0)
        $bw.Write([uint16]1)
        $bw.Write([uint16]32)
        $bw.Write([uint32]$imgBlob.Length)
        $bw.Write([uint32]$offset)

        $offset += $imgBlob.Length
    }

    foreach ($blob in $imagesData) {
        $bw.Write($blob)
    }

    $bw.Flush()
    $data = $ms.ToArray()
    $bw.Dispose()
    $ms.Dispose()
    return $data
}

# ## create_side_banner
# Generates the 164x312 welcome dialog sidebar bitmap.
function New-SideBanner([string]$targetDir) {
    $outPath = Join-Path $targetDir "openedx_banner_side.bmp"
    $generatedWithDrawing = $false

    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $bmp = [System.Drawing.Bitmap]::new(164, 312)
        $g = [System.Drawing.Graphics]::FromImage($bmp)

        $navyBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(0, 38, 62))
        $blueBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(0, 117, 180))
        $redBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(178, 6, 0))
        $whiteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 255))
        $lightGrayBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 226, 232))

        $g.FillRectangle($navyBrush, 0, 0, 164, 312)
        $g.FillRectangle($blueBrush, 0, 306, 164, 6)

        $fontLogo = [System.Drawing.Font]::new("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
        $fontSub = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
        $fontTag = [System.Drawing.Font]::new("Segoe UI", 8, [System.Drawing.FontStyle]::Regular)

        $g.DrawString("open", $fontLogo, $whiteBrush, 16, 40)
        $logoSize = $g.MeasureString("open", $fontLogo)
        $edxX = 16 + $logoSize.Width - 4
        $g.DrawString("edX", $fontLogo, $blueBrush, $edxX, 40)
        $edxSize = $g.MeasureString("edX", $fontLogo)
        $dotX = $edxX + $edxSize.Width - 4
        $g.FillEllipse($redBrush, $dotX, 44, 6, 6)

        $g.DrawString("Open edX Platform", $fontSub, $whiteBrush, 16, 75)
        $g.DrawString("LMS & Studio CMS", $fontSub, $lightGrayBrush, 16, 92)

        $bluePen2 = [System.Drawing.Pen]::new($blueBrush, 2)
        $g.DrawLine($bluePen2, 16, 118, 148, 118)

        $g.DrawString("Core Stack:", $fontSub, $whiteBrush, 16, 130)
        $g.DrawString("• Python & Node.js", $fontTag, $lightGrayBrush, 16, 148)
        $g.DrawString("• Meilisearch Engine", $fontTag, $lightGrayBrush, 16, 164)
        $g.DrawString("• MySQL & Redis", $fontTag, $lightGrayBrush, 16, 180)
        $g.DrawString("• MongoDB Store", $fontTag, $lightGrayBrush, 16, 196)

        $bluePen1 = [System.Drawing.Pen]::new($blueBrush, 1)
        $g.DrawLine($bluePen1, 16, 222, 148, 222)

        $g.DrawString("Windows Native Setup", $fontTag, $lightGrayBrush, 16, 235)
        $g.DrawString("LibScript Deployment", $fontTag, $lightGrayBrush, 16, 252)

        $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Bmp)

        $g.Dispose()
        $bmp.Dispose()
        $navyBrush.Dispose()
        $blueBrush.Dispose()
        $redBrush.Dispose()
        $whiteBrush.Dispose()
        $lightGrayBrush.Dispose()
        $bluePen2.Dispose()
        $bluePen1.Dispose()
        $fontLogo.Dispose()
        $fontSub.Dispose()
        $fontTag.Dispose()
        $generatedWithDrawing = $true
    } catch {
        $generatedWithDrawing = $false
    }

    if (-not $generatedWithDrawing) {
        $sideColor = { param($x, $y, $w, $h)
            if ($y -ge 306) { return $script:BLUE }
            if ($y -ge 117 -and $y -le 119 -and $x -ge 16 -and $x -le 148) { return $script:BLUE }
            if ($y -ge 221 -and $y -le 223 -and $x -ge 16 -and $x -le 148) { return $script:BLUE }
            return $script:NAVY
        }
        $data = New-BmpRaw 164 312 $sideColor
        [System.IO.File]::WriteAllBytes($outPath, $data)
    }

    Write-Host "[OK] Generated $outPath (164x312)"
}

# ## create_top_banner
# Generates the 493x58 wizard header banner bitmap.
function New-TopBanner([string]$targetDir) {
    $outPath = Join-Path $targetDir "openedx_banner_top.bmp"
    $generatedWithDrawing = $false

    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $bmp = [System.Drawing.Bitmap]::new(493, 58)
        $g = [System.Drawing.Graphics]::FromImage($bmp)

        $whiteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 255))
        $navyBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(0, 38, 62))
        $blueBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(0, 117, 180))
        $redBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(178, 6, 0))
        $linePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(200, 205, 210), 1)

        $g.FillRectangle($whiteBrush, 0, 0, 493, 58)

        $font = [System.Drawing.Font]::new("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
        $logoX = 385
        $g.DrawString("open", $font, $navyBrush, $logoX, 16)
        $openSize = $g.MeasureString("open", $font)
        $edxX = $logoX + $openSize.Width - 4
        $g.DrawString("edX", $font, $blueBrush, $edxX, 16)
        $edxSize = $g.MeasureString("edX", $font)
        $dotX = $edxX + $edxSize.Width - 4
        $g.FillEllipse($redBrush, $dotX, 18, 6, 6)

        $g.DrawLine($linePen, 0, 57, 493, 57)

        $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Bmp)

        $g.Dispose()
        $bmp.Dispose()
        $whiteBrush.Dispose()
        $navyBrush.Dispose()
        $blueBrush.Dispose()
        $redBrush.Dispose()
        $linePen.Dispose()
        $font.Dispose()
        $generatedWithDrawing = $true
    } catch {
        $generatedWithDrawing = $false
    }

    if (-not $generatedWithDrawing) {
        $topColor = { param($x, $y, $w, $h)
            if ($y -eq 57) { return $script:LINE_GRAY }
            return $script:WHITE
        }
        $data = New-BmpRaw 493 58 $topColor
        [System.IO.File]::WriteAllBytes($outPath, $data)
    }

    Write-Host "[OK] Generated $outPath (493x58)"
}

# ## create_icon
# Generates the multi-resolution application icon (openedx.ico).
function New-Icon([string]$targetDir) {
    $outPath = Join-Path $targetDir "openedx.ico"
    $sizes = @(256, 48, 32, 16)

    $iconColor = { param($x, $y, $s)
        $pad = [int]($s * 0.05)
        if ($x -ge $pad -and $x -lt ($s - $pad) -and $y -ge $pad -and $y -lt ($s - $pad)) {
            $cx = $s * 0.5
            $cy = $s * 0.5
            $dist = [math]::Sqrt([math]::Pow($x - $cx, 2) + [math]::Pow($y - $cy, 2))
            if ($dist -lt ($s * 0.2)) {
                return @(0, 117, 180, 255)
            }
            return @(0, 38, 62, 255)
        }
        return @(0, 0, 0, 0)
    }

    $data = New-IcoRaw $sizes $iconColor
    [System.IO.File]::WriteAllBytes($outPath, $data)
    Write-Host "[OK] Generated $outPath (multi-res ICO)"
}

# ## create_eula
# Generates the Rich Text Format (RTF) End User License Agreement.
function New-Eula([string]$targetDir) {
    $outPath = Join-Path $targetDir "openedx_eula.rtf"
    $content = @'
{\rtf1\ansi\deff0 {\fonttbl {\f0 Courier;}}\fs20
Open edX Community License Agreement\par
\par
This Open edX Windows deployment package is licensed under the terms of
the GNU Affero General Public License (AGPLv3) and respective dependency licenses.\par
\par
By proceeding with the installation, you agree to comply with all applicable terms.\par
}
'@

    $content += "`n";
    [System.IO.File]::WriteAllText($outPath, $content, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "[OK] Generated $outPath (RTF EULA)"
}

# ## main
# Entrypoint coordinating generation of all Open edX branding assets.
function Main {
    Resolve-OutputDir
    New-SideBanner $OutputDir
    New-TopBanner $OutputDir
    New-Icon $OutputDir
    New-Eula $OutputDir
}

Main
