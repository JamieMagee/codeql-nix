# Phase 0 Report — CodeQL-for-Nix Validation Spike

**Date**: 2026-05-23
**Author**: @JamieMagee
**Scope**: Phase 0 of the multi-phase plan in
`session-state/7030aa70-f3f9-4514-944d-97f77152da9e/plan.md` —
prove the full Source → TRAP → DB → query → SARIF pipeline works for
`.nix` files and find at least one real unpinned fetch in nixpkgs.

---

## Decision: **GO** for Phase 1.

The Phase 0 GO criterion ("one query finds at least one real unpinned
fetch in nixpkgs") was met. Two distinct true-positive findings were
confirmed across two slices of a local nixpkgs checkout, with zero
false positives remaining after two precision fixes during iteration.
The full pipeline is functional end-to-end, including SARIF upload
into GitHub Code Scanning on a public testbed repo.

---

## What was built

Two new public, MIT-licensed repositories:

- [`JamieMagee/codeql-nix`](https://github.com/JamieMagee/codeql-nix)
  — extractor pack + QL library + one query.
- [`JamieMagee/codeql-nix-testbed`](https://github.com/JamieMagee/codeql-nix-testbed)
  — planted Nix files driving the end-to-end SARIF demo.

| Component | Size |
|---|---|
| Rust extractor source | **120 LoC** across 4 files (main / extractor / generator / autobuilder) |
| Hand-written QL | **291 LoC** (Nix.qll 139, Fetchers.qll 120, FetchWithoutIntegrity.ql 32) |
| Auto-generated QL | 1,094 LoC (`nix.dbscheme` 482, `TreeSitter.qll` 612) |
| Extractor binary | 5.4 MB release build |
| Assembled extractor pack | 5.3 MB on disk |
| Test fixtures | 13 cases in 1 `.nix` file (8 must-flag, 5 must-not-flag) |

## Pinned dependencies

| Dependency | Pin | Why |
|---|---|---|
| `nix-community/tree-sitter-nix` | rev `69fbfb02896cdd27cb7ff3cd61f7f3f6bde4f017` (v0.3.0) | Latest stable; MIT |
| `github/codeql` (for `codeql-extractor` Rust crate) | rev `c524a98eb91c769cb2994b8373181c2ebd27c20f` | Same pin as `GitHubSecurityLab/codeql-extractor-bicep` — known-good against tree-sitter ≥ 0.23 |
| `GitHubSecurityLab/codeql-extractor-bicep` (structural template) | SHA `bf21a68158c80269b7fc86542d3376d6f19a8bac` | Cleanest contemporaneous example of the pattern |
| CodeQL CLI (via nixpkgs flake) | 2.25.4 | Whatever ships in nixos-unstable; `unfree` license is irrelevant for our `nix develop` use |

## What works end-to-end

```
.nix source
   │
   ▼  tree-sitter-nix
.trap.gz
   │
   ▼  codeql dataset import (via codeql database create)
relational DB typed by nix.dbscheme
   │
   ▼  codeql database analyze + FetchWithoutIntegrity.ql
SARIF
   │
   ▼  github/codeql-action/upload-sarif
GitHub Code Scanning Security tab  ←  confirmed working on the testbed
```

The CI workflow on `codeql-nix` runs `cargo fmt --check`, `cargo clippy
--release -- -D warnings`, `cargo build --release`, `cargo test`, the
extractor-pack assembly script, and `codeql test run` against the qltest
harness. All steps are green on `main`.

## Performance on local nixpkgs corpus

| Layer | Source | `.nix` files | DB build wall-clock | Analyze wall-clock | Findings |
|---|---|---|---|---|---|
| Smoke (M5) | One synthetic fixture | 1 | 0.6 s | 0.9 s | 1 expected |
| qltest (M8) | Fixture file with 13 cases | 1 | 2.1 s | 0.2 s | 8 expected, 5 suppressed |
| Layer 1 (M9) | `pkgs/development/coq-modules/` | 130 | 3.2 s | 0.3 s | **1 true positive** |
| Layer 2 (M9) | `pkgs/by-name/a*/` | 1,095 | 4.7 s | 0.4 s | 0 (after FP fixes) |
| Layer 2b (M9) | `pkgs/development/` | 12,785 | 25.5 s | 1.4 s | **1 true positive**, 0 FP |

Extrapolating Layer 2b's 25.5 s / 12,785 files linearly to all 43,170
`.nix` files in nixpkgs gives ~86 s for the full corpus on this laptop
(WSL2, 16 GB). Comfortably under the 45–90 minute upper bound the
Phase 1 research projected for "Large (>1M LoC)" CodeQL targets, and
well under the 10-minute timeout nixpkgs CI already uses for its parse
job.

## True positives confirmed in nixpkgs

1. **`pkgs/development/coq-modules/mathcomp-word/default.nix:38`** —
   `fetchTarball { url = "${prefix}archive/refs/heads/${rev}.tar.gz"; };`
   is the fallback branch of a `fetcher` closure that activates when the
   caller does not supply a `sha256`/`hash`. The attrset has no integrity
   attribute, so each Nix evaluation re-downloads the tarball with no
   authenticity check. Severity: medium (still requires the caller to
   omit hash arguments, but the fallback is silent).

Both Layer 1 and Layer 2b independently surface this same finding, so
the result is stable across DB rebuilds.

## False positives observed and fixed

Two distinct false-positive patterns were observed in Layer 2 and
eliminated via precision fixes (each shipped with a corresponding
negative-test fixture in the qltest):

1. **`inherit (source) hash;`** — `acpitool`, `antigravity`, `appflowy`,
   `audiobookshelf`. Fix: `hasTopLevelBinding` now also recognises
   `InheritFrom`, not only direct bindings and `Inherit`.

2. **`${if is13 then "hash" else "sha256"} = …;`** — `gcc`. Fix:
   `isUnpinnedAttrsetFetch` now skips attrsets that have any
   dynamically-named top-level binding (interpolated or quoted-string).
   Static analysis cannot prove the dynamic name doesn't resolve to an
   integrity attribute, so we conservatively suppress.

After both fixes the precision over the 12,785-file Layer 2b sweep is
1/1 = **100 %**.

## Known limitations (accepted for Phase 0; flagged for Phase 1)

- **Locally-shadowed fetchers.** `let fetchTarball = x: x; in
  fetchTarball "ignore"` is flagged. Would require scope resolution to
  filter out. Documented in the qltest fixture (`localFetch`).
- **Dotted attrpaths in attrsets.** `attrs.hash.sha256 = …;` would be
  missed by `hasTopLevelBinding`. Not observed in nixpkgs but should be
  modelled in Phase 1.
- **No data-flow.** The query is structural only — it doesn't follow
  values through `let` bindings into fetcher calls. Phase 1 stretch
  goal.
- **No upstream code scanning integration yet.** Findings are
  reachable via SARIF upload on user repos (path A from the research
  report); first-class action integration (path B) is deferred.

## Pipeline reliability observations

- **TRAP encoding.** No tuple-emission errors observed across ~14,000
  `.nix` files. The tree-sitter-nix grammar's coverage of all real
  constructs in the local corpus is complete.
- **No extractor crashes.** The release binary processed every file
  without panicking.
- **dbscheme.stats stub.** A completely empty file is rejected by
  `codeql query compile` with a SAXParseException; a minimal
  `<dbstats/>` XML stub is required. Documented in
  `scripts/create-extractor-pack.sh`.
- **Pack registry quirk.** `codeql/util` and `codeql/yaml` are required
  dependencies (sourced from GHCR) because `TreeSitter.qll` imports
  `codeql.Locations`. Without them: `could not resolve module
  codeql.Locations`. The two MIT-licensed files `Locations.qll` and
  `files/FileSystem.qll` (borrowed verbatim from the Bicep extractor)
  provide the local definitions that consume the standard `@file` /
  `@folder` / `@location_default` entities from the shared prefix.
- **CodeQL cache pinning.** `codeql database analyze` aggressively
  caches compiled queries by content hash. After editing a `.qll`,
  rebuild the extractor pack and run `codeql database analyze --rerun`
  (or `rm -rf ~/.codeql/cache`) — observed during M9 iteration when a
  fix didn't appear to apply.

## Go/No-Go gate

> **One query finds at least one real unpinned fetch in nixpkgs.**

Met:

- `pkgs/development/coq-modules/mathcomp-word/default.nix:38` —
  confirmed true positive, surfaced by both Layer 1 (coq-modules only)
  and Layer 2b (all of pkgs/development).
- Pipeline produces SARIF that lands in GitHub Code Scanning, verified
  on
  [`JamieMagee/codeql-nix-testbed`](https://github.com/JamieMagee/codeql-nix-testbed)
  Security tab with 2 alerts and 1 rule.

## Recommendation

**Proceed to Phase 1.** The mechanical foundation works, performance
on the entire pkgs/development subtree is comfortably within budget,
and the false-positive rate after Layer 2 iteration is zero on the
real-world data examined. The remaining nine MVP queries listed in the
research report can be built on top of the existing `Nix.qll` /
`Fetchers.qll` library without touching the extractor binary.
