/**
 * @name Build tools declared in buildInputs
 * @description A derivation that declares build-only tooling in `buildInputs`
 *              makes the tool target the package's host platform instead of the
 *              build platform. Port of nixpkgs-hammering's
 *              `build-tools-in-build-inputs` rule.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id nix/build-tools-in-build-inputs
 * @tags quality
 *       maintainability
 */

import codeql.nix.Nix
import codeql.nix.Derivation

/** Holds if `name` is a build tool package name used by this port. */
predicate isBuildTool(string name) {
  name =
    [
      "autoconf",
      "automake",
      "autoreconf",
      "autoreconfHook",
      "autoPatchelfHook",
      "cmake",
      "copyDesktopItems",
      "intltool",
      "libtool",
      "makeBinaryWrapper",
      "makeWrapper",
      "meson",
      "ninja",
      "pkg-config",
      "pkgconf",
      "pkgconfig",
      "qmake",
      "qt5.qmake",
      "qt6.qmake",
      "wrapGAppsHook",
      "wrapQtAppsHook"
    ]
}

from DerivationCall d, ListExpression buildInputs, AstNode toolExpr, string name
where
  buildInputs = d.getDirectBinding("buildInputs").getExpression().(ListExpression) and
  (
    exists(VariableExpression v |
      toolExpr = v and
      v = buildInputs.getElement(_) and
      name = v.getName().getValue() and
      isBuildTool(name)
    )
    or
    exists(SelectExpression sel, Attrpath ap, VariableExpression base |
      toolExpr = sel and
      sel = buildInputs.getElement(_) and
      ap = sel.getAttrpath() and
      base = sel.getExpression() and
      not exists(ap.getAttr(1)) and
      (
        base.getName().getValue() = "qt5" and
        ap.getAttr(0).(Identifier).getValue() = "qmake" and
        name = "qt5.qmake"
        or
        base.getName().getValue() = "qt6" and
        ap.getAttr(0).(Identifier).getValue() = "qmake" and
        name = "qt6.qmake"
      )
    )
  )
select toolExpr,
  "This derivation declares the build tool `" + name +
    "` in `buildInputs`. Move it to `nativeBuildInputs` instead."
