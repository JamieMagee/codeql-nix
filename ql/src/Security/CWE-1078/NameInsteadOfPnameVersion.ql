/**
 * @name `name` set alongside `version` without `pname`
 * @description nixpkgs convention is to set `pname` and `version`; `name` is derived as `"${pname}-${version}"`.
 *              Setting `name` explicitly alongside `version` (but no `pname`) bypasses the convention and
 *              breaks tooling that expects `pname`. Port of nixpkgs-hammering's `name-and-version` rule.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id nix/name-instead-of-pname-version
 * @tags quality
 *       maintainability
 */

import codeql.nix.Derivation

from DerivationCall d
where
  d.hasAttr("name") and
  d.hasAttr("version") and
  not d.hasAttr("pname")
select d,
  "Derivation sets `name` and `version` without `pname`; prefer `pname` + `version` and let `name` be derived automatically."
