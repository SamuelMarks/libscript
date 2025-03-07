#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
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

[ -d "${LIBSCRIPT_DOCS_DIR}" ] || mkdir -p "${LIBSCRIPT_DOCS_DIR}"
#cp 'tuicss.min.css' "${LIBSCRIPT_DOCS_DIR}"'/'
#cp 'tuicss.min.js' "${LIBSCRIPT_DOCS_DIR}"'/'
#cp 'styles.css' "${LIBSCRIPT_DOCS_DIR}"'/'
urls_js='['
urls=''
export LIBSCRIPT_DOCS_PREFIX="${LIBSCRIPT_DOCS_PREFIX:-}"
find_res="$(mktemp)"
find "${LIBSCRIPT_ROOT_DIR}" -type f -name '*.md' > "${find_res}"
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
  previous_wd="$(pwd)"
  new_wd="${f%/*}"
  cd -- "${new_wd}"
  for json_schema in *'.schema.json'; do
    if [ -f "${json_schema}" ]; then
      case "${json_schema##*/}" in
        'installer.schema.json'|'*'*) ;;
        *)
          cd -- "${previous_wd}"
          PORT_PATH="${new_wd##*/libscript}"
          env -i PATH="${ENVSUBST_PATH}" \
                 PORT_PATH="${PORT_PATH}" \
                 PORT_PATH_WIN="$(printf '%s' "${PORT_PATH}" | tr '/' '\\')" \
                 "${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/envsubst_safe_exec.sh' < "${HTML_ROOT}"'/usage.html' >> "${html}"'.usage'
          # shellcheck disable=SC2016
          printf '${USAGE}' >> "${html}"
          wetzel -k '**MUST**' -- "${new_wd}"'/'"${json_schema}" | iconv -t utf-8  | pandoc -f markdown -t html5 | sed 's/<table>/<table class="tui-table hovered-purple striped-purple">/g' | iconv -f utf-8 >> "${html}"
          cd -- "${new_wd}"
          ;;
      esac
      # npm install -g wetzel
    fi
  done
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
rm -- "${find_res}"
urls_js="${urls_js%,}"']'
printf '%s\n' "${urls_js}"

to_html_tree() {

  # Read input from argument or stdin
  if [ "$#" -gt 0 ] && [ -n "$1" ]; then
    input_json="$1"
  else
    # If no arguments, read from stdin
    if [ -t 0 ]; then
      printf 'No input provided.\n' >&2
      exit 2
    else
      input_json="$(cat)"
    fi
  fi

  # Check if jq is installed
  if ! command -v jq >/dev/null 2>&1; then
    printf 'Error: jq is required but not installed.\n' >&2
    exit 1
  fi

  # Parse JSON to get the paths
  paths=$(echo "$input_json" | jq -r '.[]')

  # Generate subpaths with levels
  (
    # Include the root directory
    echo "/	1"

    # Process each path
    echo "$paths" | while IFS= read -r path; do
      echo "$path" | awk -F'/' '{
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
  awk -F'\t' '
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
  previous_wd="$(pwd)"
  cd -- "${url%/*}"
  for f in *'.usage'; do
    case "${f}" in
      '*'*) ;;
      *)
        usage_="$(cat -- "${f}"; printf 'a')"
        usage_="${usage_%a}"
        USAGE="${USAGE}${usage_}"
        ;;
    esac
  done
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

  # shellcheck disable=SC2016
  awk_src='
  {
    if (!found) {
      idx = index($0, search)
      if (idx > 0) {
        # Replace the first occurrence
        before = substr($0, 1, idx - 1)
        after = substr($0, idx + length(search))
        print before replace after
        found = 1
      } else {
        print $0
      }
    } else {
      print $0
    }
  }
  '

  within_first_header='<a class="right" href="'"${GIT_HTTP_LINK}"'" aria-label="Open on GitHub"><img class="deploy-img" src="/assets/github-badge-small.png" alt="Open on GitHub"/></a>'
  awk -v search='</h1>' -v replace="${within_first_header}"'</h1>' "${awk_src}" "${url}"'.tmp' > "${url}"'.tmp1'
  mv -- "${url}"'.tmp1' "${url}"'.tmp'

  if [ -n "${USAGE}" ]; then
    after_first_header='<div class="tui-window" style="width: 100%">'
    after_first_header="${after_first_header}"'<fieldset class="tui-fieldset">'
    after_first_header="${after_first_header}"'<legend class="center">1-click deploy</legend>'
    after_first_header="${after_first_header}"'<ul class="flex-ul-prefer-hor">'
    after_first_header="${after_first_header}"'<li><a onclick="TODO()"><img class="deploy-img" src="https://aka.ms/deploytoazurebutton" alt="Deploy to Azure"/></a></li>'
    after_first_header="${after_first_header}"'<li><a onclick="TODO()"><img class="deploy-img" src="https://www.deploytodo.com/do-btn-blue.svg" alt="Deploy to Digital Ocean"/></a></li>'
    after_first_header="${after_first_header}"'<li><a onclick="TODO()"><img class="deploy-img" src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" alt="Deploy to AWS"></a></li>'
    after_first_header="${after_first_header}"'</ul>'
    after_first_header="${after_first_header}"'</fieldset>'
    after_first_header="${after_first_header}"'</div>'

    after_first_header="${after_first_header}"'<h2 class="line-beside">or</h2>'

    after_first_header="${after_first_header}"'<div class="tui-window" style="width: 100%">'
    after_first_header="${after_first_header}"'<form id="twoClickForm" action="" method="get">'
    after_first_header="${after_first_header}"'<fieldset class="tui-fieldset">'
    after_first_header="${after_first_header}"'<legend class="center">2-click deploy</legend>'
    after_first_header="${after_first_header}"'<div class="flex">'
    after_first_header="${after_first_header}"'<label for="cname" class="flex-item">     CNAME............................: </label><input class="tui-input flex-item" name="cname" id="cname" placeholder="Domain name" /><br>'
    after_first_header="${after_first_header}"'</div>'
    after_first_header="${after_first_header}"'<div class="flex">'
    after_first_header="${after_first_header}"'<label for="log_server" class="flex-item">Metrics/logs (server)............: </label><input class="tui-input flex-item" name="log_server" id="log_server" placeholder="If == ↑domain then deploy"/><br>'
    after_first_header="${after_first_header}"'</div>'
    after_first_header="${after_first_header}"'<div class="flex">'
    after_first_header="${after_first_header}"'<label for="backup_url" class="flex-item">Backup (object storage)..........: </label><input class="tui-input flex-item" name="backup_url" id="backup_url" placeholder="Object storage—e.g., s3—URL"/><br>'
    after_first_header="${after_first_header}"'</div>'
    #after_first_header="${after_first_header}"'<label for="json">Additional vars (JSON format).......:</label>'
    after_first_header="${after_first_header}"'<textarea class="tui-input" style="width: 100%" placeholder="Additional vars (JSON format)" name="json" id="json"></textarea></br>'
    after_first_header="${after_first_header}"'</fieldset>'

    after_first_header="${after_first_header}"'<ul class="flex-ul-prefer-hor">'
    after_first_header="${after_first_header}"'<li><button type="submit" id="azure_button" formaction="https://azure/" formenctype="text/plain" onclick=twoClickDeploy(this)><img class="deploy-img" src="https://aka.ms/deploytoazurebutton" alt="Deploy to Azure"/></button></li>'
    after_first_header="${after_first_header}"'<li><button type="submit" id="digitalocean_button" formaction="https://digitalocean/" formenctype="text/plain" onclick=twoClickDeploy(this)><img class="deploy-img" src="https://www.deploytodo.com/do-btn-blue.svg" alt="Deploy to Digital Ocean"/></button></li>'
    after_first_header="${after_first_header}"'<li><button type="submit" id="aws_button" formaction="https://amazonaws/" formenctype="text/plain" onclick=twoClickDeploy(this)><img class="deploy-img" src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" alt="Deploy to AWS"></button></li>'
    after_first_header="${after_first_header}"'</ul>'
    after_first_header="${after_first_header}"'</form>'
    after_first_header="${after_first_header}"'</div>'
    awk -v search='</h1>' -v replace='</h1>\n'"${after_first_header}" "${awk_src}" "${url}"'.tmp' > "${url}"'.tmp1'
    mv -- "${url}"'.tmp1' "${url}"'.tmp'
  fi

  if [ "$(crc32 "${url}")" = "$(crc32 "${url}"'.tmp')" ]; then
    rm -- "${url}"'.tmp'
  else
    mv -- "${url}"'.tmp' "${url}"
  fi
done

# Could be fancier with a crc32 here also
[ -d "${LIBSCRIPT_ASSETS_DIR}" ] || mkdir -p -- "${LIBSCRIPT_ASSETS_DIR}"
cp -- "${HTML_ROOT}"'/assets/'*'.css' "${LIBSCRIPT_ASSETS_DIR}"
cp -- "${HTML_ROOT}"'/assets/'*'.js' "${LIBSCRIPT_ASSETS_DIR}"
env -i PATH="${ENVSUBST_PATH}" \
       URLS="${urls_js}" \
       "${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/envsubst_safe_exec.sh' < "${HTML_ROOT}"'/assets/first_scripts.js' > "${LIBSCRIPT_ASSETS_DIR}"'/first_scripts.js'

set -f
