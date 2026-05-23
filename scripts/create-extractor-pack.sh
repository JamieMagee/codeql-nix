#!/usr/bin/env bash
# Assembles ./extractor-pack/ from the release binary + generated dbscheme + tools.
# Adapted from GitHubSecurityLab/codeql-extractor-bicep:scripts/create-extractor-pack.sh
set -eux

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  platform="linux64"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  platform="osx64"
else
  echo "Unsupported OSTYPE: $OSTYPE" >&2
  exit 1
fi

# Locate codeql (used for `codeql query format`). Optional — pack still works without it.
if command -v codeql >/dev/null 2>&1; then
  CODEQL_BINARY="codeql"
elif gh codeql --help >/dev/null 2>&1; then
  CODEQL_BINARY="gh codeql"
else
  CODEQL_BINARY=""
fi

# 1. Build the release binary.
cargo build --release

# 2. Regenerate dbscheme and QL library from the tree-sitter grammar.
mkdir -p ql/lib/codeql/nix/ast/internal/
cargo run --release --bin codeql-extractor-nix -- generate \
  --dbscheme ql/lib/nix.dbscheme \
  --library ql/lib/codeql/nix/ast/internal/TreeSitter.qll

# 3. Format the generated QL library so review diffs stay clean.
if [[ -n "$CODEQL_BINARY" ]]; then
  $CODEQL_BINARY query format -i ql/lib/codeql/nix/ast/internal/TreeSitter.qll
fi

# 4. Ensure a stats file exists. Empty file isn't valid XML; write a stub
#    if the committed one is missing.
if [[ ! -s ql/lib/nix.dbscheme.stats ]]; then
  cat > ql/lib/nix.dbscheme.stats <<'STATS'
<dbstats>
    <typesizes></typesizes>
    <stats></stats>
</dbstats>
STATS
fi

# 5. Assemble the extractor pack.
echo "Creating extractor pack for $platform"
rm -rf extractor-pack
mkdir -p extractor-pack
cp codeql-extractor.yml ql/lib/nix.dbscheme ql/lib/nix.dbscheme.stats extractor-pack/
cp -r tools extractor-pack/
chmod +x extractor-pack/tools/*.sh

# 6. Drop the platform binary.
mkdir -p "extractor-pack/tools/${platform}"
cp "target/release/codeql-extractor-nix" "extractor-pack/tools/${platform}/extractor"

echo "Pack ready at: $(pwd)/extractor-pack"
