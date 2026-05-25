# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `ql/lib/codeql/nix/Derivation.qll`: recognises calls to nixpkgs-style
  derivation wrappers (`stdenv.mkDerivation`, `stdenvNoCC.mkDerivation`,
  `buildPythonPackage`, `buildPythonApplication` — faithful to
  `nixpkgs-hammering`'s scope) and exposes `getKind`, `getAttrs`,
  `hasAttr`, `getDirectBinding`, `getADirectBinding`, and
  `getNthAttrName`. `getAttrs` peels through parens, the
  `(finalAttrs: { … })` callback shape, and `let … in { … }` bodies.
  Foundation for the Phase 3a `nixpkgs-hammering`-port queries.
- `ql/test/library-tests/Derivation/`: library-level test covering 12
  derivation-call shapes including callback, callback+rec, callback+let,
  parens, plain rec, both Python wrappers, and `inherit` / inherit-from
  cases.
- `ql/src/Security/CWE-1078/MesonAndCmake.ql` (plus qhelp and
  `ql/test/queries/CodeQuality/MesonAndCmake/`): ports
  `nixpkgs-hammering`'s `meson-cmake` rule. Flags derivations whose
  `nativeBuildInputs` declare both `meson` and `cmake`, where nixpkgs
  convention is to pick one primary configure-phase build system.
- `ql/src/Security/CWE-1078/NameInsteadOfPnameVersion.{ql,qhelp}`: ports
  nixpkgs-hammering's `name-and-version` rule, flagging derivations that
  set `name` and `version` without `pname`; includes a CodeQuality qltest
  fixture covering direct, `inherit`, callback, and `buildPythonPackage`
  forms.
- `ql/src/Security/CWE-1078/ExplicitPhases.ql` plus qhelp and query tests:
  ports nixpkgs-hammering's `explicit-phases` rule, reporting direct
  overrides of `configurePhase`, `buildPhase`, `checkPhase`, and
  `installPhase` while leaving hook-based customization and unrelated
  phases to their dedicated rules.
- `ql/src/Security/CWE-1078/ProtectedPhaseOverride.ql` (plus qhelp and
  `ql/test/queries/CodeQuality/ProtectedPhaseOverride/`): ports
  `nixpkgs-hammering`'s `fixup-phase` and `patch-phase` rules. Flags
  derivations that override `fixupPhase` or `patchPhase` directly
  instead of extending the default phase with `pre*` / `post*` hooks.
- `ql/src/Security/CWE-1078/MissingPhaseHooks.ql` (plus qhelp and
  `ql/test/queries/CodeQuality/MissingPhaseHooks/`): ports
  `nixpkgs-hammering`'s `missing-phase-hooks` rule for
  `configurePhase`, `buildPhase`, `checkPhase`, and `installPhase`.
  Flags string-literal phase overrides that omit the corresponding
  `runHook preX` and/or `runHook postX` calls.
- `ql/src/Security/CWE-1078/AttributeTypo.ql` (plus qhelp and
  `ql/test/queries/CodeQuality/AttributeTypo/`): ports the narrow Phase
  3a variant of `nixpkgs-hammering`'s `attribute-typo` rule. Flags
  likely top-level derivation-attribute typos when they are either
  case-only mistakes or members of a handwritten typo allow-list; leaves
  unrelated custom attributes alone.
- `ql/src/Security/CWE-1078/DuplicateCheckInputs.ql` (plus qhelp and
  `ql/test/queries/CodeQuality/DuplicateCheckInputs/`): ports
  `nixpkgs-hammering`'s `duplicate-check-inputs` rule. Flags
  derivations that repeat a package from `propagatedBuildInputs` in
  `checkInputs` or `nativeCheckInputs`, where the check-time copy is
  redundant.
- `ql/src/Security/CWE-1078/AttributeOrdering.ql` (plus qhelp and
  `ql/test/queries/CodeQuality/AttributeOrdering/`): ports
  `nixpkgs-hammering`'s `attribute-ordering` rule. Flags derivation
  attributes that appear before the canonical predecessor they should
  follow, while ignoring unknown attributes and `inherit` clauses.
- `ql/src/Security/CWE-1078/UnclearGpl.ql` (plus qhelp and
  `ql/test/queries/CodeQuality/UnclearGpl/`): ports
  `nixpkgs-hammering`'s `unclear-gpl` rule. Flags deprecated ambiguous
  GNU license aliases in derivation `meta.license` bindings and
  recommends the explicit `Only` / `Plus` variant instead.

### Changed

- `ql/src/codeql-suites/nix-code-scanning.qls`: now excludes queries
  tagged `quality`. Existing queries (tagged `maintainability` /
  `correctness`) are unaffected; Phase 3a quality lints will be picked
  up by the new `nix-code-quality.qls` suite instead.

## [0.2.0] — 2026-05-24 (Phase 2)

### Added

- `ql/lib/codeql/nix/Taint.qll`: a lightweight taint-tracking library
  targeting the shell-injection use case. Defines `Source` (untrusted
  function formals via a nixpkgs-aware allow-list, `builtins.getEnv`),
  `Sink` (interpolations and direct bindings to shell-context
  attributes, excluding path-style `${pkg}/...` patterns),
  `Sanitizer` (`lib.escapeShellArg`/`lib.escapeShellArgs`), and
  `flowsTo` / `isReachableFromSanitizer` predicates. Self-contained —
  does NOT depend on `DataFlow::InputSig` (that's a Phase 3 project).
- `ql/src/Security/CWE-077/ShellInjectionInBuildPhase.ql` (CWE-077,
  CWE-078): reports flows from untrusted sources into shell-context
  attribute interpolations without `lib.escapeShellArg`.
- `ql/src/Security/CWE-077/MissingShellEscape.ql` (CWE-077, CWE-078):
  reports any shell-context interpolation that is not preceded by a
  sanitizer call. The defensive-coding counterpart of the above.
- `Scope.qll`: `isCallbackArgName` predicate exempting `finalAttrs`,
  `prevAttrs`, and `oldAttrs` from `UnusedBinding` (deadnix convention).

### Changed

- `Scope.qll`: `getAStrictAncestor` and `resolvesTo` are now `cached`.
  This materialises the recursive ancestor closure once per database
  and drops `UnusedBinding` full-nixpkgs analyze time from ~2 minutes
  to ~16 seconds. Required to make `Taint.qll`'s flow predicates
  tractable on the full nixpkgs corpus.

### Performance

- Full nixpkgs analyze time (43,142 .nix files, 12 queries,
  `--threads=0`): ~39 s, down from ~3 m 2 s in Phase 1's 10-query
  baseline despite adding two flow-based queries.

### Notes

- `FetcherCall` and `import` were dropped from the `Source` set during
  Phase 2 triage: they always evaluate to Nix store paths or attrsets,
  never to user-controlled strings that can break shell quoting.
  Including them as sources produced almost-exclusively false positives.
- The `with`-scope handling and explicit `defUseChain` caching items
  from the Phase 2 plan were deferred to Phase 3 — neither produced a
  precision or performance improvement large enough to justify their
  cost when evaluated in isolation.

## [0.1.0] — 2026-05-23 (Phase 1)

### Added

- `.github/workflows/release.yml`: triggered on `v*` tag pushes. Builds
  the extractor pack, packages it as `codeql-extractor-nix-vX.Y.Z-linux64.tar.gz`,
  pulls the matching CHANGELOG section as release notes, and creates a
  GitHub Release with the tarball as an asset.
- `ql/lib/codeql/nix/Scope.qll`: lexical scope library porting deadnix's
  fixpoint scope analysis to QL. Exposes `Scope`, `NameReference`,
  `resolvesTo`, and `isUnusedBinding` predicates handling let-bindings,
  let-attrset bindings, function formals + universal, and inherit
  clauses (with correct outer-scope resolution for `inherit name;`).
- `ql/src/Security/CWE-563/UnusedBinding.ql`: reports defined names
  that have no in-scope reference. Skips `rec { }` and the legacy
  `let { body = …; }`'s `body` attribute (both externally visible);
  exempts identifiers starting with `_` (deadnix convention).
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
- `DuplicateAttrsetKey.ql` (CWE-710): detects duplicate top-level keys in a single attrset literal before evaluation fails.
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
- `NixPathLookup.ql` (CWE-829): detects `<...>`-style search-path lookups
  that depend on the ambient `$NIX_PATH`.
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

[Unreleased]: https://github.com/JamieMagee/codeql-nix/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/JamieMagee/codeql-nix/releases/tag/v0.1.0
[0.0.1]: https://github.com/JamieMagee/codeql-nix/releases/tag/v0.0.1
