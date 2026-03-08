#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

else
  this_file="${0}"
fi
set -eu +f

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${this_file}" )")" && pwd)}"
export LIBSCRIPT_ROOT_DIR

LIBSCRIPT_DOCS_DIR="${LIBSCRIPT_DOCS_DIR:-./docs/latest}"
export LIBSCRIPT_DOCS_DIR

LIBSCRIPT_ASSETS_DIR="${LIBSCRIPT_ASSETS_DIR:-${LIBSCRIPT_DOCS_DIR}}"
export LIBSCRIPT_ASSETS_DIR

if [ -z "${HTML_ROOT+x}" ]; then
   HTML_ROOT="${LIBSCRIPT_ROOT_DIR}"'/docs_web_template'
   export HTML_ROOT
fi

export GIT_REPO="${GIT_REPO:-https://github.com/SamuelMarks/libscript}"

ENVSUBST_PATH="$(which awk cat env printenv sort grep | sort -u | xargs dirname | tr '\n' ':')"
export ENVSUBST_PATH

export SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/find_replace.sh'
. "${SCRIPT_NAME}"

[ -d "${LIBSCRIPT_DOCS_DIR}" ] || mkdir -p "${LIBSCRIPT_DOCS_DIR}"
urls_js='['
urls=''
export LIBSCRIPT_DOCS_PREFIX="${LIBSCRIPT_DOCS_PREFIX:-}"
find_res="$(mktemp)"
trap 'rm -f -- "${find_res}"' EXIT HUP INT QUIT TERM
find "${LIBSCRIPT_ROOT_DIR}" -type f -name '*.md' ! -path '*/node_modules/*' > "${find_res}"
while IFS= read -r f; do
  out="${LIBSCRIPT_DOCS_DIR}${f#"${LIBSCRIPT_ROOT_DIR}"}"
  parent="$(dirname -- "${out}")"

  slashes=0
  tmp="${out}"

  while [ -n "${tmp}" ]; do
    rest="${tmp#?}"
    ch="${tmp%"$rest"}"
    tmp="${rest}"
    if [ "${ch}" = '/' ]; then
      # shellcheck disable=SC2003
      slashes=$(expr "${slashes}" + 1)
    fi
  done
  case "${out}" in
    './'*)
      if [ "${slashes}" -gt 1 ] ; then
        [ -d "${parent}" ] || mkdir -p -- "${parent}"
      fi
      ;;
    *'/'*)
      [ -d "${parent}" ] || mkdir -p -- "${parent}"
      ;;
  esac

  html="${out%%.md}"'.html'

  cp -- "${HTML_ROOT}"'/top.html' "${html}"
  iconv -t utf-8 -- "${f}" | sed 's/.md)/.html)/g' | pandoc -f markdown -t html5 | iconv -f utf-8 >> "${html}"
  rm -f "${html%.html}"'.schema.json' "${html}"'.usage'
  previous_wd="$(pwd)"
  new_wd="${f%/*}"
  cd -- "${new_wd}"
  set +f
  for json_schema in *'.schema.json'; do
    if [ -f "${json_schema}" ]; then
      case "${json_schema##*/}" in
        'installer.schema.json'|'*'*) ;;
        *)
          cd -- "${previous_wd}"
          PORT_PATH="${new_wd##*/libscript}"
          # shellcheck disable=SC1003
          env -i PATH="${ENVSUBST_PATH}" \
                 PORT_PATH="${PORT_PATH}" \
                 PORT_PATH_WIN="$(printf '%s' "${PORT_PATH}" | tr '/' '\\')" \
                 "${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/envsubst_safe_exec.sh' < "${HTML_ROOT}"'/usage.html' >> "${html}"'.usage'
          # shellcheck disable=SC2016
          printf '${USAGE}' >> "${html}"
#           wetzel -k '**MUST**' -- "${new_wd}"'/'"${json_schema}" | iconv -t utf-8  | pandoc -f markdown -t html5 | sed 's/<table>/<table class="tui-table hovered-purple striped-purple">/g' | iconv -f utf-8 >> "${html}"
          jq -c . "${new_wd}"'/'"${json_schema}" >> "${html%.html}"'.schema.json'
          cd -- "${new_wd}"
          ;;
      esac
      # npm install -g wetzel
    fi
  done
  set -f
  cd -- "${previous_wd}"
  cat -- "${HTML_ROOT}"'/bottom.html' >> "${html}"
  if [ -n "${LIBSCRIPT_DOCS_PREFIX}" ]; then
    h="${html#.}"
    urls_js="${urls_js}"'"'"${h#"${LIBSCRIPT_DOCS_PREFIX}"}"'",'
    urls="${urls}"' '"${html#"${LIBSCRIPT_DOCS_PREFIX}"}"
  else
    urls_js="${urls_js}"'"'"${html#.}"'",'
    urls="${urls}"' '"${html}"
  fi
done < "${find_res}"
urls_js="${urls_js%,}"']'
#printf '%s\n' "${urls_js}"

to_html_tree() {
  # Read input from argument or stdin
  if [ "$#" -gt 0 ] && [ -n "$1" ]; then
    input_json="$1"
  else
    # If no arguments, read from stdin
    if [ -t 0 ]; then
      >&2 printf 'No input provided.\n'
      exit 2
    else
      input_json="$(cat)"
    fi
  fi

  # Check if jq is installed
  if ! command -v jq >/dev/null 2>&1; then
    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/utilities/jq/setup.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/utilities/jq/setup.sh"
    fi
  fi
  if ! command -v jq >/dev/null 2>&1; then
    >&2 printf 'Error: jq is required but not installed.\n'
    exit 1
  fi

  # Parse JSON to get the paths
  paths=$(printf '%s' "${input_json}" | jq -r '.[]')

  # Generate subpaths with levels
  (
    # Include the root directory
    printf '/	1\n'

    # Process each path
    printf '%s\n' "${paths}" | while IFS= read -r path; do
      printf '%s\n' "${path}" | awk -F'/' -- '{
        n = split($0, arr, "/")
        subpath = ""
        for (i = 2; i <= n; i++) {
          subpath = subpath "/" arr[i]
          level = i
          printf "%s\t%d\n", subpath, level
        }
      }'
    done
  ) | sort -u > subpaths.txt

  # Process subpaths to generate the nested HTML lists
  awk -F'\t' -- '
  BEGIN {
    prev_level = 0
    indent = ""
  }

  {
    path = $1
    level = $2

    # Close tags if moving up
    while (prev_level > level) {
      print indent "  </li>"
      indent = substr(indent, 1, length(indent) - 2)
      print indent "</ul>"
      prev_level--
    }

    # If same level, close previous <li>
    if (prev_level == level && prev_level != 0) {
      print indent "  </li>"
    }

    # Open new levels
    if (prev_level < level) {
      for (i = prev_level; i < level; i++) {
        print indent "<ul>"
        indent = indent "  "
        prev_level++
      }
    }

    # Print current item
    print indent "<li>" path
  }

  END {
    # Close any remaining open tags
    while (prev_level > 0) {
      print indent "  </li>"
      indent = substr(indent, 1, length(indent) - 2)
      print indent "</ul>"
      prev_level--
    }
  }
  ' subpaths.txt

  # Clean up temporary file
  rm -f subpaths.txt
}

#to_html_tree "${urls}"
#to_html_tree "${urls_js}"
#exit 5
for url in ${urls}; do
  title="${url##*/}"
  p="${url%/*}"
  p="${p##*/}"
  if [ "${title}" = 'README.html' ]; then
    title="${p}"
  else
    title="${p}"'/'"${title}"
  fi
  if [ -n "${LIBSCRIPT_DOCS_PREFIX}" ]; then
    url="${LIBSCRIPT_DOCS_PREFIX}"'/'"${url}"
  fi
  USAGE=''
  SCHEMA=''
  previous_wd="$(pwd)"
  cd -- "${url%/*}"
  set +f
  for f in *'.usage'; do
    case "${f}" in
      '*'*) ;;
      *)
        usage_="$(cat -- "${f}"; printf 'a')"
        usage_="${usage_%a}"
        USAGE="${USAGE}${usage_}"

        for schema in *'.schema.json'; do
          case "${schema}" in
            '*'*) ;;
            *)
              schema_="$(cat -- "${schema}"; printf 'a')"
              schema_="${schema_%a}"
              SCHEMA="${SCHEMA}${schema_}"
              ;;
          esac
        done
        ;;
    esac
  done
  set -f
  cd -- "${previous_wd}"
  URL_PATHNAME="${url}"
  if [ -n "${LIBSCRIPT_DOCS_PREFIX}" ]; then
    URL_PATHNAME="${URL_PATHNAME#"${LIBSCRIPT_DOCS_PREFIX}"}"
  fi
  URL_PATHNAME="${URL_PATHNAME##/}"

  GIT_HTTP_LINK="${GIT_REPO}""$(printf '%s' "${URL_PATHNAME#.}" | sed 's/docs/blob/; s/latest/master/; s/html/md/')"

  GIT_HTTP_LINK="$(printf '%s' "${GIT_HTTP_LINK}" | sed 's/docs/blob/; s/latest/master/; s/html/md/')"
  env -i PATH="${ENVSUBST_PATH}" \
         url="${url}" \
         TITLE="${title%%.html}" \
         LIBSCRIPT_DOCS_DIR="${LIBSCRIPT_DOCS_DIR#.}" \
         LIBSCRIPT_ASSETS_DIR="${LIBSCRIPT_ASSETS_DIR}" \
         USAGE="${USAGE}" \
         URL_PATHNAME="${URL_PATHNAME}" \
         GIT_HTTP_LINK="${GIT_HTTP_LINK}" \
         "${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/envsubst_safe_exec.sh' < "${url}" > "${url}"'.tmp'

  within_first_header='<a class="right" href="'"${GIT_HTTP_LINK}"'" aria-label="Open on GitHub"><img class="deploy-img" src="/assets/github-badge-small.png" alt="Open on GitHub"/></a>'
  awk -v within_first_header="$within_first_header" '/<\/h1>/ && !done { sub(/<\/h1>/, within_first_header "</h1>"); done=1 } 1' "${url}.tmp" > "${url}.tmp1"

  mv -- "${url}"'.tmp1' "${url}"'.tmp'

  if [ -n "${USAGE}" ]; then
    STATIC_FORM_HTML="$(printf '%s' "${SCHEMA}" | jq -r '
      if type == "object" and has("properties") then
        .properties | to_entries |
        (map(.key | length) | max) as $max_len |
        .[] |
        ($max_len - (.key | length) + 20) as $dots_len |
        (.key | tostring | sub("^\\["; "") | sub("\\]$"; "")) as $clean_key |
        ($clean_key + ("." * $dots_len) + ": ") as $label_text |
        "<div class=\"flex\">\n  <label for=\"\($clean_key)\" class=\"flex-item\" id=\"label-\($clean_key)\" style=\"white-space: pre;\">\( $label_text )</label>\n  <input class=\"tui-input flex-item\" name=\"\($clean_key)\" id=\"\($clean_key)\" placeholder=\"\(.value.description // "" | gsub("\""; "&quot;"))\" type=\"\(if ($clean_key | test("SECRET|PASSWORD")) then "password" else "text" end)\" />\n</div>"
      else
        empty
      end
    ')"

    # shellcheck disable=SC2016
    after_first_header=$(printf '
<div class="tui-window" style="width: 100%%">
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

<div class="tui-window" style="width: 100%%">
  <form id="twoClickForm" action="" method="get">
    <fieldset class="tui-fieldset">
      <legend class="center">2-click deploy</legend>
      <div class="flex">
        <label for="cname" class="flex-item" style="white-space: pre;">CNAME.........................: </label><input class="tui-input flex-item" name="cname" id="cname" placeholder="Domain name" />
      </div>
      <div class="flex">
        <label for="log_server" class="flex-item" style="white-space: pre;">Metrics/logs (server).........: </label><input class="tui-input flex-item" name="log_server" id="log_server" placeholder="If == ↑domain then deploy"/>
      </div>
      <div class="flex">
        <label for="backup_url" class="flex-item" style="white-space: pre;">Backup (object storage).......: </label><input class="tui-input flex-item" name="backup_url" id="backup_url" placeholder="Object storage—e.g., s3—URL"/>
      </div>

      <div class="flex-col">
'"${STATIC_FORM_HTML}"'
      </div>

      <div class="flex">
        <button class="tui-button" id="submit" type="submit">Set vars</button>
      </div>

      <ul class="flex-ul-prefer-hor">
        <li><button type="submit" id="azure_button" formaction="https://azure/" formenctype="text/plain" onclick=twoClickDeploy(this)><img class="deploy-img" src="https://aka.ms/deploytoazurebutton" alt="Deploy to Azure"/></button></li>
        <li><button type="submit" id="digitalocean_button" formaction="https://digitalocean/" formenctype="text/plain" onclick=twoClickDeploy(this)><img class="deploy-img" src="https://www.deploytodo.com/do-btn-blue.svg" alt="Deploy to Digital Ocean"/></button></li>
        <li><button type="submit" id="aws_button" formaction="https://amazonaws/" formenctype="text/plain" onclick=twoClickDeploy(this)><img class="deploy-img" src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" alt="Deploy to AWS"></button></li>
      </ul>
    </fieldset>
  </form>
</div>')
    after_first_header="$after_first_header" awk '
      /<\/h1>/ && !done {
        split($0, a, "</h1>");
        print a[1] "</h1>\n" ENVIRON["after_first_header"] a[2];
        done=1;
        next;
      }
      1
    ' "${url}.tmp" > "${url}.tmp1" 
    mv -- "${url}.tmp1" "${url}.tmp"
  fi

  if [ "$(crc32 "${url}")" = "$(crc32 "${url}"'.tmp')" ]; then
    rm -- "${url}"'.tmp'
  else
    mv -- "${url}"'.tmp' "${url}"
  fi
done

# Could be fancier with a crc32 here also
[ -d "${LIBSCRIPT_ASSETS_DIR}" ] || mkdir -p -- "${LIBSCRIPT_ASSETS_DIR}"
if [ ! "${HTML_ROOT}"'/assets' = "${LIBSCRIPT_ASSETS_DIR}" ]; then
  rsync -a -- "${HTML_ROOT}"'/assets/' "${LIBSCRIPT_ASSETS_DIR}"
fi
if [ -d "${LIBSCRIPT_ROOT_DIR}"'/node_modules/tuicss' ]; then
  rsync -a -- "${LIBSCRIPT_ROOT_DIR}"'/node_modules/tuicss/dist/' "${LIBSCRIPT_ASSETS_DIR}"
fi
env -i PATH="${ENVSUBST_PATH}" \
       URLS="${urls_js}" \
       "${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/envsubst_safe_exec.sh' < "${HTML_ROOT}"'/assets/first_scripts.js' > "${LIBSCRIPT_ASSETS_DIR}"'/first_scripts.js'
[ -d "${LIBSCRIPT_ROOT_DIR}"'/assets/' ] || mkdir -- "${LIBSCRIPT_ROOT_DIR}"'/assets/'

set +f
LIBSCRIPT_ASSETS_DIR=$(CDPATH='' cd -P -- "${LIBSCRIPT_ASSETS_DIR}" && pwd -P)
if [ ! "${LIBSCRIPT_ASSETS_DIR}" = "${LIBSCRIPT_ROOT_DIR}"'/assets' ]; then
  cp -- "${LIBSCRIPT_ASSETS_DIR}"/*.css "${LIBSCRIPT_ROOT_DIR}"'/assets/'
  cp -- "${LIBSCRIPT_ASSETS_DIR}"/*.js "${LIBSCRIPT_ROOT_DIR}"'/assets/'
fi
if [ -d "${LIBSCRIPT_ASSETS_DIR}"'/images' ]; then
  rsync -a -- "${LIBSCRIPT_ASSETS_DIR}"'/images' "${LIBSCRIPT_ROOT_DIR}"'/assets/'
fi
if [ -d "${LIBSCRIPT_ROOT_DIR}"'/../verman-tui-www/assets' ]; then
  rsync -a -r -- "${LIBSCRIPT_ROOT_DIR}"'/../verman-tui-www/assets/' "${LIBSCRIPT_ROOT_DIR}"'/assets/'
fi
set -f
