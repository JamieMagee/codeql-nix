/**
 * String-content helpers for queries that inspect string literals.
 */

import codeql.nix.Nix

/**
 * Holds if `e` is a list element of a `Binding` whose attrpath ends
 * in the identifier `attrName`.
 *
 * For example, given `cmakeFlags = [ "-DFOO=bar" "-DBAZ=qux" ]`, this
 * predicate holds with each of the two list-element strings and
 * `attrName = "cmakeFlags"`.
 *
 * Also matches dotted paths whose last leaf is `attrName`, e.g.
 * `env.cmakeFlags = [ … ]`.
 *
 * Does NOT match attrpaths whose last leaf is a dynamic name
 * (`${expr}` or quoted string).
 */
predicate isListElementOfBinding(AstNode e, string attrName) {
  exists(ListExpression list, Binding b, Attrpath ap, int last |
    e = list.getElement(_) and
    b.getExpression() = list and
    ap = b.getAttrpath() and
    attrName = ap.getAttr(last).(Identifier).getValue() and
    not exists(ap.getAttr(last + 1))
  )
}

/**
 * Names of nixpkgs `mkDerivation` attributes that take a list of
 * shell-argv strings. A string literal with embedded whitespace
 * inside any of these gets word-split by the build wrapper and is
 * almost always a bug.
 *
 * Source: nixpkgs `pkgs/stdenv/generic/setup.sh` plus `nixpkgs-hammering`
 * lints `no-flags-spaces` and `no-flags-array`.
 */
predicate isFlagListAttributeName(string name) {
  name =
    [
      "cmakeFlags", "cmakeBuildFlags", "cmakeInstallFlags", "mesonFlags", "mesonBuildFlags",
      "mesonInstallFlags", "configureFlags", "configureFlagsArray", "makeFlags", "makeFlagsArray",
      "buildFlags", "buildFlagsArray", "installFlags", "installFlagsArray", "checkFlags",
      "checkFlagsArray", "distFlags", "distFlagsArray", "ninjaFlags", "ninjaFlagsArray",
      "qmakeFlags", "preferLocalBuild"
    ]
}
