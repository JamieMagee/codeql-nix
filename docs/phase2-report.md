# Phase 2 Report — CodeQL-for-Nix v0.2.0

**Date**: 2026-05-24
**Author**: @JamieMagee
**Scope**: Phase 2 of the multi-phase plan — ship a lightweight
taint-tracking library and two shell-injection queries on top of
Phase 1's 10-query MVP, validate them against the full nixpkgs
corpus, and cut the `v0.2.0` release.

---

## Decision: **GO** for Phase 3.

The Phase 2 GO criterion ("shell-injection query produces ≥5 real
true positives in nixpkgs") was met by 9 manually-triaged true
positives in the first sample of 30 random findings, with several
more obvious TPs visible in the remaining 661 ShellInjection results.

Full sweep across 43,142 .nix files now completes in **39 seconds**
with all 12 queries (down from Phase 1's 3 m 2 s with 10 queries),
thanks to `cached` annotations on the hot scope-resolution
predicates and the sink-anchored design of `Taint.qll`.

---

## What shipped

| Component | Phase 2 change |
|---|---|
| **Extractor** | Unchanged from v0.1.0 |
| **QL library** | New `Taint.qll` (~280 LoC); `Scope.qll` gained `isCallbackArgName` and `cached` on `getAStrictAncestor` + `resolvesTo` |
| **Queries** | Grew from 10 to 12 (two CWE-077 queries added) |
| **Test fixtures** | Two new shared fixtures under `ql/test/queries/Security/CWE-077/` |
| **CI** | Unchanged — `release.yml` from Phase 1 reused |
| **Distribution** | `codeql-nix-action` continues to pin `latest`; v0.2.0 is the new floor |

### Updated query catalogue

The two new queries in Phase 2 are flagged with `★`.

| ID | CWE | Severity | Description |
|---|---|---|---|
| `nix/fetch-without-integrity` | CWE-829 | error / 7.5 | Fetcher call with no hash |
| `nix/unpinned-import-fetch` | CWE-829, CWE-094 | error / 9.0 | `import (fetcher …)` without integrity |
| `nix/nix-path-lookup` | CWE-829 | warning / 5.0 | `<nixpkgs>`-style search-path lookup |
| `nix/deprecated-uri-literal` | CWE-477 | warning | Bare URI literal (RFC 45) |
| `nix/legacy-let-attrset` | CWE-477 | warning | Deprecated `let { body = …; }` |
| `nix/duplicate-attrset-key` | CWE-710 | warning | Duplicate static keys in attrset |
| `nix/rec-attrset-merge` | CWE-665 | warning | Conflicting `rec` attrset merges |
| `nix/builtins-get-env` | CWE-807 | warning / 6.5 | Build-time `builtins.getEnv` use |
| `nix/space-in-flag-string` | CWE-078 | warning | Likely-misplaced space in a compiler flag |
| `nix/unused-binding` | CWE-563 | note | deadnix-style unused let/formal binding |
| `nix/shell-injection-in-build-phase` ★ | CWE-077, CWE-078 | error / 8.0 | Untrusted value → shell-context attr (no `escapeShellArg`) |
| `nix/missing-shell-escape` ★ | CWE-077, CWE-078 | warning / 6.5 | Any shell-context interpolation without sanitiser (defensive) |

### Full-nixpkgs results

| Rule | Findings |
|---|---|
| `nix/missing-shell-escape` | 15 782 |
| `nix/unused-binding` | 5 716 |
| `nix/shell-injection-in-build-phase` | 691 |
| `nix/space-in-flag-string` | 92 |
| `nix/rec-attrset-merge` | 78 |
| `nix/nix-path-lookup` | 64 |
| `nix/builtins-get-env` | 12 |
| `nix/duplicate-attrset-key` | 8 |
| `nix/fetch-without-integrity` | 3 |
| `nix/deprecated-uri-literal` | 0 |
| `nix/legacy-let-attrset` | 0 |
| `nix/unpinned-import-fetch` | 0 |

Full SARIF: [`findings/phase2-full-nixpkgs.sarif`](findings/phase2-full-nixpkgs.sarif).

### Triage of shell-injection TPs

Confirmed true positives in the random-sampled triage (all are
unquoted or partially-quoted shell interpolations of user-controlled
formals — `pname`, `version`, or similar — and are exploitable via
`derivation.overrideAttrs (prev: { version = "…\$(rm -rf /)…"; })`):

| File:line | Pattern |
|---|---|
| `pkgs/development/misc/resholve/resholve.nix:53` | `substituteInPlace $file --subst-var-by version ${version}` (unquoted) |
| `pkgs/tools/package-management/akku/akkuDerivation.nix:51` | `xargs ${parse-akku} merge ${pname} ${version} > temp___` (unquoted, two formals) |
| `pkgs/applications/virtualization/singularity/generic.nix:213` | `$configureScript -V ${version} …` (unquoted) |
| `pkgs/applications/video/kodi/build-kodi-binary-addon.nix:57` | `${n}.so.${version}` — version embedded in a filename |
| `pkgs/by-name/sd/sdrplay/darwin.nix:40` | `root="$PWD/Library/SDRplayAPI/${version}"` — version embedded in a path |
| `pkgs/applications/virtualization/docker/default.nix:323` | `export VERSION="${version}"` — `$`/`\`/`` ` `` still expand in double quotes |
| `pkgs/applications/misc/sweethome3d/linux.nix:127` | `-jar $out/share/java/SweetHome3D-${version}.jar` — version in a `-jar` arg |
| `nixos/tests/common/acme/server/generate-certs.nix:24` | `minica … --domains ${domain}` (unquoted) |
| `pkgs/by-name/sm/sm64ex/package.nix:62` | `ln -s ${baseRom} ./baserom.${region}.z64` — region in a filename |

Many more in the remaining 682 ShellInjection findings; the random
sample shows the bug-density is high enough that `pname`, `version`,
and the rare attacker-controlled formal account for the majority of
the alerts.

---

## Performance summary

Phase 1 baseline (`v0.1.0`, 10 queries, `--threads=0`): **3 m 2 s**.

Phase 2 final (`v0.2.0`, 12 queries, `--threads=0`):

```
[1/12 eval 61ms]  CWE-477/LegacyLetAttrset.bqrs
[2/12 eval 1.9s]  CWE-477/DeprecatedUriLiteral.bqrs
[3/12 eval 3.1s]  CWE-829/UnpinnedImportFetch.bqrs
[4/12 eval 5s]    CWE-077/MissingShellEscape.bqrs
[5/12 eval 5s]    CWE-665/RecAttrsetMerge.bqrs
[6/12 eval 5s]    CWE-829/NixPathLookup.bqrs
[7/12 eval 5.9s]  CWE-078/SpaceInFlagString.bqrs
[8/12 eval 5.9s]  CWE-829/FetchWithoutIntegrity.bqrs
[9/12 eval 6.2s]  CWE-710/DuplicateAttrsetKey.bqrs
[10/12 eval 12s]  CWE-807/BuiltinsGetEnv.bqrs
[11/12 eval 16s]  CWE-563/UnusedBinding.bqrs
[12/12 eval 31s]  CWE-077/ShellInjectionInBuildPhase.bqrs
real    0m39.083s
```

The 5× speedup came almost entirely from adding `cached` to two
`Scope.qll` predicates. `UnusedBinding`'s analyze time dropped from
~2 m (Phase 1) to ~16 s (Phase 2). Without caching, the new flow
queries were entirely intractable on full nixpkgs (~25 min + spilling
to disk).

## What was tried and dropped

These items appeared in the Phase 2 plan but were dropped before
release; each is a Phase 3 candidate:

- **`containsWith(Scope)` in `Scope.qll`** — flagged any `Scope`
  whose body contains a `WithExpression` and skipped `UnusedBinding`
  for it. Eliminated a known FP class but slowed `UnusedBinding` by
  ~7×. Reverted; documented in commit `<hash>`.
- **Cached `defUseChain` predicate in `Taint.qll`** — was speculated
  in the plan as a precaution against join blowups. Not needed once
  the let-binding `flowStep` clause was restructured to drive from
  the cached `resolvesTo` predicate.
- **Including `FetcherCall` / `import` in `Source`** — produced
  >3,500 false positives because store paths and attrsets aren't
  shell-unsafe. Removed during triage.

## What's in the design that's worth highlighting

- **Sink-anchored flow.** `flowsTo(Source, Sink)` is defined via
  `flowsToSink(Expr, Sink)` (a backwards walk from `Sink`). The seed
  set of sinks (~23k) is far smaller than the set of sources (~312k
  function formals), so anchoring on sinks keeps the recursive fix-
  point tractable.
- **Path-style FP filter.** An interpolation `${expr}` whose enclosing
  string immediately follows it with a `/…` fragment is excluded
  from `Sink`. This is the dominant idiom in nixpkgs (`${pkg}/bin/foo`)
  and the dominant FP class — cut ShellInjection findings from 4 470
  → 815 with no observed TP regressions.
- **Trusted-formal allow-list.** Recognised package-shaped formals
  (`stdenv`, `lib`, `runtimeShell`, the fetchers, build tools, etc.)
  are not sources. The list is heuristic and explicitly tuned for
  nixpkgs; it'll need extension before this library is useful for
  out-of-tree Nix codebases.
- **`builtins.toString` is NOT a sanitiser.** It is the identity on
  strings — only safe for path/int inputs, which we can't statically
  detect at the Sink. Documented inline.

## What's blocked / Phase 3 candidates

- **Cross-file flow.** NixOS module options → `systemd.services.<x>.serviceConfig.ExecStart`
  is the obvious next escalation. Needs a content-aware data-flow
  shim (Phase 3+).
- **Attrset destructuring through caller-supplied values.** The
  `mkDerivation` callsite typically passes a single attrset; bindings
  to function formals via destructuring (`{ version, ... }:`) is
  already covered, but `f { version = …; }` to caller-defined `f`
  isn't.
- **Higher-order functions** (`map (x: ${x}) [src]`). The `flowStep`
  vocabulary doesn't yet model lambda application.
- **GHCR pack publishing.** Deferred — requires a `write:packages`
  token that's not in scope for this release.

## Files touched

```
ql/lib/codeql/nix/Scope.qll             (+ cached annotations, isCallbackArgName)
ql/lib/codeql/nix/Taint.qll             (new; ~280 LoC)
ql/src/Security/CWE-077/ShellInjectionInBuildPhase.{ql,qhelp}  (new)
ql/src/Security/CWE-077/MissingShellEscape.{ql,qhelp}          (new)
ql/test/queries/Security/CWE-077/*                              (new fixtures)
ql/src/Security/CWE-563/UnusedBinding.qhelp                    (callback-arg note)
ql/test/queries/Security/CWE-563/UnusedBinding/fixture.nix     (3 new cases)
CHANGELOG.md                                                    (0.2.0 entry)
docs/findings/phase2-full-nixpkgs.sarif                        (new; archived sweep)
docs/phase2-report.md                                          (this file)
```
