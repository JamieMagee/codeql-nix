/**
 * @name Fetcher invoked without an integrity hash
 * @description A `fetchTarball`/`fetchurl`/`fetchgit`/`fetchFrom*` call
 *              without a `sha256`, `narHash`, or `hash` attribute (or
 *              called with a bare URL string) downloads content whose
 *              authenticity cannot be verified. An attacker who controls
 *              the upstream URL — or any network position in between —
 *              can substitute malicious code that will be evaluated by
 *              every Nix evaluation.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision high
 * @id nix/fetch-without-integrity
 * @tags security
 *       external/cwe/cwe-829
 *       external/cwe/cwe-494
 *       supply-chain
 */

import codeql.nix.Nix
import codeql.nix.Fetchers

from FetcherCall call, AstNode arg, string reason
where
  isBareStringFetch(call, arg) and
  reason = "bare-string argument has no content hash"
  or
  isUnpinnedAttrsetFetch(call, arg) and
  reason = "no `sha256`, `narHash`, or `hash` attribute is set"
select call,
  "Call to `" + call.getName() + "` is not content-pinned: " + reason + "."
