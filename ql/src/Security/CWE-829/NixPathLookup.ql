/**
 * @name <...>-style search-path lookup
 * @description A `<...>`-style search-path lookup such as `<nixpkgs>`
 *              resolves via the ambient `$NIX_PATH`/`builtins.nixPath`
 *              search path. That search path differs across machines and
 *              over time, making evaluation non-reproducible and allowing
 *              unexpected code to be imported.
 * @kind problem
 * @problem.severity warning
 * @security-severity 5.0
 * @precision very-high
 * @id nix/nix-path-lookup
 * @tags security
 *       external/cwe/cwe-829
 *       supply-chain
 *       reproducibility
 */

import codeql.nix.Nix

from LookupPath p
select p,
  "<...>-style lookup path '" + p.getValue() +
    "' depends on the ambient $NIX_PATH and is not reproducible."
