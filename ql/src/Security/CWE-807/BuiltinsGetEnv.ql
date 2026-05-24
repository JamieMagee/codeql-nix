/**
 * @name Use of `builtins.getEnv`
 * @description `builtins.getEnv` reads the host environment during evaluation. That is impure,
 *              behaves differently under `--pure-eval`, and can leak host state into derivation
 *              hashes and outputs.
 * @kind problem
 * @problem.severity warning
 * @security-severity 3.5
 * @precision high
 * @id nix/builtins-get-env
 * @tags reliability
 *       external/cwe/cwe-807
 *       impurity
 */

import codeql.nix.Nix
import codeql.nix.Builtins

private string getEnvVarName(BuiltinCall call) {
  result = getStringLiteralValue(call.getArgument().(StringExpression))
  or
  not exists(getStringLiteralValue(call.getArgument().(StringExpression))) and
  result = "?"
}

from BuiltinCall call, string envVar
where call.getName() = "getEnv" and envVar = getEnvVarName(call)
select call,
  "Call to `builtins.getEnv` reads the host environment and is impure; results depend on environment variable `"
    + envVar + "`."
