# codeql-nix

A [CodeQL](https://codeql.github.com) extractor and query pack for the [Nix expression language](https://nix.dev/manual/nix/2.18/language/).

> [!WARNING]
> Phase 1 — building the MVP query set. See [`CHANGELOG.md`](./CHANGELOG.md) for details. Phase 0 ([`docs/phase0-report.md`](./docs/phase0-report.md)) validated the pipeline end-to-end.

## What this is

`codeql-nix` enables static analysis of `.nix` source files using GitHub's CodeQL platform. It builds on:

- [`nix-community/tree-sitter-nix`](https://github.com/nix-community/tree-sitter-nix) for parsing
- The [`codeql-extractor`](https://github.com/github/codeql/tree/main/shared/tree-sitter-extractor) shared Rust crate for TRAP emission

The initial scope is supply-chain hygiene — the kind of checks `statix` / `deadnix` / `nixpkgs-hammering` don't target.

## What's planned

| Phase | Status | Scope |
|---|---|---|
| **Phase 0** | ✅ Complete (see [`docs/phase0-report.md`](./docs/phase0-report.md)) | One query (`FetchWithoutIntegrity`), full pipeline validated end-to-end |
| **Phase 1** | 🚧 In progress | 10 MVP syntactic queries + `v0.1.0` release |
| Phase 2 | Not started | Data-flow library, shell-injection queries |

## Building

Requires Nix with flakes enabled.

```bash
nix develop                              # enter dev shell
cargo build --release                    # build the extractor
./scripts/create-extractor-pack.sh       # assemble extractor-pack/
codeql resolve extractor --search-path=./extractor-pack
```

## Running on a Nix codebase

```bash
codeql database create /tmp/nix-db \
  --language=nix \
  --source-root=path/to/nix/sources \
  --search-path=./extractor-pack

codeql database analyze /tmp/nix-db ./ql/src \
  --format=sarif-latest \
  --output=results.sarif
```

## License

MIT — see [LICENSE](./LICENSE).

The CodeQL CLI itself is not redistributed by this project and is subject to its own [terms](https://github.com/github/codeql-cli-binaries).
