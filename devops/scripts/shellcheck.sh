#!/bin/bash

set -e


function run_native_or_in_docker () {
    EXCLUDE_RULES="SC1090,SC1091,SC2001,SC2064,SC2181,SC1117"
    if [ "$(command -v shellcheck)" ]; then
        shellcheck -x --exclude="$EXCLUDE_RULES" "$1"
    else
        docker run --rm -v "$(pwd):/sd" -w /sd \
            -t koalaman/shellcheck:v0.4.7 \
            -x --exclude=$EXCLUDE_RULES "$1"
    fi
}
export -f run_native_or_in_docker

# Omitting:
# - the `.git/` directory since its hooks won't pass # validation, and
#   we don't maintain those scripts.
# - the `.venv/` dir because we don't control files in there.
# - ossec packages because there are a LOT of violations, and we have
#   a separate issue dedicated to cleaning those up.
# - Python, JavaScript, YAML, HTML, SASS, PNG files because they're not shell scripts.
# - Cache directories of mypy, SASS, or Tox.
# - test results
find "." \
     \( \
        -path '*.html' \
        -o -path '*.js' \
        -o -path '*.mo' \
        -o -path '*.png' \
        -o -path '*.po' \
        -o -path '*.py' \
        -o -path '*.sass' \
        -o -path '*.yml' \
        -o -path '*/.mypy_cache/*' \
        -o -path '*/.sass-cache/*' \
        -o -path '*/.tox/*' \
        -o -path '*/.venv' \
        -o -path './.git' \
        -o -path './build/*' \
        -o -path './install_files/ossec-agent' \
        -o -path './install_files/ossec-server' \
        -o -path './securedrop/static/*' \
        -o -path './test-results/*' \
     \) -prune \
     -o -type f \
     -exec file --mime {} + \
    | awk '$2 ~ /x-shellscript/ { print $1 }' \
    | sed 's/://' \
    | xargs -I {} -n1 bash -c 'run_native_or_in_docker "{}"' _
