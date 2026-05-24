/**
 * @name Unused binding
 * @description A name is defined by a `let`-binding, `rec`-attrset
 *              binding, `inherit`, or function parameter, but is never
 *              referenced in its lexical scope. Unused bindings make
 *              code harder to maintain and may indicate a refactoring
 *              error such as a forgotten use site.
 * @kind problem
 * @problem.severity recommendation
 * @precision medium
 * @id nix/unused-binding
 * @tags maintainability
 *       external/cwe/cwe-563
 */

import codeql.nix.Nix
import codeql.nix.Scope

from Scope scope, string name, Identifier defNode, string kind
where
  isUnusedBinding(scope, name, defNode) and
  (
    scope instanceof LetExpression and kind = "let-binding"
    or
    scope instanceof LetAttrsetExpression and kind = "let-attrset binding"
    or
    scope instanceof FunctionExpression and kind = "function parameter"
  )
select defNode, "Unused " + kind + " `" + name + "`."
