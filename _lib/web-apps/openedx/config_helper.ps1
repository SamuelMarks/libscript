# cspell:words edxmako DJFS osfs pyfs localfs openassessment Cryptodome jwkest edxloggedin csrftoken MICROFRONTEND
# ## Overview
# Configuration helper utility for Open edX configuration management on Windows.
# Provides key inspection, mutation, full production lms.yml / cms.yml / revisions.yml / Caddyfile
# generation (including 2048-bit RSA JWK keys and Verawood MFE configuration), and syntax validation.
#
# ## Usage
# powershell _lib/web-apps/openedx/config_helper.ps1 get <conf_file> <key>
# powershell _lib/web-apps/openedx/config_helper.ps1 set <conf_file1> <conf_file2> <key> <val>
# powershell _lib/web-apps/openedx/config_helper.ps1 generate <conf_file1> <conf_file2>
# powershell _lib/web-apps/openedx/config_helper.ps1 validate <conf_file> <schema_file>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Action,
    [Parameter(Position = 1)]
    [string]$Arg1,
    [Parameter(Position = 2)]
    [string]$Arg2,
    [Parameter(Position = 3)]
    [string]$Arg3,
    [Parameter(Position = 4)]
    [string]$Arg4
)

# ## Show-Help
# Displays usage instructions.
function Show-Help {
    Write-Host "Usage: config_helper.ps1 get <conf_file> <key>"
    Write-Host "       config_helper.ps1 set <conf_file1> <conf_file2> <key> <val>"
    Write-Host "       config_helper.ps1 generate <conf_file1> <conf_file2>"
    Write-Host "       config_helper.ps1 validate <conf_file> <schema_file>"
    exit 0
}

# ## Do-Get
# Retrieves a dot-separated property value from a JSON/YAML file.
function Do-Get {
    param(
        [string]$ConfFile,
        [string]$Key
    )

    if (-not (Test-Path $ConfFile)) {
        exit 1
    }

    try {
        $raw = Get-Content -Path $ConfFile -Raw
        $json = ConvertFrom-Json $raw
        $parts = $Key.Split('.')
        $curr = $json
        foreach ($p in $parts) {
            if ($null -ne $curr -and $curr.PSObject.Properties[$p]) {
                $curr = $curr.$p
            } else {
                Write-Output "null"
                return
            }
        }
        if ($curr -is [PSCustomObject] -or $curr -is [System.Collections.IDictionary] -or $curr -is [System.Collections.IList]) {
            Write-Output (ConvertTo-Json $curr -Depth 10)
        } elseif ($null -eq $curr) {
            Write-Output "null"
        } else {
            Write-Output $curr
        }
    } catch {
        Write-Output "null"
    }
}

# ## Do-Set
# Sets a dot-separated property value across target JSON/YAML configuration files.
function Do-Set {
    param(
        [string[]]$ConfFiles,
        [string]$Key,
        [string]$Val
    )

    $parsedVal = $Val
    try {
        $parsedVal = ConvertFrom-Json $Val
    } catch {
        $parsedVal = $Val
    }

    foreach ($cf in $ConfFiles) {
        $parent = Split-Path -Parent $cf
        if (-not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        $dict = @{}
        if (Test-Path $cf) {
            try {
                $raw = Get-Content -Path $cf -Raw
                $dict = [System.Web.Script.Serialization.JavaScriptSerializer]::new().Deserialize([string]$raw, [hashtable])
            } catch {
                $dict = @{}
            }
        }
        if (-not ($dict -is [System.Collections.IDictionary])) {
            $dict = @{}
        }

        $parts = $Key.Split('.')
        $curr = $dict
        for ($i = 0; $i -lt $parts.Length - 1; $i++) {
            $p = $parts[$i]
            if (-not $curr.ContainsKey($p) -or -not ($curr[$p] -is [System.Collections.IDictionary])) {
                $curr[$p] = @{}
            }
            $curr = $curr[$p]
        }
        $curr[$parts[$parts.Length - 1]] = $parsedVal

        $jsonStr = ConvertTo-Json $dict -Depth 10
        Set-Content -Path $cf -Value $jsonStr -Encoding Ascii
    }

    $cfgDir = Split-Path -Parent $ConfFiles[0]
    if (Test-Path $ConfFiles[0]) { Copy-Item -Path $ConfFiles[0] -Destination (Join-Path $cfgDir "lms.yml") -Force }
    if ($ConfFiles.Length -gt 1 -and (Test-Path $ConfFiles[1])) { Copy-Item -Path $ConfFiles[1] -Destination (Join-Path $cfgDir "cms.yml") -Force }

    Write-Host "Updated $Key."
}

# ## New-RsaJwkPair
# Generates a 2048-bit RSA JWK public keyset and private JWK string using .NET RSACryptoServiceProvider.
function New-RsaJwkPair {
    try {
        $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider(2048)
        $params = $rsa.ExportParameters($true)
        $toB64Url = {
            param([byte[]]$bytes)
            [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        }
        $n = & $toB64Url $params.Modulus
        $e = & $toB64Url $params.Exponent
        $d = & $toB64Url $params.D
        $p = & $toB64Url $params.P
        $q = & $toB64Url $params.Q
        $dp = & $toB64Url $params.DP
        $dq = & $toB64Url $params.DQ
        $qi = & $toB64Url $params.InverseQ
        $pubSet = @{
            "keys" = @(
                @{
                    "kty" = "RSA"
                    "kid" = "openedx"
                    "alg" = "RS512"
                    "use" = "sig"
                    "n"   = $n
                    "e"   = $e
                }
            )
        } | ConvertTo-Json -Compress -Depth 6
        $privKey = @{
            "kty" = "RSA"
            "kid" = "openedx"
            "alg" = "RS512"
            "n"   = $n
            "e"   = $e
            "d"   = $d
            "p"   = $p
            "q"   = $q
            "dp"  = $dp
            "dq"  = $dq
            "qi"  = $qi
        } | ConvertTo-Json -Compress -Depth 6
        return @{ "pub" = $pubSet; "priv" = $privKey }
    } catch {
        return @{
            "pub"  = '{"keys":[{"kty":"RSA","kid":"openedx","alg":"RS512","use":"sig"}]}'
            "priv" = '{"kty":"RSA","kid":"openedx","alg":"RS512"}'
        }
    }
}

# ## New-VariantConfigObject
# Builds the complete production configuration hashtable for LMS or Studio CMS.
function New-VariantConfigObject {
    param(
        [string]$Variant,
        [string]$InstallDirFwd,
        [string]$SecretKey,
        [string]$ObfKey,
        [string]$PubJwkSet,
        [string]$PrivJwk
    )

    $lmsPort = if ($env:OPENEDX_LMS_PORT) { [int]$env:OPENEDX_LMS_PORT } else { 8000 }
    $cmsPort = if ($env:OPENEDX_CMS_PORT) { [int]$env:OPENEDX_CMS_PORT } else { 8001 }
    $mysqlPort = if ($env:MYSQL_PORT) { [int]$env:MYSQL_PORT } else { 3306 }
    $mongoPort = if ($env:MONGODB_PORT) { [int]$env:MONGODB_PORT } else { 27017 }
    $redisPort = if ($env:REDIS_PORT) { [int]$env:REDIS_PORT } else { 6379 }
    $meiliPort = if ($env:MEILISEARCH_PORT) { [int]$env:MEILISEARCH_PORT } else { 7700 }
    $lmsHost = if ($env:LMS_HOST) { $env:LMS_HOST } else { "localhost:$lmsPort" }
    $cmsHost = if ($env:CMS_HOST) { $env:CMS_HOST } else { "localhost:$cmsPort" }
    $siteName = if ($Variant -eq "cms") { $cmsHost } else { $lmsHost }
    $dataDirFwd = if ($env:OPENEDX_DATA_DIR) { $env:OPENEDX_DATA_DIR.Replace('\', '/') } else { "$InstallDirFwd/data" }
    $logDirFwd = if ($env:OPENEDX_LOG_DIR) { $env:OPENEDX_LOG_DIR.Replace('\', '/') } else { "$InstallDirFwd/logs" }
    $makoDir = if ($Variant -eq "cms") { "$dataDirFwd/mako_cms" } else { "$dataDirFwd/mako_lms" }
    $sessionCookie = if ($Variant -eq "cms") { "studio_sessionid" } else { "sessionid" }

    $mysqlCfg = @{
        "ENGINE"          = "django.db.backends.mysql"
        "HOST"            = "127.0.0.1"
        "PORT"            = $mysqlPort
        "NAME"            = "openedx"
        "USER"            = "openedx"
        "PASSWORD"        = ""
        "ATOMIC_REQUESTS" = $true
        "CONN_MAX_AGE"    = 60
        "OPTIONS"         = @{
            "charset"      = "utf8mb4"
            "init_command" = "SET sql_mode='STRICT_TRANS_TABLES'"
        }
    }

    $mongoCfg = @{
        "host"       = "127.0.0.1"
        "port"       = $mongoPort
        "db"         = "openedx"
        "collection" = "modulestore"
    }

    return @{
        "PLATFORM_NAME"                     = "Open edX"
        "STUDIO_NAME"                       = "Open edX Studio"
        "STUDIO_SHORT_NAME"                 = "Studio"
        "SITE_NAME"                         = $siteName
        "LMS_BASE"                          = $lmsHost
        "LMS_ROOT_URL"                      = "http://localhost:$lmsPort"
        "LMS_INTERNAL_ROOT_URL"             = "http://localhost:$lmsPort"
        "CMS_BASE"                          = $cmsHost
        "CMS_ROOT_URL"                      = "http://localhost:$cmsPort"
        "BOOK_URL"                          = ""
        "HTTPS"                             = "off"
        "ENABLE_HTTPS"                      = $false
        "SESSION_COOKIE_NAME"               = $sessionCookie
        "SESSION_COOKIE_SECURE"             = $false
        "CSRF_COOKIE_SECURE"                = $false
        "DCS_SESSION_COOKIE_SAMESITE"       = "Lax"
        "ALLOWED_HOSTS"                     = @("localhost", "127.0.0.1", "*")
        "LOGIN_REDIRECT_WHITELIST"          = @("localhost:$lmsPort", "localhost:$cmsPort", "127.0.0.1:$lmsPort", "127.0.0.1:$cmsPort")
        "CORS_ORIGIN_ALLOW_ALL"             = $true
        "CORS_ALLOW_INSECURE"               = $true
        "CORS_ALLOW_CREDENTIALS"            = $true
        "ENABLE_CORS_HEADERS"               = $true
        "ENABLE_CROSS_DOMAIN_CSRF_COOKIE"   = $true
        "CROSS_DOMAIN_CSRF_COOKIE_NAME"     = "prod-edx-csrftoken"
        "CROSS_DOMAIN_CSRF_COOKIE_DOMAIN"   = "localhost"
        "FRONTEND_LOGIN_URL"                = "http://localhost:$lmsPort/authn/login"
        "FRONTEND_REGISTER_URL"             = "http://localhost:$lmsPort/authn/register"
        "ENABLE_MFE_CONFIG_API"             = $true
        "ENABLE_AUTHN_MICROFRONTEND"        = $true
        "AUTHN_MICROFRONTEND_URL"           = "http://localhost:$lmsPort/authn"
        "LEARNER_HOME_MICROFRONTEND_URL"    = "http://localhost:$lmsPort/learner-dashboard"
        "LEARNING_MICROFRONTEND_URL"        = "http://localhost:$lmsPort/learning"
        "COURSE_AUTHORING_MICROFRONTEND_URL"= "http://localhost:$cmsPort/authoring"
        "ACCOUNT_MICROFRONTEND_URL"         = "http://localhost:$lmsPort/account"
        "PROFILE_MICROFRONTEND_URL"         = "http://localhost:$lmsPort/profile"
        "MFE_CONFIG"                        = @{
            "SITE_NAME"                      = "Open edX"
            "BASE_URL"                       = "http://localhost:$lmsPort"
            "LMS_BASE_URL"                   = "http://localhost:$lmsPort"
            "STUDIO_BASE_URL"                = "http://localhost:$cmsPort"
            "LOGIN_URL"                      = "http://localhost:$lmsPort/authn/login"
            "LOGOUT_URL"                     = "http://localhost:$lmsPort/logout"
            "MARKETING_SITE_BASE_URL"        = "http://localhost:$lmsPort"
            "LEARNING_BASE_URL"              = "http://localhost:$lmsPort/learning"
            "REFRESH_ACCESS_TOKEN_ENDPOINT"  = "http://localhost:$lmsPort/login_refresh"
            "ACCESS_TOKEN_COOKIE_NAME"       = "edx-jwt-cookie-header-payload"
            "USER_INFO_COOKIE_NAME"          = "edx-user-info"
            "CSRF_TOKEN_API_PATH"            = "/csrf/api/v1/token"
            "LANGUAGE_PREFERENCE_COOKIE_NAME"= "openedx-language-preference"
            "LOGO_URL"                       = "http://localhost:$lmsPort/static/images/logo.png"
            "LOGO_WHITE_URL"                 = "http://localhost:$lmsPort/static/images/logo.png"
            "LOGO_TRADEMARK_URL"             = "http://localhost:$lmsPort/static/images/logo.png"
            "FAVICON_URL"                    = "http://localhost:$lmsPort/static/images/favicon.ico"
            "ENABLE_NEW_USER_EXPERIENCE"     = $false
        }
        "SECRET_KEY"                        = $SecretKey
        "PROCTORING_USER_OBFUSCATION_KEY"   = $ObfKey
        "DATA_DIR"                          = $dataDirFwd
        "LOG_DIR"                           = $logDirFwd
        "LOGGING_ENV"                       = "sandbox"
        "LOCAL_LOGLEVEL"                    = "INFO"
        "SYSLOG_SERVER"                     = ""
        "MAKO_MODULE_DIR"                   = $makoDir
        "MEDIA_ROOT"                        = "$InstallDirFwd/media"
        "MEDIA_URL"                         = "/media/"
        "STATIC_ROOT_BASE"                  = "$InstallDirFwd/staticfiles"
        "STATIC_URL_BASE"                   = "/static/"
        "DEFAULT_TEMPLATE_ENGINE"           = @{
            "NAME"     = "mako"
            "BACKEND"  = "common.djangoapps.edxmako.MakoBackend"
            "APP_DIRS" = $true
            "OPTIONS"  = @{
                "context_processors" = @(
                    "django.template.context_processors.request",
                    "django.template.context_processors.static",
                    "django.contrib.messages.context_processors.messages",
                    "django.template.context_processors.i18n",
                    "django.contrib.auth.context_processors.auth",
                    "django.template.context_processors.csrf",
                    "help_tokens.context_processor",
                    "openedx.core.djangoapps.site_configuration.context_processors.configuration_context"
                )
                "debug" = $false
            }
        }
        "ENABLE_COMPREHENSIVE_THEMING"      = $true
        "COMPREHENSIVE_THEME_DIRS"          = @("$InstallDirFwd/codebase/themes")
        "GITHUB_REPO_ROOT"                  = $dataDirFwd
        "GIT_REPO_DIR"                      = "$InstallDirFwd/course_repos"
        "GIT_REPO_EXPORT_DIR"               = "$InstallDirFwd/export_course_repos"
        "DJFS"                              = @{
            "type"           = "osfs"
            "directory_root" = "$dataDirFwd/django-pyfs/static/django-pyfs"
            "url_root"       = "/static/django-pyfs"
        }
        "GRADES_DOWNLOAD"                   = @{
            "STORAGE_TYPE" = "localfs"
            "BUCKET"       = "edx-grades"
            "ROOT_PATH"    = "$dataDirFwd/grades"
        }
        "FINANCIAL_REPORTS"                 = @{
            "STORAGE_TYPE" = "localfs"
            "BUCKET"       = "edx-financial-reports"
            "ROOT_PATH"    = "$dataDirFwd/financial-reports"
        }
        "STORAGES"                          = @{
            "default"     = @{ "BACKEND" = "django.core.files.storage.FileSystemStorage" }
            "staticfiles" = @{ "BACKEND" = "openedx.core.storage.ProductionStorage" }
        }
        "OPENEDX_LEARNING"                  = @{
            "MEDIA" = @{
                "BACKEND" = "django.core.files.storage.FileSystemStorage"
                "OPTIONS" = @{ "location" = "$InstallDirFwd/media-private" }
            }
        }
        "ORA2_FILE_PREFIX"                  = "openassessment"
        "PROFILE_IMAGE_BACKEND"             = @{
            "class"   = "openedx.core.storage.OverwriteStorage"
            "options" = @{
                "location" = "$InstallDirFwd/media/profile-images/"
                "base_url" = "/media/profile-images/"
            }
        }
        "VIDEO_IMAGE_SETTINGS"              = @{
            "VIDEO_IMAGE_MAX_BYTES" = 2097152
            "VIDEO_IMAGE_MIN_BYTES" = 2048
            "STORAGE_CLASS"         = "django.core.files.storage.FileSystemStorage"
            "STORAGE_KWARGS"        = @{ "location" = "$InstallDirFwd/media"; "base_url" = "/media/" }
            "DIRECTORY_PREFIX"      = "video-images/"
        }
        "VIDEO_TRANSCRIPTS_SETTINGS"        = @{
            "VIDEO_TRANSCRIPTS_MAX_BYTES" = 3145728
            "STORAGE_CLASS"               = "django.core.files.storage.FileSystemStorage"
            "STORAGE_KWARGS"              = @{ "location" = "$InstallDirFwd/media"; "base_url" = "/media/" }
            "DIRECTORY_PREFIX"            = "video-transcripts/"
        }
        "CODE_JAIL"                         = @{ "limits" = @{ "PROXY" = 0 } }
        "DATABASE_ROUTERS"                  = @()
        "DATABASES"                         = @{
            "default"                = $mysqlCfg
            "student_module_history" = $mysqlCfg
        }
        "DOC_STORE_CONFIG"                  = $mongoCfg
        "CONTENTSTORE"                      = @{
            "ENGINE"           = "xmodule.contentstore.mongo.MongoContentStore"
            "DOC_STORE_CONFIG" = $mongoCfg
        }
        "MODULESTORE"                       = @{
            "default" = @{
                "ENGINE"  = "xmodule.modulestore.mixed.MixedModuleStore"
                "OPTIONS" = @{
                    "mappings" = @{}
                    "stores"   = @(
                        @{
                            "NAME"             = "split"
                            "ENGINE"           = "xmodule.modulestore.split_mongo.split_draft.DraftVersioningModuleStore"
                            "DOC_STORE_CONFIG" = $mongoCfg
                            "OPTIONS"          = @{
                                "default_class"   = "xmodule.hidden_block.HiddenBlock"
                                "fs_root"         = $dataDirFwd
                                "render_template" = "common.djangoapps.edxmako.shortcuts.render_to_string"
                            }
                        },
                        @{
                            "NAME"             = "draft"
                            "ENGINE"           = "xmodule.modulestore.mongo.DraftMongoModuleStore"
                            "DOC_STORE_CONFIG" = $mongoCfg
                            "OPTIONS"          = @{
                                "default_class"   = "xmodule.hidden_block.HiddenBlock"
                                "fs_root"         = $dataDirFwd
                                "render_template" = "common.djangoapps.edxmako.shortcuts.render_to_string"
                            }
                        }
                    )
                }
            }
        }
        "CACHES"                            = @{
            "default"                    = @{ "BACKEND" = "django_redis.cache.RedisCache"; "KEY_PREFIX" = "default"; "LOCATION" = "redis://@127.0.0.1:$redisPort/1" }
            "general"                    = @{ "BACKEND" = "django_redis.cache.RedisCache"; "KEY_PREFIX" = "general"; "LOCATION" = "redis://@127.0.0.1:$redisPort/1" }
            "celery"                     = @{ "BACKEND" = "django_redis.cache.RedisCache"; "KEY_PREFIX" = "celery"; "LOCATION" = "redis://@127.0.0.1:$redisPort/1" }
            "configuration"              = @{ "BACKEND" = "django_redis.cache.RedisCache"; "KEY_PREFIX" = "configuration"; "LOCATION" = "redis://@127.0.0.1:$redisPort/1" }
            "course_structure_cache"     = @{ "BACKEND" = "django_redis.cache.RedisCache"; "KEY_PREFIX" = "course_structure"; "TIMEOUT" = 7200; "LOCATION" = "redis://@127.0.0.1:$redisPort/1" }
            "mongo_metadata_inheritance" = @{ "BACKEND" = "django_redis.cache.RedisCache"; "KEY_PREFIX" = "mongo_metadata_inheritance"; "TIMEOUT" = 300; "LOCATION" = "redis://@127.0.0.1:$redisPort/1" }
            "ora2-storage"               = @{ "BACKEND" = "django_redis.cache.RedisCache"; "KEY_PREFIX" = "ora2-storage"; "LOCATION" = "redis://@127.0.0.1:$redisPort/1" }
        }
        "CELERY_BROKER_TRANSPORT"           = "redis"
        "CELERY_BROKER_HOSTNAME"            = "127.0.0.1:$redisPort"
        "CELERY_BROKER_VHOST"               = "0"
        "CELERY_BROKER_USER"                = ""
        "CELERY_BROKER_PASSWORD"            = ""
        "CELERY_BROKER_USE_SSL"             = $false
        "CELERY_BROKER_URL"                 = "redis://@127.0.0.1:$redisPort/0"
        "EVENT_BUS_REDIS_CONNECTION"        = "redis://@127.0.0.1:$redisPort/0"
        "EVENT_BUS_PRODUCER"                = "edx_event_bus_redis.create_producer"
        "EVENT_BUS_CONSUMER"                = "edx_event_bus_redis.RedisEventConsumer"
        "EVENT_BUS_TOPIC_PREFIX"            = "openedx"
        "MEILISEARCH_ENABLED"               = $false
        "MEILISEARCH_URL"                   = "http://127.0.0.1:$meiliPort"
        "MEILISEARCH_PUBLIC_URL"            = "http://localhost:$meiliPort"
        "MEILISEARCH_INDEX_PREFIX"          = "openedx"
        "MEILISEARCH_API_KEY"               = "openedx_meilisearch_key"
        "EMAIL_BACKEND"                     = "django.core.mail.backends.smtp.EmailBackend"
        "EMAIL_HOST"                        = "127.0.0.1"
        "EMAIL_PORT"                        = 25
        "EMAIL_HOST_USER"                   = ""
        "EMAIL_HOST_PASSWORD"               = ""
        "EMAIL_USE_TLS"                     = $false
        "EMAIL_USE_SSL"                     = $false
        "DEFAULT_FROM_EMAIL"                = "no-reply@localhost"
        "CONTACT_EMAIL"                     = "info@localhost"
        "BUGS_EMAIL"                        = "bugs@localhost"
        "TECH_SUPPORT_EMAIL"                = "technical@localhost"
        "UNIVERSITY_EMAIL"                  = "university@localhost"
        "PRESS_EMAIL"                       = "press@localhost"
        "PAYMENT_SUPPORT_EMAIL"             = "payment@localhost"
        "BULK_EMAIL_DEFAULT_FROM_EMAIL"     = "no-reply@localhost"
        "ACE_CHANNEL_DEFAULT_EMAIL"         = "django_email"
        "ACE_CHANNEL_TRANSACTIONAL_EMAIL"   = "django_email"
        "ACE_ENABLED_CHANNELS"              = @("django_email")
        "OAUTH_OIDC_ISSUER"                 = "http://localhost:$lmsPort/oauth2"
        "SOCIAL_AUTH_EDX_OAUTH2_KEY"        = "cms-sso"
        "SOCIAL_AUTH_EDX_OAUTH2_SECRET"     = "openedx-cms-oauth2-secret-$SecretKey"
        "SOCIAL_AUTH_EDX_OAUTH2_ISSUER"     = "http://localhost:$lmsPort"
        "SOCIAL_AUTH_EDX_OAUTH2_URL_ROOT"   = "http://localhost:$lmsPort"
        "SOCIAL_AUTH_EDX_OAUTH2_PUBLIC_URL_ROOT" = "http://localhost:$lmsPort"
        "BACKEND_SERVICE_EDX_OAUTH2_KEY"    = "backend-service-key"
        "BACKEND_SERVICE_EDX_OAUTH2_SECRET" = "openedx-backend-service-secret-$SecretKey"
        "JWT_AUTH"                          = @{
            "JWT_ISSUER"                     = "http://localhost:$lmsPort/oauth2"
            "JWT_AUDIENCE"                   = "openedx-jwt-audience"
            "JWT_SECRET_KEY"                 = $SecretKey
            "JWT_ALGORITHM"                  = "RS512"
            "JWT_VERIFY_EXPIRATION"          = $true
            "JWT_EXPIRATION_DELTA"           = 3600
            "JWT_ALLOW_REFRESH"              = $true
            "JWT_AUTH_HEADER_PREFIX"         = "JWT"
            "JWT_AUTH_COOKIE"                = "edx-jwt-cookie"
            "JWT_AUTH_COOKIE_HEADER_PAYLOAD" = "edx-jwt-cookie-header-payload"
            "JWT_AUTH_COOKIE_SIGNATURE"      = "edx-jwt-cookie-signature"
            "JWT_AUTH_REFRESH_COOKIE"        = "edx-jwt-refresh-cookie"
            "JWT_ISSUERS"                    = @(
                @{
                    "ISSUER"     = "http://localhost:$lmsPort/oauth2"
                    "AUDIENCE"   = "openedx-jwt-audience"
                    "SECRET_KEY" = $SecretKey
                }
            )
            "JWT_PUBLIC_SIGNING_JWK_SET"     = $PubJwkSet
            "JWT_PRIVATE_SIGNING_JWK"        = $PrivJwk
        }
        "FEATURES"                          = @{
            "ENABLE_CSMH_EXTENDED"               = $false
            "ENABLE_DISCUSSION_SERVICE"          = $false
            "ENABLE_COURSEWARE_SEARCH"           = $false
            "ENABLE_COURSE_DISCOVERY"            = $false
            "ENABLE_DASHBOARD_SEARCH"            = $false
            "ENABLE_COURSEWARE_INDEX"            = $false
            "ENABLE_LIBRARY_INDEX"               = $false
            "ENABLE_COMBINED_LOGIN_REGISTRATION" = $true
            "ENABLE_AUTHN_MICROFRONTEND"         = $true
            "ENABLE_CORS_HEADERS"                = $true
            "ENABLE_CROSS_DOMAIN_CSRF_COOKIE"    = $true
            "ENABLE_PUBLIC_BMI"                  = $true
            "CERTIFICATES_HTML_VIEW"             = $true
            "PREVIEW_LMS_BASE"                   = "localhost:$lmsPort"
            "ALLOW_PUBLIC_ACCOUNT_CREATION"      = $true
        }
    }
}

# ## Do-Generate
# Generates default production configuration files (lms.yml, cms.yml, revisions.yml, Caddyfile, lms.env.json, cms.env.json).
function Do-Generate {
    param([string[]]$ConfFiles)

    $secretKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    $obfKey = "openedx_obf_$secretKey"
    $jwkPair = New-RsaJwkPair

    $cfgDir = Split-Path -Parent $ConfFiles[0]
    if (-not (Test-Path $cfgDir)) {
        New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
    }
    $installDir = Split-Path -Parent $cfgDir
    $installDirFwd = $installDir.Replace('\', '/')

    $revFile = Join-Path $cfgDir "revisions.yml"
    if (-not (Test-Path $revFile)) {
        Set-Content -Path $revFile -Value 'EDX_PLATFORM_REVISION: "windows-native-v1"' -Encoding Ascii
    }

    if (-not (Test-Path $ConfFiles[0])) {
        $lmsDefaults = New-VariantConfigObject -Variant "lms" -InstallDirFwd $installDirFwd -SecretKey $secretKey -ObfKey $obfKey -PubJwkSet $jwkPair.pub -PrivJwk $jwkPair.priv
        Set-Content -Path $ConfFiles[0] -Value (ConvertTo-Json $lmsDefaults -Depth 10) -Encoding Ascii
    }
    if ($ConfFiles.Length -gt 1 -and (-not (Test-Path $ConfFiles[1]))) {
        $cmsDefaults = New-VariantConfigObject -Variant "cms" -InstallDirFwd $installDirFwd -SecretKey $secretKey -ObfKey $obfKey -PubJwkSet $jwkPair.pub -PrivJwk $jwkPair.priv
        Set-Content -Path $ConfFiles[1] -Value (ConvertTo-Json $cmsDefaults -Depth 10) -Encoding Ascii
    }

    if (Test-Path $ConfFiles[0]) { Copy-Item -Path $ConfFiles[0] -Destination (Join-Path $cfgDir "lms.yml") -Force }
    if ($ConfFiles.Length -gt 1 -and (Test-Path $ConfFiles[1])) { Copy-Item -Path $ConfFiles[1] -Destination (Join-Path $cfgDir "cms.yml") -Force }

    $caddyFile = Join-Path $cfgDir "Caddyfile"
    if (-not (Test-Path $caddyFile)) {
        $lmsPort = if ($env:OPENEDX_LMS_PORT) { $env:OPENEDX_LMS_PORT } else { "8000" }
        $cmsPort = if ($env:OPENEDX_CMS_PORT) { $env:OPENEDX_CMS_PORT } else { "8001" }
        $caddyText = @"
{
    admin off
    auto_https off
}

http://localhost:80, http://127.0.0.1:80 {
    request_body {
        max_size 250MB
    }

    handle_path /static/* {
        root * $installDirFwd/staticfiles
        file_server
    }

    handle_path /media/* {
        root * $installDirFwd/media
        file_server
    }

    reverse_proxy 127.0.0.1:$lmsPort {
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Port {server_port}
        header_up Host {host}
    }
}

http://studio.localhost:80, http://localhost:8081 {
    request_body {
        max_size 2048MB
    }

    handle_path /static/* {
        root * $installDirFwd/staticfiles
        file_server
    }

    handle_path /media/* {
        root * $installDirFwd/media
        file_server
    }

    reverse_proxy 127.0.0.1:$cmsPort {
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Port {server_port}
        header_up Host {host}
    }
}
"@
        Set-Content -Path $caddyFile -Value $caddyText -Encoding Ascii
    }

    Write-Host "Configurations generated."
}

# ## Do-Validate
# Validates JSON file syntax.
function Do-Validate {
    param(
        [string]$ConfFile,
        [string]$SchemaFile
    )

    if (-not (Test-Path $ConfFile)) {
        Write-Error "Error: $ConfFile does not exist"
        exit 1
    }

    try {
        $raw = Get-Content -Path $ConfFile -Raw
        $null = ConvertFrom-Json $raw
        Write-Host "Configuration validation PASSED."
    } catch {
        Write-Error "Error: Invalid JSON syntax in $ConfFile"
        exit 1
    }
}

if ([string]::IsNullOrEmpty($Action) -or $Action -in @("help", "--help", "-h")) {
    Show-Help
}

switch ($Action.ToLower()) {
    "get" {
        Do-Get -ConfFile $Arg1 -Key $Arg2
    }
    "set" {
        Do-Set -ConfFiles @($Arg1, $Arg2) -Key $Arg3 -Val $Arg4
    }
    "generate" {
        Do-Generate -ConfFiles @($Arg1, $Arg2)
    }
    "validate" {
        Do-Validate -ConfFile $Arg1 -SchemaFile $Arg2
    }
    Default {
        Write-Error "Error: Unknown action $Action"
        exit 1
    }
}
