<#
## Overview
Generates HTML documentation from markdown sources.

## Usage
./devtools/generate_html_docs.ps1 [OPTIONS]
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Write-Host "Usage: generate_html_docs.ps1 [OPTIONS]"
    Write-Host "See script implementation or documentation for more details."
    exit 0
}

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LIBSCRIPT_ROOT_DIR = $env:LIBSCRIPT_ROOT_DIR
if (-not $LIBSCRIPT_ROOT_DIR) {
    $d = $SCRIPT_DIR
    while (-not (Test-Path (Join-Path $d "libscript.cmd")) -and -not (Test-Path (Join-Path $d "ROOT"))) {
        $parent = Split-Path -Parent $d
        if (-not $parent -or $parent -eq $d) { break }
        $d = $parent
    }
    $LIBSCRIPT_ROOT_DIR = $d
}
$env:LIBSCRIPT_ROOT_DIR = $LIBSCRIPT_ROOT_DIR

$LIBSCRIPT_DOCS_DIR = $env:LIBSCRIPT_DOCS_DIR
if (-not $LIBSCRIPT_DOCS_DIR) {
    $LIBSCRIPT_DOCS_DIR = Join-Path $LIBSCRIPT_ROOT_DIR "docs\latest"
}
$env:LIBSCRIPT_DOCS_DIR = $LIBSCRIPT_DOCS_DIR

$LIBSCRIPT_ASSETS_DIR = $env:LIBSCRIPT_ASSETS_DIR
if (-not $LIBSCRIPT_ASSETS_DIR) {
    $LIBSCRIPT_ASSETS_DIR = $LIBSCRIPT_DOCS_DIR
}
$env:LIBSCRIPT_ASSETS_DIR = $LIBSCRIPT_ASSETS_DIR

$HTML_ROOT = $env:HTML_ROOT
if (-not $HTML_ROOT) {
    $HTML_ROOT = Join-Path $LIBSCRIPT_ROOT_DIR "docs-web-template"
}
$env:HTML_ROOT = $HTML_ROOT

$GIT_REPO = $env:GIT_REPO
if (-not $GIT_REPO) {
    $GIT_REPO = "https://github.com/SamuelMarks/libscript"
}
$env:GIT_REPO = $GIT_REPO
$env:LIBSCRIPT_EXTENDED_SCHEMAS = "topologies/topology.schema.json topologies/topology-state.schema.json payloads/payload.schema.json traits/trait.schema.json _lib/_common/manifest.schema.json"

# ## Invoke-EnvSubst
# Replaces environment variables in the provided template string.
function Invoke-EnvSubst {
    param([string]$TemplateContent)
    if ([string]::IsNullOrEmpty($TemplateContent)) { return $TemplateContent }
    
    $result = $TemplateContent
    $vars = [Environment]::GetEnvironmentVariables()
    foreach ($key in $vars.Keys) {
        $val = $vars[$key]
        if ($val -ne $null) {
            $escapedVal = $val -replace '\$', '$$$$'
            $result = $result -replace ("\$\{?" + [regex]::Escape($key) + "\}?"), $escapedVal
        }
    }
    return $result
}

if (-not (Test-Path $LIBSCRIPT_DOCS_DIR)) {
    New-Item -ItemType Directory -Force -Path $LIBSCRIPT_DOCS_DIR | Out-Null
}

$URLS_JS_List = @()
$URLS_List = @()

$LIBSCRIPT_DOCS_PREFIX = $env:LIBSCRIPT_DOCS_PREFIX

$mdFiles = Get-ChildItem -Path $LIBSCRIPT_ROOT_DIR -Filter "*.md" -Recurse | Where-Object { $_.FullName -notmatch "node_modules" }

foreach ($file in $mdFiles) {
    $relativePath = $file.FullName.Substring($LIBSCRIPT_ROOT_DIR.Length).TrimStart('\', '/')
    $outPath = Join-Path $LIBSCRIPT_DOCS_DIR $relativePath
    $parent = Split-Path -Parent $outPath
    
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    
    $htmlPath = $outPath.Substring(0, $outPath.Length - 3) + ".html"
    
    Copy-Item (Join-Path $HTML_ROOT "top.html") -Destination $htmlPath -Force
    
    $mdContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    if ($null -ne $mdContent) {
        $mdContent = $mdContent -replace "\.md\)", ".html)"
        $pandocIn = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllText($pandocIn, $mdContent, [System.Text.Encoding]::UTF8)
        
        $pandocOut = [System.IO.Path]::GetTempFileName()
        $pandocArgs = @("-f", "markdown", "-t", "html5", "-o", $pandocOut, $pandocIn)
        try {
            & pandoc $pandocArgs
            $htmlContent = [System.IO.File]::ReadAllText($pandocOut, [System.Text.Encoding]::UTF8)
            Add-Content -Path $htmlPath -Value $htmlContent -Encoding UTF8
        } catch {
            Write-Warning "Failed to run pandoc on $($file.FullName)"
        }
        
        Remove-Item $pandocIn -Force
        Remove-Item $pandocOut -Force
    }
    
    $baseName = $htmlPath.Substring(0, $htmlPath.Length - 5)
    $schemaOut = $baseName + ".schema.json"
    $usageOut = $htmlPath + ".usage"
    
    if (Test-Path $schemaOut) { Remove-Item $schemaOut -Force }
    if (Test-Path $usageOut) { Remove-Item $usageOut -Force }
    
    $new_wd = Split-Path -Parent $file.FullName
    $schemaFiles = Get-ChildItem -Path $new_wd -Filter "*.schema.json" -File
    
    foreach ($schemaFile in $schemaFiles) {
        $schemaName = $schemaFile.Name
        if ($schemaName -match "installer\.schema\.json") { continue }
        
        $PORT_PATH = ""
        $idx = $new_wd.IndexOf("libscript")
        if ($idx -ge 0) {
            $PORT_PATH = $new_wd.Substring($idx + 9).Replace('\', '/').TrimStart('/')
        }
        
        $env:PORT_PATH = $PORT_PATH
        $env:PORT_PATH_WIN = $PORT_PATH.Replace('/', '\')
        
        $usageTemplate = Get-Content (Join-Path $HTML_ROOT "usage.html") -Raw
        $usageSubst = Invoke-EnvSubst -TemplateContent $usageTemplate
        Add-Content -Path $usageOut -Value $usageSubst
        
        Add-Content -Path $htmlPath -Value '${USAGE}'
        
        try {
            $compactSchema = & jq -c . $schemaFile.FullName
            Add-Content -Path $schemaOut -Value $compactSchema
        } catch {
            Write-Warning "Failed to run jq on $($schemaFile.FullName)"
        }
    }
    
    $bottomHtml = Get-Content (Join-Path $HTML_ROOT "bottom.html") -Raw
    Add-Content -Path $htmlPath -Value $bottomHtml
    
    $urlPath = $relativePath.Replace('\', '/')
    $urlPath = $urlPath.Substring(0, $urlPath.Length - 3) + ".html"
    
    if ($LIBSCRIPT_DOCS_PREFIX) {
        $URLS_JS_List += "`"$urlPath`""
        $URLS_List += $urlPath
    } else {
        $URLS_JS_List += "`"$urlPath`""
        $URLS_List += $urlPath
    }
}

$URLS_JS = "[" + ($URLS_JS_List -join ",") + "]"

foreach ($url in $URLS_List) {
    $fullUrl = Join-Path $LIBSCRIPT_DOCS_DIR $url
    $title = Split-Path -Leaf $url
    $p = Split-Path -Parent $url
    $pLeaf = Split-Path -Leaf $p
    
    if ($title -eq 'README.html') {
        $title = $pLeaf
    } else {
        if ($pLeaf) {
            $title = $pLeaf + '/' + $title
        }
    }
    
    if ($LIBSCRIPT_DOCS_PREFIX) {
        $url = $LIBSCRIPT_DOCS_PREFIX + '/' + $url
    }
    
    $USAGE = ""
    $SCHEMA = ""
    
    $parentDir = Split-Path -Parent $fullUrl
    $usageFiles = Get-ChildItem -Path $parentDir -Filter "*.usage" -File
    foreach ($uf in $usageFiles) {
        $USAGE += Get-Content $uf.FullName -Raw
        $sFiles = Get-ChildItem -Path $parentDir -Filter "*.schema.json" -File
        foreach ($sf in $sFiles) {
            $SCHEMA += Get-Content $sf.FullName -Raw
        }
    }
    
    $URL_PATHNAME = $url
    if ($LIBSCRIPT_DOCS_PREFIX) {
        $URL_PATHNAME = $URL_PATHNAME.Replace($LIBSCRIPT_DOCS_PREFIX, "")
    }
    $URL_PATHNAME = $URL_PATHNAME.TrimStart('/')
    
    $gitPath = $URL_PATHNAME.Replace('\', '/')
    $gitPath = $gitPath -replace "^docs", "blob" -replace "latest", "master" -replace "\.html$", ".md"
    $GIT_HTTP_LINK = $GIT_REPO + "/" + $gitPath
    
    $env:url = $url
    $env:TITLE = $title -replace "\.html$", ""
    $env:LIBSCRIPT_DOCS_DIR = $LIBSCRIPT_DOCS_DIR.Replace(".\", "")
    $env:LIBSCRIPT_ASSETS_DIR = $LIBSCRIPT_ASSETS_DIR
    $env:USAGE = $USAGE
    $env:URL_PATHNAME = $URL_PATHNAME
    $env:GIT_HTTP_LINK = $GIT_HTTP_LINK
    
    $fullHtml = Get-Content $fullUrl -Raw
    $substHtml = Invoke-EnvSubst -TemplateContent $fullHtml
    
    $githubBadge = '<a class="right" href="' + $GIT_HTTP_LINK + '" aria-label="Open on GitHub"><img class="deploy-img" src="/assets/github-badge-small.png" alt="Open on GitHub"/></a>'
    $substHtml = $substHtml -replace "(?i)(</h1>)", ($githubBadge + "`n`$1")
    
    if ($USAGE) {
        $schemaObj = $null
        try {
            if ($SCHEMA) {
                $schemaObj = $SCHEMA | ConvertFrom-Json
            }
        } catch { }
        
        $STATIC_FORM_HTML = ""
        if ($schemaObj -and $schemaObj.properties) {
            $max_len = 0
            $props = $schemaObj.properties.PSObject.Properties
            foreach ($pProp in $props) {
                if ($pProp.Name.Length -gt $max_len) { $max_len = $pProp.Name.Length }
            }
            
            foreach ($pProp in $props) {
                $clean_key = $pProp.Name.TrimStart('[').TrimEnd(']')
                $dots_len = $max_len - $pProp.Name.Length + 20
                $label_text = $clean_key + ("." * $dots_len) + ": "
                $desc = ""
                if ($pProp.Value.description) { $desc = $pProp.Value.description.Replace('"', '&quot;') }
                
                $inputType = "text"
                if ($clean_key -match "SECRET|PASSWORD") { $inputType = "password" }
                
                $STATIC_FORM_HTML += @"
<div class="flex">
  <label for="$clean_key" class="flex-item" id="label-$clean_key" style="white-space: pre;">$label_text</label>
  <input class="tui-input flex-item" name="$clean_key" id="$clean_key" placeholder="$desc" type="$inputType" />
</div>
"@ + "`n"
            }
        }
        
        $after_first_header = @"
<div class="tui-window" style="width: 100%">
  <fieldset class="tui-fieldset">
  <legend class="center">1-click deploy</legend>
  <ul class="flex-ul-prefer-hor">
    <li><a onclick="TODO()"><img class="deploy-img" src="https://aka.ms/deploytoazurebutton" alt="Deploy to Azure"/></a></li>
    <li><a onclick="TODO()"><img class="deploy-img" src="https://www.deploytodo.com/do-btn-blue.svg" alt="Deploy to Digital Ocean"/></a></li>
    <li><a onclick="TODO()"><img class="deploy-img" src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" alt="Deploy to AWS"></a></li>
  </ul>
  </fieldset>
</div>

<h2 class="line-beside">or</h2>

<div class="tui-window" style="width: 100%">
  <form iD="twoClickForm" action="" methoD="get">
    <fieldset class="tui-fieldset">
      <legend class="center">2-click deploy</legend>
      <div class="flex">
        <label for="cname" class="flex-item" style="white-space: pre;">CNAME.........................: </label><input class="tui-input flex-item" name="cname" iD="cname" placeholder="Domain name" />
      </div>
      <div class="flex">
        <label for="log_server" class="flex-item" style="white-space: pre;">Metrics/logs (server).........: </label><input class="tui-input flex-item" name="log_server" iD="log_server" placeholder="If == ↑domain then deploy"/>
      </div>
      <div class="flex">
        <label for="backup_url" class="flex-item" style="white-space: pre;">Backup (object storage).......: </label><input class="tui-input flex-item" name="backup_url" iD="backup_url" placeholder="Object storage—e.g., s3—URL"/>
      </div>

      <div class="flex-col">
$STATIC_FORM_HTML
      </div>

      <div class="flex">
        <button class="tui-button" iD="submit" type="submit">Set vars</button>
      </div>

      <ul class="flex-ul-prefer-hor">
        <li><button type="submit" iD="azure_button" formaction="https://azure/" formenctype="text/plain" onclick="twoClickDeploy(this)"><img class="deploy-img" src="https://aka.ms/deploytoazurebutton" alt="Deploy to Azure"/></button></li>
        <li><button type="submit" iD="digitalocean_button" formaction="https://digitalocean/" formenctype="text/plain" onclick="twoClickDeploy(this)"><img class="deploy-img" src="https://www.deploytodo.com/do-btn-blue.svg" alt="Deploy to Digital Ocean"/></button></li>
        <li><button type="submit" iD="aws_button" formaction="https://amazonaws/" formenctype="text/plain" onclick="twoClickDeploy(this)"><img class="deploy-img" src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" alt="Deploy to AWS"></button></li>
      </ul>
    </fieldset>
  </form>
</div>
"@
        
        $substHtml = $substHtml -replace "(?i)(</h1>)", ("`$1`n" + $after_first_header)
    }
    
    Set-Content -Path $fullUrl -Value $substHtml -Encoding UTF8
}

if (-not (Test-Path $LIBSCRIPT_ASSETS_DIR)) {
    New-Item -ItemType Directory -Force -Path $LIBSCRIPT_ASSETS_DIR | Out-Null
}

$assetsSrc = Join-Path $HTML_ROOT "assets"
if ($assetsSrc -ne $LIBSCRIPT_ASSETS_DIR -and (Test-Path $assetsSrc)) {
    Copy-Item -Path "$assetsSrc\*" -Destination $LIBSCRIPT_ASSETS_DIR -Recurse -Force
}

$tuicssSrc = Join-Path $LIBSCRIPT_ROOT_DIR "node_modules\tuicss\dist"
if (Test-Path $tuicssSrc) {
    Copy-Item -Path "$tuicssSrc\*" -Destination $LIBSCRIPT_ASSETS_DIR -Recurse -Force
}

$env:URLS = $URLS_JS
$firstScriptsHtml = Get-Content (Join-Path $assetsSrc "first_scripts.js") -Raw
$firstScriptsSubst = Invoke-EnvSubst -TemplateContent $firstScriptsHtml
Set-Content -Path (Join-Path $LIBSCRIPT_ASSETS_DIR "first_scripts.js") -Value $firstScriptsSubst -Encoding UTF8

$globalAssets = Join-Path $LIBSCRIPT_ROOT_DIR "assets"
if (-not (Test-Path $globalAssets)) {
    New-Item -ItemType Directory -Force -Path $globalAssets | Out-Null
}

if ($LIBSCRIPT_ASSETS_DIR -ne $globalAssets) {
    Get-ChildItem -Path $LIBSCRIPT_ASSETS_DIR -Filter "*.css" | Copy-Item -Destination $globalAssets -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $LIBSCRIPT_ASSETS_DIR -Filter "*.js" | Copy-Item -Destination $globalAssets -Force -ErrorAction SilentlyContinue
}

$assetsImages = Join-Path $LIBSCRIPT_ASSETS_DIR "images"
if (Test-Path $assetsImages) {
    Copy-Item -Path "$assetsImages\*" -Destination $globalAssets -Recurse -Force
}

$vermanAssets = Join-Path $LIBSCRIPT_ROOT_DIR "..\verman-tui-www\assets"
if (Test-Path $vermanAssets) {
    Copy-Item -Path "$vermanAssets\*" -Destination $globalAssets -Recurse -Force
}
