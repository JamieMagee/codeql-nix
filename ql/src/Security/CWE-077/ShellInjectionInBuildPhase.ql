/**
 * @name Shell injection in derivation build phase
 * @description An untrusted value (function formal, fetcher result,
 *              `getEnv`, `import`) flows into a shell-context attribute
 *              (`buildPhase`, `installPhase`, etc.) without being
 *              passed through `lib.escapeShellArg`. An attacker who
 *              controls the source value can break out of the
 *              interpolation and execute arbitrary shell commands
 *              during the build.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.0
 * @precision medium
 * @id nix/shell-injection-in-build-phase
 * @tags security
 *       external/cwe/cwe-077
 *       external/cwe/cwe-078
 *       supply-chain
 */

import codeql.nix.Nix
import codeql.nix.Taint

from Source src, Sink sink
where flowsTo(src, sink)
select sink,
  "Untrusted value from $@ flows into a shell-context interpolation without `lib.escapeShellArg` (or equivalent).",
  src, src.toString()
