/**
 * @name Deprecated legacy `let { … }` attrset syntax
 * @description The legacy `let { body = ...; }` attrset form is deprecated
 *              and supported only for backwards compatibility. Prefer
 *              `let ... in ...` instead.
 * @kind problem
 * @problem.severity warning
 * @precision very-high
 * @id nix/legacy-let-attrset
 * @tags maintainability
 *       external/cwe/cwe-477
 *       deprecated
 */

import codeql.nix.Nix

from LetAttrsetExpression e
select e, "Deprecated `let { ... }` attrset syntax; use `let ... in ...` (modern let-in) instead."
