# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `BuiltinsGetEnv.ql` (CWE-807): flags `builtins.getEnv` and bare `getEnv`
  calls under `with builtins;` because they read the host environment during
  evaluation.
- `DeprecatedUriLiteral.ql` (CWE-477): flags bare URI literals deprecated by Nix RFC 45 and recommends quoted strings.
- `ql/src/Security/CWE-829/UnpinnedImportFetch.ql` (CWE-829, CWE-094): detects
  `import` of unpinned fetcher results, where network-controlled content is
  fetched and immediately evaluated as Nix code.
- `ql/src/Security/CWE-078/SpaceInFlagString.ql` (plus qhelp and tests) to detect flag-list string literals with embedded whitespace that Bash word-splits into multiple argv entries.
- `RecAttrsetMerge.ql` (CWE-665): warns when `//` merges a `rec { ... }`
  attrset, since recursive references do not see the merged result.
- Phase 1 library expansion:
  - `ql/lib/codeql/nix/Builtins.qll` — `BuiltinCall` class recognising
    `builtins.X` invocations and (best-effort) bare `X` references
    under a `with builtins;` scope.
  - `ql/lib/codeql/nix/Strings.qll` — `isListElementOfBinding(node, attrName)`
    helper plus an `isFlagListAttributeName` allow-list of `mkDerivation`
    argv-style attributes.
  - `Nix.qll`: new aliases (`LetExpression`, `LetAttrsetExpression`,
    `FunctionExpression`, `Formals`, `Formal`, `WithExpression`,
    `LookupPath`, `BareUriLiteral`, `BinaryExpression`), plus
    `hasInterpolation`, `indentedHasInterpolation`, `isLookupPath`
    predicates.
- `CHANGELOG.md` and `CONTRIBUTING.md`.
- `ql/src/Security/CWE-477/LegacyLetAttrset.ql` (CWE-477): flags the deprecated
  legacy `let { body = …; }` attrset syntax and recommends modern
  `let ... in ...` instead.

## [0.0.1] — 2026-05-23 (Phase 0)

### Added

- Initial extractor: Rust binary wrapping `tree-sitter-nix` via the
  shared `codeql-extractor` crate from `github/codeql`.
- Auto-generated `nix.dbscheme` (31 Nix node types, 33 tables) and
  `TreeSitter.qll` from `tree-sitter-nix` v0.3.0 `node-types.json`.
- Hand-written QL library (`codeql.nix.Nix`, `codeql.nix.Fetchers`).
- `FetchWithoutIntegrity.ql` (CWE-829): one query detecting bare-string
  and attrset-missing-hash fetcher calls.
- qltest harness with 13-case fixture.
- GitHub Actions CI: `cargo fmt`/`clippy`/`build`/`test` plus extractor-pack
  assembly and `codeql test run` on push and PR.
- End-to-end SARIF demo via [`JamieMagee/codeql-nix-testbed`](https://github.com/JamieMagee/codeql-nix-testbed).

[Unreleased]: https://github.com/JamieMagee/codeql-nix/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/JamieMagee/codeql-nix/releases/tag/v0.0.1
