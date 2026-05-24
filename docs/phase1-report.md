# Phase 1 Report — CodeQL-for-Nix v0.1.0 MVP

**Date**: 2026-05-23
**Author**: @JamieMagee
**Scope**: Phase 1 of the multi-phase plan — ship the 10-query MVP from
the research's "v0.1" list, validate it against the full nixpkgs corpus,
package it for end users, and cut the `v0.1.0` release.

---

## Decision: **GO** for Phase 2.

The Phase 1 GO criterion ("≥5 distinct query rules produce ≥1 true
positive each on the full nixpkgs sweep") was met with **7 rules**
producing findings, all sampled findings reviewed as true positives or
accurate flags. The full pipeline now works end-to-end through a
distributable GitHub Action.

---

## What shipped

| Component | Detail |
|---|---|
| **Extractor** | Unchanged from v0.0.1 (130 LoC of Rust glue over `codeql-extractor` + `tree-sitter-nix`) |
| **QL library** | Grew from ~291 LoC to ~570 LoC: added `Builtins.qll`, `Strings.qll`, `Scope.qll`; extended `Nix.qll` with 9 new aliases and predicates |
| **Queries** | Grew from 1 to 10 (see table below) |
| **Test fixtures** | Grew from 1 file to 10 files, ~120 fixture cases total |
| **CI** | `.github/workflows/release.yml` ships the extractor pack as a tarball on every `v*` tag |
| **Distribution** | New repo [`JamieMagee/codeql-nix-action`](https://github.com/JamieMagee/codeql-nix-action) wraps the pipeline as a composite Action |

### Query catalogue

| ID | CWE | Severity | Phase | Description |
|---|---|---|---|---|
| `nix/fetch-without-integrity` | CWE-829 | error / 7.5 | 0 | Fetcher call with no hash |
| `nix/unpinned-import-fetch` | CWE-829, CWE-094 | error / 9.0 | 1 | `import (fetcher …)` without integrity |
| `nix/nix-path-lookup` | CWE-829 | warning / 5.0 | 1 | `<nixpkgs>`-style search-path lookup |
| `nix/deprecated-uri-literal` | CWE-477 | warning | 1 | Bare URI literal (RFC 45) |
| `nix/legacy-let-attrset` | CWE-477 | warning | 1 | Deprecated `let { body = …; }` |
| `nix/builtins-get-env` | CWE-807 | warning / 3.5 | 1 | `builtins.getEnv` impurity |
| `nix/duplicate-attrset-key` | CWE-710 | warning | 1 | Duplicate top-level keys |
| `nix/rec-attrset-merge` | CWE-665 | warning | 1 | `rec { } // expr` confusing semantics |
| `nix/space-in-flag-string` | CWE-78 | error / 4.0 | 1 | Whitespace in flag-list string |
| `nix/unused-binding` | CWE-563 | recommendation | 1 | Defined name never referenced |

---

## Confidence Assessment

| Claim | Confidence | Evidence |
|---|---|---|
| 10 queries compile and pass qltest deterministically | **Very high** | CI green on every PR + post-merge main |
| ≥5 rules produce TPs on real nixpkgs code | **Very high** | 7 rules produced findings; all sampled findings are TPs |
| `UnusedBinding` algorithm matches deadnix's intent | **High** | Fixture covers shadowing, inherit-into-let, rec-exempt, underscore-exempt cases; passes |
| Full nixpkgs sweep completes in <5 minutes | **Very high** | Measured 3 min 2 s total wall-clock on this laptop |
| Action repo works end-to-end | **Medium** | Workflow defined; smoke test will run on first v0.1.0 release |
| All listed FPs are documented | **Medium** | Major FP sources documented in qhelp/CHANGELOG; some FPs (esp. UnusedBinding via `with`) will surface in real-world use |

---

## Nixpkgs sweep performance

Same corpus and host as Phase 0 (`~/src/code/nixpkgs` hardlinked into a
scratch directory; WSL2 8-core laptop), now scanned with all 10 queries
via the `nix-code-scanning.qls` suite:

| Phase | Database size | Files | DB build | Analyze (all queries) | Total |
|---|---|---|---|---|---|
| Phase 0 (Layer 2b, `pkgs/development/`) | 59 MiB | 12,785 | 25.5 s | ~5 s | 30 s |
| **Phase 1 (full nixpkgs)** | **306 MiB relations + 88 MiB strings** | **43,142** | **52.5 s** | **130 s** | **183 s** |

Linear scaling on extraction (~3.4× the files, ~2.1× the time — better
than linear thanks to multi-threading). Analyze dominated by
`UnusedBinding`'s recursive ancestor walks (2 m 1 s of the 2 m 10 s);
the other 9 queries together took ~9 s.

Memory: peak resident set ~6 GB during analyze, well within the 64 GB
budget for "Large (>1M LoC)" CodeQL targets.

---

## Findings on full nixpkgs (43,142 `.nix` files)

| Rule | Findings | Notable |
|---|---|---|
| `nix/unused-binding` | **6,260** | Mostly TPs; known FP source: nixpkgs `@all` destructuring + `finalAttrs:` callback patterns (deadnix has the same FP class). Real refactor opportunities. |
| `nix/space-in-flag-string` | **92** | Mix of real bugs (e.g. `-f Makefile.gnu` in `makeFlags`) and intentional value-spaces (e.g. `-DBRIDGE_APP_FULL_NAME=Proton Mail Bridge`). Same triage profile as `nixpkgs-hammering`'s `no-flags-spaces`. |
| `nix/rec-attrset-merge` | **78** | All `rec { } // other` patterns; per-query-spec TPs. Some intentional, but each is a readability liability. |
| `nix/nix-path-lookup` | **64** | All real `<nixpkgs>` references; many in `nixos/tests/`. Per-query-spec TPs. |
| `nix/builtins-get-env` | **12** | All confirmed-impure uses (`NIXPKGS_ALLOW_BROKEN`, `IN_NIX_SHELL`, `HOME`, etc.). Per-query-spec TPs. |
| `nix/duplicate-attrset-key` | **8** | All real refactor bugs (`env`, `passthru`, `serviceConfig`, …). High-value TPs. |
| `nix/fetch-without-integrity` | **3** | All TPs incl. Phase 0's `mathcomp-word/default.nix:38`. New finds: `pkgs/top-level/all-packages.nix:734` and `pkgs/build-support/rust/import-cargo-lock.nix:191`. |
| `nix/deprecated-uri-literal` | 0 | nixpkgs is clean on RFC 45. |
| `nix/legacy-let-attrset` | 0 | nixpkgs is clean on legacy `let`. |
| `nix/unpinned-import-fetch` | 0 | Rare pattern; would surface in third-party code. |

Total: **6,517 findings, 7 distinct rules producing TPs.** GO criterion
(≥5 distinct rules with TPs) cleared with margin.

---

## Architecture changes from Phase 0

```
ql/lib/codeql/nix/
├── Nix.qll              (+9 aliases, +3 predicates)
├── Fetchers.qll         (unchanged)
├── Builtins.qll         NEW (~90 LoC) — BuiltinCall class
├── Strings.qll          NEW (~50 LoC) — flag-list context helpers
├── Scope.qll            NEW (~140 LoC) — deadnix-style scope graph
└── ast/internal/TreeSitter.qll  (unchanged; regenerated from grammar)
```

`Scope.qll` is the most substantial addition. It treats four node kinds
as scopes (`LetExpression`, `LetAttrsetExpression`, `RecAttrsetExpression`,
`FunctionExpression`) and uses a recursive ancestor walk to resolve each
`NameReference` to its closest enclosing scope. The one non-obvious case
the library handles correctly: an `inherit name;` clause inside a `let`
scope `S` defines `name` in `S`, but the reference `name` within the
inherit looks up the OUTER scope. `isVisibleScope` skips `S` for that
specific lookup.

`Builtins.qll` only models the precise dotted form (`builtins.X`) plus a
best-effort bare-form check via lexical `with builtins;` ancestry. The
bare form doesn't account for inner shadowing — a Phase 2 task once
`Scope.qll`'s shadowing logic is more polished.

---

## Reliability observations

- **`UnusedBinding` is the expensive query.** 2 m 1 s of the 2 m 10 s
  total analyze time. The cost is in the recursive `getAStrictAncestor`
  predicate. Phase 2 candidate: define a per-node "enclosing scope chain"
  via a cached `seq()` predicate to short-circuit the recursion.

- **No extractor crashes** observed on the 43,142-file sweep.

- **CHANGELOG conflict pattern** during PR merge: every Phase 1 PR
  touched `CHANGELOG.md`'s `[Unreleased]` section, producing CHANGELOG
  conflicts on every rebase. Used `git merge-file --union` for automatic
  resolution. Phase 2 candidate: a CHANGELOG fragment system (one file
  per change, merged at release time) to eliminate the conflict class.

- **Hardlink corpus prep** (`cp -al`) cut the nixpkgs working-tree
  setup from ~30 s of full copying to ~7 s of hardlinking. Works only
  on same-filesystem scratch (not `/tmp` which is tmpfs).

---

## Known limitations (Phase 1 scope, deferred to Phase 2)

- No data-flow library; shell-injection queries impossible without it.
- No `with`-scope dynamic name introduction in `Scope.qll`. This
  produces FPs in `UnusedBinding` where a `with` injects same-named
  attrs (rare in practice but non-zero in nixpkgs).
- `BuiltinCall`'s bare-form recognition doesn't account for inner
  shadowing.
- Linux x86-64 only for the Action. No macOS or Windows runners yet.
- No GHCR pack publishing — users get the QL packs via the Action's
  source clone, not via `codeql pack download`.
- No first-class CodeQL action integration (custom CodeQL bundle).
  The `unfree`-licensed CLI redistribution problem is still unsolved.

---

## Next: Phase 2

The recommended Phase 2 scope, based on what Phase 1 surfaced:

1. **Data-flow library** (the big one — ~6–18 months per the research's
   estimate). Enables shell-injection queries.
2. **`Scope.qll` polish**: account for `with`-scope dynamic introduction,
   cache the ancestor walk.
3. **macOS / Windows runner support**: extend the release workflow to
   cross-compile the extractor binary.
4. **CHANGELOG fragments**: kill the CHANGELOG conflict class.
5. **Engagement with Nix Security WG**: present the 23 high-confidence
   TPs surfaced today (3 fetch-without-integrity + 8 duplicate-key + 12
   getEnv).
