/**
 * @name `rec { ... }` merged with `//`
 * @description Merging a recursive attrset with `//` is misleading because
 *              references inside the `rec` block resolve only within that
 *              block, not against the merged result.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id nix/rec-attrset-merge
 * @tags correctness
 *       external/cwe/cwe-665
 *       maintainability
 */

import codeql.nix.Nix

private predicate parenthesizedOperandStep(AstNode outer, AstNode inner) {
  exists(NIX::ParenthesizedExpression paren | outer = paren and inner = paren.getExpression())
}

private predicate stripParentheses(AstNode outer, AstNode inner) {
  outer = inner or parenthesizedOperandStep+(outer, inner)
}

from BinaryExpression update, RecAttrsetExpression rec_, string side
where
  update.getOperator() = "//" and
  (
    stripParentheses(update.getLeft(), rec_) and side = "left-hand"
    or
    stripParentheses(update.getRight(), rec_) and side = "right-hand"
  )
select update,
  "Merging a `rec { ... }` attrset (on the " + side +
    " side) with `//` creates surprising semantics: recursive references in the `rec` block do NOT see attributes from the other operand."
