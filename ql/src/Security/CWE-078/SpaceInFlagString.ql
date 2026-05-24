/**
 * @name Whitespace inside a flag-list string literal
 * @description A literal string inside `cmakeFlags`/`mesonFlags`/`configureFlags`/`makeFlags`
 *              (and similar argv-style attributes) that contains embedded whitespace is
 *              word-split by nixpkgs' build wrapper into
 *              multiple argv entries, silently changing the invoked command line.
 * @kind problem
 * @problem.severity error
 * @security-severity 4.0
 * @precision very-high
 * @id nix/space-in-flag-string
 * @tags correctness
 *       external/cwe/cwe-078
 *       maintainability
 */

import codeql.nix.Nix
import codeql.nix.Strings

from StringExpression s, string attrName, string content
where
  isListElementOfBinding(s, attrName) and
  isFlagListAttributeName(attrName) and
  content = getStringLiteralValue(s) and
  content.regexpMatch(".*\\S\\s+\\S.*")
select s,
  "String literal `" + content + "` inside `" + attrName +
    "` contains embedded whitespace; the build wrapper word-splits this into multiple argv entries."
