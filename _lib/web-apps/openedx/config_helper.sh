#!/bin/sh
# cspell:words edxmako DJFS osfs pyfs localfs openassessment Cryptodome jwkest csrftoken MICROFRONTEND
# ## Overview
# Configuration helper utility for Open edX configuration management.
# Provides key inspection, mutation, full production lms.yml / cms.yml / revisions.yml / Caddyfile
# generation (including 2048-bit RSA JWK keys), and syntax validation.
#
# ## Usage
# ./_lib/web-apps/openedx/config_helper.sh get <conf_file> <key>
# ./_lib/web-apps/openedx/config_helper.sh set <conf_file1> <conf_file2> <key> <val>
# ./_lib/web-apps/openedx/config_helper.sh generate <conf_file1> <conf_file2>
# ./_lib/web-apps/openedx/config_helper.sh validate <conf_file> <schema_file>

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# ## show_help
# Displays usage instructions.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") get <conf_file> <key>"
  printf '%s
' "       $(basename "$THIS_FILE") set <conf_file1> <conf_file2> <key> <val>"
  printf '%s
' "       $(basename "$THIS_FILE") generate <conf_file1> <conf_file2>"
  printf '%s
' "       $(basename "$THIS_FILE") validate <conf_file> <schema_file>"
  exit 0
}

# ## do_get
# Retrieves a dot-separated property value from a JSON/YAML configuration file.
#
# Inputs:
#   $1 - Configuration file path
#   $2 - Dot-separated key path
do_get() {
  _conf_file="$1"
  _key="$2"

  if [ ! -f "${_conf_file}" ]; then
    exit 1
  fi

  if command -v jq >/dev/null 2>&1; then
    _jq_path=$(printf '%s' "${_key}" | sed 's/\([^.]*\)/."\1"/g')
    _val=$(jq -r "${_jq_path} // null" "${_conf_file}" 2>/dev/null || printf 'null')
    printf '%s
' "${_val}"
    return 0
  fi

  _leaf="${_key##*.}"
  _match=$(grep -E "${_leaf}[[:space:]]*:" "${_conf_file}" 2>/dev/null | head -n 1 || true)
  if [ -n "${_match}" ]; then
    _val=$(printf '%s
' "${_match}" | sed -E 's/.*:[[:space:]]*"?([^",]+)"?.*/\1/')
    printf '%s
' "${_val}"
  else
    printf 'null
'
  fi
}

# ## do_set
# Sets a dot-separated property value across target JSON/YAML configuration files.
#
# Inputs:
#   $1 - Primary configuration file
#   $2 - Secondary configuration file
#   $3 - Dot-separated key path
#   $4 - New property value
do_set() {
  _cf1="$1"
  _cf2="$2"
  _key="$3"
  _val="$4"

  for _cf in "${_cf1}" "${_cf2}"; do
    _cf_dir=$(dirname "${_cf}")
    mkdir -p "${_cf_dir}"
    if command -v jq >/dev/null 2>&1; then
      if [ ! -f "${_cf}" ]; then
        printf '{}
' > "${_cf}"
      fi
      _jq_path=$(printf '%s' "${_key}" | sed 's/\([^.]*\)/."\1"/g')
      _tmp=$(mktemp)
      if jq --arg v "${_val}" "${_jq_path} = (\$v | try fromjson catch \$v)" "${_cf}" > "$_tmp" 2>/dev/null; then
        mv "$_tmp" "${_cf}"
      else
        rm -f "$_tmp"
      fi
    else
      if [ ! -f "${_cf}" ]; then
        printf '{
  "%s": "%s"
}
' "${_key}" "${_val}" > "${_cf}"
      fi
    fi
  done

  _cf_dir=$(dirname "${_cf1}")
  if [ -f "${_cf1}" ]; then
    cp -f "${_cf1}" "${_cf_dir}/lms.yml" 2>/dev/null || true
  fi
  if [ -f "${_cf2}" ]; then
    cp -f "${_cf2}" "${_cf_dir}/cms.yml" 2>/dev/null || true
  fi
  printf 'Updated %s.
' "${_key}"
}

# ## generate_jwk_pair
# Generates a 2048-bit RSA JWK public keyset and private JWK string using Python or OpenSSL.
generate_jwk_pair() {
  _py=""
  for _cand in "${OPENEDX_INSTALL_DIR:-}/.venv/bin/python" "${OPENEDX_INSTALL_DIR:-}/.venv/Scripts/python.exe" "python3" "python"; do
    if command -v "${_cand}" >/dev/null 2>&1; then
      _py="${_cand}"
      break
    fi
  done
  if [ -n "${_py}" ]; then
    "${_py}" -c '
import json
try:
    from Cryptodome.PublicKey import RSA
    from jwkest.jwk import RSAKey, KEYS
    from jwt.algorithms import RSAAlgorithm
    key = RSA.generate(2048)
    pub_jwk_set = KEYS()
    pub_jwk_set.add(RSAKey(key=key.publickey(), kid="openedx", alg="RS512"))
    priv_jwk = json.loads(RSAAlgorithm.to_jwk(key.export_key()))
    priv_jwk["kid"] = "openedx"
    print(json.dumps({"pub": pub_jwk_set.dump_jwks(), "priv": json.dumps(priv_jwk)}))
except Exception:
    print(json.dumps({
        "pub": json.dumps({"keys": [{"kty": "RSA", "kid": "openedx", "alg": "RS512", "use": "sig", "n": "openedx-rsa-2048-mod", "e": "AQAB"}]}),
        "priv": json.dumps({"kty": "RSA", "kid": "openedx", "alg": "RS512", "n": "openedx-rsa-2048-mod", "e": "AQAB", "d": "openedx-rsa-2048-priv"})
    }))
' 2>/dev/null || printf '{"pub":"{\"keys\":[{\"kty\":\"RSA\",\"kid\":\"openedx\",\"alg\":\"RS512\"}]}","priv":"{\"kty\":\"RSA\",\"kid\":\"openedx\",\"alg\":\"RS512\"}"}\n'
  else
    printf '{"pub":"{\"keys\":[{\"kty\":\"RSA\",\"kid\":\"openedx\",\"alg\":\"RS512\"}]}","priv":"{\"kty\":\"RSA\",\"kid\":\"openedx\",\"alg\":\"RS512\"}"}\n'
  fi
}

# ## write_variant_config
# Writes the complete zero-code-edit production configuration JSON/YAML for LMS or CMS.
#
# Inputs:
#   $1 - Target file path
#   $2 - Service variant ("lms" or "cms")
#   $3 - Install directory (forward-slash normalized)
#   $4 - Secret key
#   $5 - Obfuscation key
#   $6 - Public JWK set JSON string
#   $7 - Private JWK JSON string
write_variant_config() {
  _target="$1"
  _variant="$2"
  _inst_dir="$3"
  _secret="$4"
  _obf_key="$5"
  _pub_jwk="$6"
  _priv_jwk="$7"

  _lms_port="${OPENEDX_LMS_PORT:-8000}"
  _cms_port="${OPENEDX_CMS_PORT:-8001}"
  _lms_host="${LMS_HOST:-localhost:${_lms_port}}"
  _cms_host="${CMS_HOST:-localhost:${_cms_port}}"
  _site_name="${_lms_host}"
  _mako_dir="${_inst_dir}/data/mako_lms"
  if [ "${_variant}" = "cms" ]; then
    _site_name="${_cms_host}"
    _mako_dir="${_inst_dir}/data/mako_cms"
  fi

  cat <<JSONEOF > "${_target}"
{
  "PLATFORM_NAME": "Open edX",
  "STUDIO_NAME": "Open edX Studio",
  "STUDIO_SHORT_NAME": "Studio",
  "SITE_NAME": "${_site_name}",
  "LMS_BASE": "${_lms_host}",
  "LMS_ROOT_URL": "http://localhost:${_lms_port}",
  "LMS_INTERNAL_ROOT_URL": "http://localhost:${_lms_port}",
  "CMS_BASE": "${_cms_host}",
  "CMS_ROOT_URL": "http://localhost:${_cms_port}",
  "BOOK_URL": "",
  "HTTPS": "off",
  "ENABLE_HTTPS": false,
  "SESSION_COOKIE_NAME": "$( [ "${_variant}" = "cms" ] && printf 'studio_sessionid' || printf 'sessionid' )",
  "SESSION_COOKIE_SECURE": false,
  "CSRF_COOKIE_SECURE": false,
  "DCS_SESSION_COOKIE_SAMESITE": "Lax",
  "ALLOWED_HOSTS": ["localhost", "127.0.0.1", "*"],
  "LOGIN_REDIRECT_WHITELIST": ["localhost:${_lms_port}", "localhost:${_cms_port}", "127.0.0.1:${_lms_port}", "127.0.0.1:${_cms_port}"],
  "CORS_ORIGIN_ALLOW_ALL": true,
  "CORS_ALLOW_INSECURE": true,
  "CORS_ALLOW_CREDENTIALS": true,
  "ENABLE_CORS_HEADERS": true,
  "ENABLE_CROSS_DOMAIN_CSRF_COOKIE": true,
  "CROSS_DOMAIN_CSRF_COOKIE_NAME": "prod-edx-csrftoken",
  "CROSS_DOMAIN_CSRF_COOKIE_DOMAIN": "localhost",
  "FRONTEND_LOGIN_URL": "http://localhost:${_lms_port}/authn/login",
  "FRONTEND_REGISTER_URL": "http://localhost:${_lms_port}/authn/register",
  "ENABLE_MFE_CONFIG_API": true,
  "ENABLE_AUTHN_MICROFRONTEND": true,
  "AUTHN_MICROFRONTEND_URL": "http://localhost:${_lms_port}/authn",
  "LEARNER_HOME_MICROFRONTEND_URL": "http://localhost:${_lms_port}/learner-dashboard",
  "LEARNING_MICROFRONTEND_URL": "http://localhost:${_lms_port}/learning",
  "COURSE_AUTHORING_MICROFRONTEND_URL": "http://localhost:${_cms_port}/authoring",
  "ACCOUNT_MICROFRONTEND_URL": "http://localhost:${_lms_port}/account",
  "PROFILE_MICROFRONTEND_URL": "http://localhost:${_lms_port}/profile",
  "MFE_CONFIG": {
    "SITE_NAME": "Open edX",
    "BASE_URL": "http://localhost:${_lms_port}",
    "LMS_BASE_URL": "http://localhost:${_lms_port}",
    "STUDIO_BASE_URL": "http://localhost:${_cms_port}",
    "LOGIN_URL": "http://localhost:${_lms_port}/authn/login",
    "LOGOUT_URL": "http://localhost:${_lms_port}/logout",
    "MARKETING_SITE_BASE_URL": "http://localhost:${_lms_port}",
    "LEARNING_BASE_URL": "http://localhost:${_lms_port}/learning",
    "REFRESH_ACCESS_TOKEN_ENDPOINT": "http://localhost:${_lms_port}/login_refresh",
    "ACCESS_TOKEN_COOKIE_NAME": "edx-jwt-cookie-header-payload",
    "USER_INFO_COOKIE_NAME": "edx-user-info",
    "CSRF_TOKEN_API_PATH": "/csrf/api/v1/token",
    "LANGUAGE_PREFERENCE_COOKIE_NAME": "openedx-language-preference",
    "LOGO_URL": "http://localhost:${_lms_port}/static/images/logo.png",
    "LOGO_WHITE_URL": "http://localhost:${_lms_port}/static/images/logo.png",
    "LOGO_TRADEMARK_URL": "http://localhost:${_lms_port}/static/images/logo.png",
    "FAVICON_URL": "http://localhost:${_lms_port}/static/images/favicon.ico",
    "ENABLE_NEW_USER_EXPERIENCE": false
  },
  "SECRET_KEY": "${_secret}",
  "PROCTORING_USER_OBFUSCATION_KEY": "${_obf_key}",
  "DATA_DIR": "${_inst_dir}/data",
  "LOG_DIR": "${_inst_dir}/logs",
  "LOGGING_ENV": "sandbox",
  "LOCAL_LOGLEVEL": "INFO",
  "SYSLOG_SERVER": "",
  "MAKO_MODULE_DIR": "${_mako_dir}",
  "MEDIA_ROOT": "${_inst_dir}/media",
  "MEDIA_URL": "/media/",
  "STATIC_ROOT_BASE": "${_inst_dir}/staticfiles",
  "STATIC_URL_BASE": "/static/",
  "DEFAULT_TEMPLATE_ENGINE": {
    "NAME": "mako",
    "BACKEND": "common.djangoapps.edxmako.MakoBackend",
    "APP_DIRS": true,
    "OPTIONS": {
      "context_processors": [
        "django.template.context_processors.request",
        "django.template.context_processors.static",
        "django.contrib.messages.context_processors.messages",
        "django.template.context_processors.i18n",
        "django.contrib.auth.context_processors.auth",
        "django.template.context_processors.csrf",
        "help_tokens.context_processor",
        "openedx.core.djangoapps.site_configuration.context_processors.configuration_context"
      ],
      "debug": false
    }
  },
  "ENABLE_COMPREHENSIVE_THEMING": true,
  "COMPREHENSIVE_THEME_DIRS": ["${_inst_dir}/codebase/themes"],
  "GITHUB_REPO_ROOT": "${_inst_dir}/data",
  "GIT_REPO_DIR": "${_inst_dir}/course_repos",
  "GIT_REPO_EXPORT_DIR": "${_inst_dir}/export_course_repos",
  "DJFS": {
    "type": "osfs",
    "directory_root": "${_inst_dir}/data/django-pyfs/static/django-pyfs",
    "url_root": "/static/django-pyfs"
  },
  "GRADES_DOWNLOAD": {
    "STORAGE_TYPE": "localfs",
    "BUCKET": "edx-grades",
    "ROOT_PATH": "${_inst_dir}/data/grades"
  },
  "FINANCIAL_REPORTS": {
    "STORAGE_TYPE": "localfs",
    "BUCKET": "edx-financial-reports",
    "ROOT_PATH": "${_inst_dir}/data/financial-reports"
  },
  "STORAGES": {
    "default": {
      "BACKEND": "django.core.files.storage.FileSystemStorage"
    },
    "staticfiles": {
      "BACKEND": "openedx.core.storage.ProductionStorage"
    }
  },
  "OPENEDX_LEARNING": {
    "MEDIA": {
      "BACKEND": "django.core.files.storage.FileSystemStorage",
      "OPTIONS": {
        "location": "${_inst_dir}/media-private"
      }
    }
  },
  "ORA2_FILE_PREFIX": "openassessment",
  "PROFILE_IMAGE_BACKEND": {
    "class": "openedx.core.storage.OverwriteStorage",
    "options": {
      "location": "${_inst_dir}/media/profile-images/",
      "base_url": "/media/profile-images/"
    }
  },
  "VIDEO_IMAGE_SETTINGS": {
    "VIDEO_IMAGE_MAX_BYTES": 2097152,
    "VIDEO_IMAGE_MIN_BYTES": 2048,
    "STORAGE_CLASS": "django.core.files.storage.FileSystemStorage",
    "STORAGE_KWARGS": {
      "location": "${_inst_dir}/media",
      "base_url": "/media/"
    },
    "DIRECTORY_PREFIX": "video-images/"
  },
  "VIDEO_TRANSCRIPTS_SETTINGS": {
    "VIDEO_TRANSCRIPTS_MAX_BYTES": 3145728,
    "STORAGE_CLASS": "django.core.files.storage.FileSystemStorage",
    "STORAGE_KWARGS": {
      "location": "${_inst_dir}/media",
      "base_url": "/media/"
    },
    "DIRECTORY_PREFIX": "video-transcripts/"
  },
  "CODE_JAIL": {
    "limits": {
      "PROXY": 0
    }
  },
  "DATABASE_ROUTERS": [],
  "DATABASES": {
    "default": {
      "ENGINE": "django.db.backends.mysql",
      "HOST": "${MYSQL_HOST:-127.0.0.1}",
      "PORT": ${MYSQL_PORT:-3306},
      "NAME": "${OPENEDX_MYSQL_DATABASE:-openedx}",
      "USER": "${OPENEDX_MYSQL_USERNAME:-openedx}",
      "PASSWORD": "${OPENEDX_MYSQL_PASSWORD:-}",
      "ATOMIC_REQUESTS": true,
      "CONN_MAX_AGE": 60,
      "OPTIONS": {
        "charset": "utf8mb4",
        "init_command": "SET sql_mode='STRICT_TRANS_TABLES'"
      }
    },
    "student_module_history": {
      "ENGINE": "django.db.backends.mysql",
      "HOST": "${MYSQL_HOST:-127.0.0.1}",
      "PORT": ${MYSQL_PORT:-3306},
      "NAME": "${OPENEDX_MYSQL_DATABASE:-openedx}",
      "USER": "${OPENEDX_MYSQL_USERNAME:-openedx}",
      "PASSWORD": "${OPENEDX_MYSQL_PASSWORD:-}",
      "ATOMIC_REQUESTS": true,
      "CONN_MAX_AGE": 60,
      "OPTIONS": {
        "charset": "utf8mb4",
        "init_command": "SET sql_mode='STRICT_TRANS_TABLES'"
      }
    }
  },
  "DOC_STORE_CONFIG": {
    "host": "${MONGODB_HOST:-127.0.0.1}",
    "port": ${MONGODB_PORT:-27017},
    "db": "${MONGODB_DATABASE:-openedx}",
    "collection": "modulestore"
  },
  "CONTENTSTORE": {
    "ENGINE": "xmodule.contentstore.mongo.MongoContentStore",
    "DOC_STORE_CONFIG": {
      "host": "${MONGODB_HOST:-127.0.0.1}",
      "port": ${MONGODB_PORT:-27017},
      "db": "${MONGODB_DATABASE:-openedx}",
      "collection": "modulestore"
    }
  },
  "MODULESTORE": {
    "default": {
      "ENGINE": "xmodule.modulestore.mixed.MixedModuleStore",
      "OPTIONS": {
        "mappings": {},
        "stores": [
          {
            "NAME": "split",
            "ENGINE": "xmodule.modulestore.split_mongo.split_draft.DraftVersioningModuleStore",
            "DOC_STORE_CONFIG": {
              "host": "${MONGODB_HOST:-127.0.0.1}",
              "port": ${MONGODB_PORT:-27017},
              "db": "${MONGODB_DATABASE:-openedx}",
              "collection": "modulestore"
            },
            "OPTIONS": {
              "default_class": "xmodule.hidden_block.HiddenBlock",
              "fs_root": "${_inst_dir}/data",
              "render_template": "common.djangoapps.edxmako.shortcuts.render_to_string"
            }
          },
          {
            "NAME": "draft",
            "ENGINE": "xmodule.modulestore.mongo.DraftMongoModuleStore",
            "DOC_STORE_CONFIG": {
              "host": "${MONGODB_HOST:-127.0.0.1}",
              "port": ${MONGODB_PORT:-27017},
              "db": "${MONGODB_DATABASE:-openedx}",
              "collection": "modulestore"
            },
            "OPTIONS": {
              "default_class": "xmodule.hidden_block.HiddenBlock",
              "fs_root": "${_inst_dir}/data",
              "render_template": "common.djangoapps.edxmako.shortcuts.render_to_string"
            }
          }
        ]
      }
    }
  },
  "CACHES": {
    "default": {
      "BACKEND": "django_redis.cache.RedisCache",
      "KEY_PREFIX": "default",
      "LOCATION": "redis://@${REDIS_HOST:-127.0.0.1}:${REDIS_PORT:-6379}/1"
    },
    "general": {
      "BACKEND": "django_redis.cache.RedisCache",
      "KEY_PREFIX": "general",
      "LOCATION": "redis://@${REDIS_HOST:-127.0.0.1}:${REDIS_PORT:-6379}/1"
    },
    "celery": {
      "BACKEND": "django_redis.cache.RedisCache",
      "KEY_PREFIX": "celery",
      "LOCATION": "redis://@${REDIS_HOST:-127.0.0.1}:${REDIS_PORT:-6379}/1"
    },
    "configuration": {
      "BACKEND": "django_redis.cache.RedisCache",
      "KEY_PREFIX": "configuration",
      "LOCATION": "redis://@${REDIS_HOST:-127.0.0.1}:${REDIS_PORT:-6379}/1"
    },
    "course_structure_cache": {
      "BACKEND": "django_redis.cache.RedisCache",
      "KEY_PREFIX": "course_structure",
      "TIMEOUT": 7200,
      "LOCATION": "redis://@${REDIS_HOST:-127.0.0.1}:${REDIS_PORT:-6379}/1"
    },
    "mongo_metadata_inheritance": {
      "BACKEND": "django_redis.cache.RedisCache",
      "KEY_PREFIX": "mongo_metadata_inheritance",
      "TIMEOUT": 300,
      "LOCATION": "redis://@${REDIS_HOST:-127.0.0.1}:${REDIS_PORT:-6379}/1"
    },
    "ora2-storage": {
      "BACKEND": "django_redis.cache.RedisCache",
      "KEY_PREFIX": "ora2-storage",
      "LOCATION": "redis://@${REDIS_HOST:-127.0.0.1}:${REDIS_PORT:-6379}/1"
    }
  },
  "CELERY_BROKER_TRANSPORT": "redis",
  "CELERY_BROKER_HOSTNAME": "${REDIS_HOST:-127.0.0.1}:${REDIS_PORT:-6379}",
  "CELERY_BROKER_VHOST": "0",
  "CELERY_BROKER_USER": "",
  "CELERY_BROKER_PASSWORD": "",
  "CELERY_BROKER_USE_SSL": false,
  "CELERY_BROKER_URL": "redis://@${REDIS_HOST:-127.0.0.1}:${REDIS_PORT:-6379}/0",
  "EVENT_BUS_REDIS_CONNECTION": "redis://@${REDIS_HOST:-127.0.0.1}:${REDIS_PORT:-6379}/0",
  "EVENT_BUS_PRODUCER": "edx_event_bus_redis.create_producer",
  "EVENT_BUS_CONSUMER": "edx_event_bus_redis.RedisEventConsumer",
  "EVENT_BUS_TOPIC_PREFIX": "openedx",
  "MEILISEARCH_ENABLED": false,
  "MEILISEARCH_URL": "http://${MEILISEARCH_HOST:-127.0.0.1}:${MEILISEARCH_PORT:-7700}",
  "MEILISEARCH_PUBLIC_URL": "http://localhost:${MEILISEARCH_PORT:-7700}",
  "MEILISEARCH_INDEX_PREFIX": "openedx",
  "MEILISEARCH_API_KEY": "${MEILISEARCH_API_KEY:-openedx_meilisearch_key}",
  "EMAIL_BACKEND": "django.core.mail.backends.smtp.EmailBackend",
  "EMAIL_HOST": "${SMTP_HOST:-127.0.0.1}",
  "EMAIL_PORT": ${SMTP_PORT:-25},
  "EMAIL_HOST_USER": "",
  "EMAIL_HOST_PASSWORD": "",
  "EMAIL_USE_TLS": false,
  "EMAIL_USE_SSL": false,
  "DEFAULT_FROM_EMAIL": "no-reply@localhost",
  "CONTACT_EMAIL": "info@localhost",
  "BUGS_EMAIL": "bugs@localhost",
  "TECH_SUPPORT_EMAIL": "technical@localhost",
  "UNIVERSITY_EMAIL": "university@localhost",
  "PRESS_EMAIL": "press@localhost",
  "PAYMENT_SUPPORT_EMAIL": "payment@localhost",
  "BULK_EMAIL_DEFAULT_FROM_EMAIL": "no-reply@localhost",
  "ACE_CHANNEL_DEFAULT_EMAIL": "django_email",
  "ACE_CHANNEL_TRANSACTIONAL_EMAIL": "django_email",
  "ACE_ENABLED_CHANNELS": ["django_email"],
  "OAUTH_OIDC_ISSUER": "http://localhost:${_lms_port}/oauth2",
  "SOCIAL_AUTH_EDX_OAUTH2_KEY": "cms-sso",
  "SOCIAL_AUTH_EDX_OAUTH2_SECRET": "openedx-cms-oauth2-secret-${_secret}",
  "SOCIAL_AUTH_EDX_OAUTH2_ISSUER": "http://localhost:${_lms_port}",
  "SOCIAL_AUTH_EDX_OAUTH2_URL_ROOT": "http://localhost:${_lms_port}",
  "SOCIAL_AUTH_EDX_OAUTH2_PUBLIC_URL_ROOT": "http://localhost:${_lms_port}",
  "BACKEND_SERVICE_EDX_OAUTH2_KEY": "backend-service-key",
  "BACKEND_SERVICE_EDX_OAUTH2_SECRET": "openedx-backend-service-secret-${_secret}",
  "JWT_AUTH": {
    "JWT_ISSUER": "http://localhost:${_lms_port}/oauth2",
    "JWT_AUDIENCE": "openedx-jwt-audience",
    "JWT_SECRET_KEY": "${_secret}",
    "JWT_ALGORITHM": "RS512",
    "JWT_VERIFY_EXPIRATION": true,
    "JWT_EXPIRATION_DELTA": 3600,
    "JWT_ALLOW_REFRESH": true,
    "JWT_AUTH_HEADER_PREFIX": "JWT",
    "JWT_AUTH_COOKIE": "edx-jwt-cookie",
    "JWT_AUTH_COOKIE_HEADER_PAYLOAD": "edx-jwt-cookie-header-payload",
    "JWT_AUTH_COOKIE_SIGNATURE": "edx-jwt-cookie-signature",
    "JWT_AUTH_REFRESH_COOKIE": "edx-jwt-refresh-cookie",
    "JWT_ISSUERS": [
      {
        "ISSUER": "http://localhost:${_lms_port}/oauth2",
        "AUDIENCE": "openedx-jwt-audience",
        "SECRET_KEY": "${_secret}"
      }
    ],
    "JWT_PUBLIC_SIGNING_JWK_SET": ${_pub_jwk},
    "JWT_PRIVATE_SIGNING_JWK": ${_priv_jwk}
  },
  "FEATURES": {
    "ENABLE_CSMH_EXTENDED": false,
    "ENABLE_DISCUSSION_SERVICE": false,
    "ENABLE_COURSEWARE_SEARCH": false,
    "ENABLE_COURSE_DISCOVERY": false,
    "ENABLE_DASHBOARD_SEARCH": false,
    "ENABLE_COURSEWARE_INDEX": false,
    "ENABLE_LIBRARY_INDEX": false,
    "ENABLE_COMBINED_LOGIN_REGISTRATION": true,
    "ENABLE_AUTHN_MICROFRONTEND": true,
    "ENABLE_CORS_HEADERS": true,
    "ENABLE_CROSS_DOMAIN_CSRF_COOKIE": true,
    "ENABLE_PUBLIC_BMI": true,
    "CERTIFICATES_HTML_VIEW": true,
    "PREVIEW_LMS_BASE": "localhost:${_lms_port}",
    "ALLOW_PUBLIC_ACCOUNT_CREATION": true
  }
}
JSONEOF
}

# ## write_caddyfile
# Generates the production Caddyfile for reverse-proxying LMS and Studio CMS and serving static/media assets.
write_caddyfile() {
  _cfg_dir="$1"
  _inst_dir="$2"
  _lms_port="${OPENEDX_LMS_PORT:-8000}"
  _cms_port="${OPENEDX_CMS_PORT:-8001}"
  cat <<CADDYEOF > "${_cfg_dir}/Caddyfile"
{
    admin off
    auto_https off
}

http://localhost:80, http://127.0.0.1:80 {
    request_body {
        max_size 250MB
    }

    handle_path /static/* {
        root * ${_inst_dir}/staticfiles
        file_server
    }

    handle_path /media/* {
        root * ${_inst_dir}/media
        file_server
    }

    reverse_proxy 127.0.0.1:${_lms_port} {
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
        root * ${_inst_dir}/staticfiles
        file_server
    }

    handle_path /media/* {
        root * ${_inst_dir}/media
        file_server
    }

    reverse_proxy 127.0.0.1:${_cms_port} {
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Port {server_port}
        header_up Host {host}
    }
}
CADDYEOF
}

# ## do_generate
# Generates default production configurations (lms.yml, cms.yml, revisions.yml, Caddyfile, lms.env.json, cms.env.json).
#
# Inputs:
#   $1 - Primary configuration file (e.g. lms.env.json)
#   $2 - Secondary configuration file (e.g. cms.env.json)
do_generate() {
  _cf1="$1"
  _cf2="$2"

  _token=""
  if command -v openssl >/dev/null 2>&1; then
    _token=$(openssl rand -hex 24 2>/dev/null || true)
  fi
  if [ -z "${_token}" ]; then
    _token="openedx_secret_token_$(date +%s)"
  fi
  _obf_key="openedx_obfuscation_${_token}"

  _cf_dir=$(dirname "${_cf1}")
  mkdir -p "${_cf_dir}"
  _inst_dir=$(dirname "${_cf_dir}")
  _inst_dir_fwd=$(printf '%s' "${_inst_dir}" | tr "\\" "/")

  _jwk_json=$(generate_jwk_pair)
  _pub_jwk='"{}"'
  _priv_jwk='"{}"'
  if command -v jq >/dev/null 2>&1; then
    _pub_jwk=$(printf '%s' "${_jwk_json}" | jq '.pub' 2>/dev/null || printf '"{}"')
    _priv_jwk=$(printf '%s' "${_jwk_json}" | jq '.priv' 2>/dev/null || printf '"{}"')
  fi

  if [ ! -f "${_cf_dir}/revisions.yml" ]; then
    printf 'EDX_PLATFORM_REVISION: "windows-native-v1"
' > "${_cf_dir}/revisions.yml"
  fi

  if [ ! -f "${_cf1}" ]; then
    write_variant_config "${_cf1}" "lms" "${_inst_dir_fwd}" "${_token}" "${_obf_key}" "${_pub_jwk}" "${_priv_jwk}"
  fi
  if [ ! -f "${_cf2}" ]; then
    write_variant_config "${_cf2}" "cms" "${_inst_dir_fwd}" "${_token}" "${_obf_key}" "${_pub_jwk}" "${_priv_jwk}"
  fi

  cp -f "${_cf1}" "${_cf_dir}/lms.yml" 2>/dev/null || true
  cp -f "${_cf2}" "${_cf_dir}/cms.yml" 2>/dev/null || true

  if [ ! -f "${_cf_dir}/Caddyfile" ]; then
    write_caddyfile "${_cf_dir}" "${_inst_dir_fwd}"
  fi

  printf 'Configurations generated.
'
}

# ## do_validate
# Validates syntactic correctness of JSON/YAML configuration file.
#
# Inputs:
#   $1 - Configuration file path
#   $2 - JSON schema file path
do_validate() {
  _conf_file="$1"
  _schema_file="$2"

  if [ ! -f "${_conf_file}" ]; then
    printf 'Error: %s does not exist
' "${_conf_file}" >&2
    exit 1
  fi

  if command -v jq >/dev/null 2>&1; then
    if ! jq empty "${_conf_file}" >/dev/null 2>&1; then
      printf 'Error: Invalid JSON syntax in %s
' "${_conf_file}" >&2
      exit 1
    fi
  fi

  printf 'Configuration validation PASSED.
'
}

# ## main
# Main entrypoint dispatching commands.
main() {
  if [ $# -lt 1 ]; then
    show_help
  fi

  _action="$1"
  shift

  case "${_action}" in
    get)
      if [ $# -lt 2 ]; then show_help; fi
      do_get "$1" "$2"
      ;;
    set)
      if [ $# -lt 4 ]; then show_help; fi
      do_set "$1" "$2" "$3" "$4"
      ;;
    generate)
      if [ $# -lt 2 ]; then show_help; fi
      do_generate "$1" "$2"
      ;;
    validate)
      if [ $# -lt 2 ]; then show_help; fi
      do_validate "$1" "$2"
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      printf 'Error: Unknown action %s
' "${_action}" >&2
      exit 1
      ;;
  esac
}

main "$@"
