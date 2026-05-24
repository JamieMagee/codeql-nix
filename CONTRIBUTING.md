# Contributing to codeql-nix

Thanks for your interest. This project is in an early MVP phase
([roadmap](./README.md#whats-planned)) — bug reports, query proposals,
and small documentation fixes are especially welcome.

## Development environment

Requires Nix with flakes enabled. Everything else (Rust toolchain,
CodeQL CLI 2.25+, tree-sitter, `just`, `jq`) is provided by the dev shell:

```bash
nix develop
```

## Building the extractor

```bash
cargo build --release                  # ./target/release/codeql-extractor-nix
./scripts/create-extractor-pack.sh     # assembles ./extractor-pack/
codeql resolve extractor \
    --language=nix \
    --search-path=./extractor-pack     # smoke check
```

## Running the test suite

```bash
# Rust unit tests (none today, but plumbing is in place)
cargo test --release

# QL query tests
codeql test run \
    --search-path=./extractor-pack \
    --additional-packs=ql \
    ql/test
```

## Adding a new query

1. Drop a new `.ql` file under `ql/src/Security/CWE-<NNN>/<QueryName>.ql`
   following the metadata conventions documented in `FetchWithoutIntegrity.ql`
   (`@kind problem` + `@id nix/<kebab-case>` + `@security-severity` + `@tags`).
2. Ship the corresponding `.qhelp`.
3. Add a fixture directory at
   `ql/test/queries/Security/CWE-<NNN>/<QueryName>/`:
   - `<QueryName>.qlref` pointing at the query.
   - `fixture.nix` containing both BAD (must-flag) and GOOD (must-not-flag)
     cases. NEUTRAL examples that exercise an adjacent AST shape are also
     welcome.
4. Generate the `.expected` snapshot:
   ```bash
   codeql test run \
       --search-path=./extractor-pack \
       --additional-packs=ql \
       --learn ql/test
   ```
5. Update `CHANGELOG.md` under `## [Unreleased]` / `### Added`.

## Querying nixpkgs locally

The repository assumes a checkout at `~/src/code/nixpkgs`. Symlinks
into the working tree don't work because CodeQL's file scanner doesn't
follow them, so copy or hardlink the source into a scratch directory
before running `codeql database create`.

```bash
mkdir -p /tmp/nixpkgs-scratch/pkgs
cp -r ~/src/code/nixpkgs/pkgs/by-name /tmp/nixpkgs-scratch/pkgs/by-name

codeql database create /tmp/nixpkgs-db \
    --language=nix \
    --source-root=/tmp/nixpkgs-scratch \
    --search-path=./extractor-pack \
    --overwrite

codeql database analyze /tmp/nixpkgs-db \
    --search-path=./extractor-pack \
    --additional-packs=ql \
    ql/src/codeql-suites/nix-code-scanning.qls \
    --format=sarif-latest \
    --output=results.sarif
```

## Cutting a release (maintainers only)

1. Update `CHANGELOG.md` — promote the `Unreleased` section to a new
   versioned heading.
2. Bump the `version =` lines in `extractor/Cargo.toml` and
   `codeql-extractor.yml`.
3. Commit on `main`.
4. `git tag -a vX.Y.Z -m "Release vX.Y.Z" && git push --tags`.
5. The `release.yml` workflow builds the extractor-pack tarball,
   attaches it to a draft GitHub Release, and includes the CHANGELOG
   excerpt as the release notes.

## Code style

- Rust: `cargo fmt`, `cargo clippy --release -- -D warnings`. Both run in CI.
- QL: `codeql query format -i <file>`. The pack-assembly script runs this
  automatically on the auto-generated `TreeSitter.qll`.
- Commit messages: imperative mood, short subject, free-form body. We use
  `M<N>: <description>` for milestone commits inside a planned phase, and
  conventional `ci:` / `deps:` prefixes (set by Dependabot) for everything
  else.

## License

This project is MIT-licensed. By submitting a contribution you agree
that it will be released under the same terms.
