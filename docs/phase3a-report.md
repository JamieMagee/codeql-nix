# Phase 3a Report — CodeQL-for-Nix v0.3.0

**Date**: 2026-05-25
**Author**: @JamieMagee
**Scope**: Port 12 of `nixpkgs-hammering`'s 22 rules to CodeQL queries,
ship them as a separate `nix-code-quality.qls` suite alongside the
existing security suite, and cut `v0.3.0`.

---

## Decision: **GO** for Phase 4 (whatever the next priority is).

Composite GO gate (revised after rubber-duck pass):

1. ✅ All 24 queries compile under the current pack.
2. ✅ All 25 qltests pass (12 security + 12 quality + 1 library).
3. ✅ Full nixpkgs sweep finishes in **40.8 s** for both suites combined (budget was 90 s).
4. ✅ Each new query has ≥1 manually-triaged true positive in nixpkgs (full triage notes in PR bodies #17–#27).
5. ⚠️ Two queries exceed the "no-flood" threshold (2 × `UnusedBinding`'s 5716 findings = 11 432):
   - `nix/attribute-ordering` — 13 002 findings. Justified: rule is intrinsically noisy on real nixpkgs (most packages don't follow strict canonical attribute order); ships at `severity=recommendation` so it stays out of warning-level views.
   - `nix/explicit-phases` — 7 194 findings. Justified: overriding phases is genuinely common in nixpkgs; `severity=recommendation`.
   - Both are documented here and in the queries' qhelp.

---

## What shipped

| Component | Phase 3a change |
|---|---|
| **Extractor** | Unchanged from v0.2.0 |
| **QL library** | New `Derivation.qll` (~200 LoC); the 12 Phase 3a queries depend on it |
| **Queries** | Grew from 12 to **24** (12 new under `Security/CWE-1078/`) |
| **Test fixtures** | One new library test (`Derivation/`) plus 12 new query fixtures under `ql/test/queries/CodeQuality/` |
| **CI** | Unchanged |
| **Distribution** | New `nix-code-quality.qls` suite alongside `nix-code-scanning.qls`. Existing scanning suite now excludes queries tagged `quality` |

### Phase 3a query catalogue (all flagged with `★`)

| ID | Hammering rule | Severity | Findings on nixpkgs | Eval time |
|---|---|---|---|---|
| `nix/attribute-ordering` ★ | `attribute-ordering` | recommendation | 13 002 | 9.2 s |
| `nix/attribute-typo` ★ | `attribute-typo` (narrow) | recommendation | 8 | 6.9 s |
| `nix/build-tools-in-build-inputs` ★ | `build-tools-in-build-inputs` | warning | 109 | 5.1 s |
| `nix/duplicate-check-inputs` ★ | `duplicate-check-inputs` | warning | 10 | 4.7 s |
| `nix/env-vars-at-top-level` ★ | `environment-variables-go-to-env` | warning | 14 | 2.2 s |
| `nix/explicit-phases` ★ | `explicit-phases` | recommendation | 7 194 | 5.0 s |
| `nix/meson-and-cmake` ★ | `meson-cmake` | warning | 53 | 4.9 s |
| `nix/missing-phase-hooks` ★ | `missing-phase-hooks` | warning | 2 441 | (n/a — measured in combined sweep) |
| `nix/name-instead-of-pname-version` ★ | `name-and-version` | warning | 31 | 4.7 s |
| `nix/protected-phase-override` ★ | `fixup-phase` + `patch-phase` | warning | 247 | 4.9 s |
| `nix/unclear-gpl` ★ | `unclear-gpl` | warning | 1 616 | 4.4 s |
| `nix/unnecessary-parallel-building` ★ | `unnecessary-parallel-building` | warning | 106 | 4.7 s |

---

## Performance summary

Phase 2 baseline (12 queries, `--threads=0`): 39 s.
Phase 3a final (24 queries, both suites, `--threads=0`): **40.8 s**.

The 1.8 s overhead for doubling the query set is mostly the new lints
sharing the same `Derivation.qll` predicates and AST tables that were
already cached by Phase 1/2 queries. The Phase 2 `cached` annotations
on `Scope.qll` continue to pay off.

```
[ 1/24 eval   45ms] LegacyLetAttrset
[ 2/24 eval  1.9s ] DeprecatedUriLiteral
…
[22/24 eval 17.9s ] BuiltinsGetEnv
[23/24 eval 18.0s ] UnusedBinding
[24/24 eval 31.1s ] ShellInjectionInBuildPhase
real    0m40.771s
```

---

## What's in the design that's worth highlighting

- **`Derivation.qll` is the keystone.** ~200 LoC. Wraps `stdenv.mkDerivation`, `stdenvNoCC.mkDerivation`, `buildPythonPackage`, `buildPythonApplication`. `getAttrs` peels parens, callbacks (`finalAttrs:`), and `let … in …` bodies. `hasAttr` covers direct + `inherit` + `inherit (expr)`. No `getEnclosingDerivation(AstNode)` predicate — the Phase 2 retrospective documented that as a guaranteed perf trap; all queries instead drive from `DerivationCall.getADirectBinding`.
- **Pilot-then-fleet.** M2–M4 (`MesonAndCmake`, `NameInsteadOfPnameVersion`, `ExplicitPhases`) ran serially first to validate `Derivation.qll`. M6–M14 then fanned out 9-way in parallel sub-agents. Total wall-clock from M1 to all-merged: ~1 hour.
- **Tag-based suite partitioning.** `nix-code-scanning.qls` and `nix-code-quality.qls` are disjoint by `tags`; the existing scanning suite uses `exclude: tags contain quality`, and the new quality suite uses `include: tags contain quality`. Existing users see no findings change unless they opt in.
- **Faithful to hammering, deliberately.** The plan v1 had 5 sketches that diverged from `nixpkgs-hammering` (e.g. duplicate-check-inputs was `buildInputs`↔`checkInputs` instead of `propagatedBuildInputs`↔`checkInputs`). The rubber-duck pass caught all 5; v2 of the plan matches hammering semantics exactly.

## What was tried and dropped

- **Wider wrapper scope.** The plan originally proposed including `buildGoModule`, `buildRustPackage`, `buildNpmPackage`, `mkYarnPackage`, `mkShell`. The rubber-duck pass flagged that these introduce wrapper-specific attrs (`cargoHash`, `npmDepsHash`, `vendorHash`, …) that `attribute-typo` and `attribute-ordering` would flag as false positives. Reduced to hammering parity. Phase 3b candidate: add wrapper-specific attr allowlists, then broaden.
- **General Levenshtein in `attribute-typo`.** Considered. Dropped in favour of case-insensitive equality + a hand-curated typo allowlist (`knownAttr` has 112 entries, `typoOf` has 36). Phase 3b candidate.
- **A `getEnclosingDerivation(AstNode)` helper.** Considered. The rubber-duck pass flagged it as a Phase-2-style perf trap. Skipped. All queries drive from `DerivationCall` outward.

## What's still on `nixpkgs-hammering`'s roster but not yet ported

| Rule | Why not yet |
|---|---|
| `license-missing` | Needs `inherit`-tracing across files to know whether `meta.license` was set via an inherited `meta` |
| `maintainers-missing` | Same |
| `missing-patch-comment` | Needs comment-token adjacency in the AST — possible but a Phase 3b lift |
| `no-python-tests`, `python-explicit-check-phase`, `python-imports-check-typo`, `python-include-tests`, `python-inconsistent-interpreters` | All need evaluator output (the package's `passthru.tests`, wheel contents, or actually-resolved Python interpreters) — out of scope for a static analyser |
| `stale-substitute` | Needs to read the source files being substituted; possible but a big lift |

## Files touched

```
ql/lib/codeql/nix/Derivation.qll                              (+ ~200 LoC)
ql/src/codeql-suites/nix-code-quality.qls                     (new)
ql/src/codeql-suites/nix-code-scanning.qls                    (+1 line: exclude quality)
ql/src/Security/CWE-1078/*.{ql,qhelp}                         (12 new queries)
ql/test/library-tests/Derivation/                             (new)
ql/test/queries/CodeQuality/*/                                (12 new fixtures)
CHANGELOG.md                                                  (0.3.0 entry)
docs/findings/phase3a-full-nixpkgs.sarif                      (archived sweep)
docs/phase3a-report.md                                        (this file)
```
