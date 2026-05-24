/**
 * @name Missing shell-escape on derivation interpolation
 * @description A `${expr}` interpolation inside one of `mkDerivation`'s
 *              shell-context attributes is not passed through
 *              `lib.escapeShellArg` (or an equivalent sanitizer).
 *              Defensive escaping is recommended for any value that
 *              wasn't explicitly proven safe.
 * @kind problem
 * @problem.severity warning
 * @security-severity 6.5
 * @precision low
 * @id nix/missing-shell-escape
 * @tags security
 *       external/cwe/cwe-077
 *       external/cwe/cwe-078
 *       maintainability
 */

import codeql.nix.Nix
import codeql.nix.Taint

from Sink sink
where not isReachableFromSanitizer(sink)
select sink,
  "Interpolation in a shell-context attribute is not passed through `lib.escapeShellArg`."
