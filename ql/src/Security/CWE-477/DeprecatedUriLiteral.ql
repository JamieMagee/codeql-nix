/**
 * @name Deprecated bare URI literal
 * @description A bare (unquoted) URI literal such as `https://example.com`
 *              is deprecated by Nix RFC 45 and is scheduled for removal from
 *              the language. Quote the URI as a string literal instead.
 * @kind problem
 * @problem.severity warning
 * @precision very-high
 * @id nix/deprecated-uri-literal
 * @tags maintainability
 *       external/cwe/cwe-477
 *       deprecated
 */

import codeql.nix.Nix

from BareUriLiteral u
select u,
  "Bare URI literal '" + u.getValue() + "' is deprecated by Nix RFC 45; quote it as a string."
