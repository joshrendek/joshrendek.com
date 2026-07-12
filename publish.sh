#!/bin/bash
set -euo pipefail
hugo --logLevel warn
scripts/check-site.sh public
rsync -avz --delete --exclude=docs public/ www-data@static-sites:html/
