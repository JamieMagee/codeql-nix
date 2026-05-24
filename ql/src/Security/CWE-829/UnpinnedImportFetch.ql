/**
 * @name `import` of unpinned fetcher result
 * @description Importing the result of an unpinned fetcher call downloads and
 *              evaluates mutable network-controlled Nix code. An attacker who
 *              can tamper with the fetched content can execute arbitrary Nix
 *              code during evaluation.
 * @kind problem
 * @problem.severity error
 * @security-severity 9.0
 * @precision high
 * @id nix/unpinned-import-fetch
 * @tags security
 *       external/cwe/cwe-829
 *       external/cwe/cwe-094
 *       supply-chain
 */

import codeql.nix.Nix
import codeql.nix.Fetchers

predicate isImportCall(ApplyExpression call) {
  call.getFunction().(VariableExpression).getName().getValue() = "import"
}

/** Strips parenthesised expressions: `(expr)` is treated as just `expr`. */
Expr unparenthesize(AstNode e) {
  result = e.(Expr) and not e instanceof ParenthesizedExpression
  or
  result = unparenthesize(e.(ParenthesizedExpression).getExpression())
}

from ApplyExpression imp, FetcherCall fetch, string reason
where
  isImportCall(imp) and
  fetch = unparenthesize(imp.getArgument()) and
  (
    isBareStringFetch(fetch, _) and
    reason = "bare-string fetcher argument has no content hash"
    or
    isUnpinnedAttrsetFetch(fetch, _) and
    reason = "fetcher attrset has no `sha256`, `narHash`, or `hash` attribute"
  )
select imp,
  "`import` of unpinned `" + fetch.getName() + "`: " + reason +
    ". Network-controlled code is evaluated at import time."
