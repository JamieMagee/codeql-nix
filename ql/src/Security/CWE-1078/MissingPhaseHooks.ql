/**
 * @name Missing pre/post hooks in an overridden phase
 * @description Overriding `configurePhase`, `buildPhase`, `checkPhase`, or
 *              `installPhase` without calling the corresponding `runHook preX`
 *              and `runHook postX` skips nixpkgs setup hooks and
 *              `overrideAttrs`-supplied phase extensions.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id nix/missing-phase-hooks
 * @tags quality
 *       maintainability
 */

import codeql.nix.Nix
import codeql.nix.Derivation

private predicate phaseHooks(string phaseName, string preHook, string postHook) {
  phaseName = "configurePhase" and preHook = "preConfigure" and postHook = "postConfigure"
  or
  phaseName = "buildPhase" and preHook = "preBuild" and postHook = "postBuild"
  or
  phaseName = "checkPhase" and preHook = "preCheck" and postHook = "postCheck"
  or
  phaseName = "installPhase" and preHook = "preInstall" and postHook = "postInstall"
}

from
  DerivationCall d, Binding b, Identifier phaseAttr, string phaseName, string preHook,
  string postHook, Expr rhs, string content, string prePattern, string postPattern, string missing
where
  b = d.getADirectBinding() and
  phaseAttr = b.getAttrpath().getAttr(0).(Identifier) and
  phaseName = phaseAttr.getValue() and
  phaseHooks(phaseName, preHook, postHook) and
  rhs = b.getExpression() and
  (
    exists(StringExpression s |
      rhs = s and
      (
        not hasInterpolation(s) and
        content = getStringLiteralValue(s)
        or
        hasInterpolation(s) and
        content =
          concat(int i, StringFragment frag | s.getChild(i) = frag | frag.getValue() order by i)
      )
    )
    or
    exists(IndentedStringExpression s |
      rhs = s and
      (
        not indentedHasInterpolation(s) and
        content = s.getChild(0).(StringFragment).getValue() and
        not exists(s.getChild(1))
        or
        indentedHasInterpolation(s) and
        content =
          concat(int i, StringFragment frag | s.getChild(i) = frag | frag.getValue() order by i)
      )
    )
  ) and
  prePattern = "(?s).*\\brunHook\\s+" + preHook + "\\b.*" and
  postPattern = "(?s).*\\brunHook\\s+" + postHook + "\\b.*" and
  (
    not content.regexpMatch(prePattern) and
    not content.regexpMatch(postPattern) and
    missing = "`runHook " + preHook + "` and `runHook " + postHook + "`"
    or
    not content.regexpMatch(prePattern) and
    content.regexpMatch(postPattern) and
    missing = "`runHook " + preHook + "`"
    or
    content.regexpMatch(prePattern) and
    not content.regexpMatch(postPattern) and
    missing = "`runHook " + postHook + "`"
  )
select phaseAttr, "`" + phaseName + "` overrides the default phase but is missing " + missing + "."
