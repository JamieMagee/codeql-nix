#!/bin/sh
set -eu

exec "${CODEQL_DIST}/codeql" database index-files \
    --include-extension=.nix \
    --size-limit=5m \
    --language=nix \
    --working-dir=. \
    "$CODEQL_EXTRACTOR_NIX_WIP_DATABASE"
