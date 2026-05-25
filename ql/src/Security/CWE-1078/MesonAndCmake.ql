/**
 * @name Meson and CMake both declared as native build inputs
 * @description A derivation that declares both `meson` and `cmake` in `nativeBuildInputs` uses two
 *              configure-phase build systems where one would do. nixpkgs convention is to pick one;
 *              the other is dead weight in the closure. Port of nixpkgs-hammering's `meson-cmake` rule.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id nix/meson-and-cmake
 * @tags quality
 *       maintainability
 */

import codeql.nix.Nix
import codeql.nix.Derivation

private predicate listContainsNamedVariable(ListExpression list, string name) {
  exists(VariableExpression v |
    v = list.getElement(_) and
    v.getName().getValue() = name
  )
}

from Binding nativeBuildInputsBinding, ListExpression nativeBuildInputs
where
  nativeBuildInputs = nativeBuildInputsBinding.getExpression().(ListExpression) and
  nativeBuildInputsBinding.getAttrpath().getAttr(0).(Identifier).getValue() = "nativeBuildInputs" and
  not exists(nativeBuildInputsBinding.getAttrpath().getAttr(1)) and
  exists(DerivationCall drv | nativeBuildInputsBinding = drv.getADirectBinding()) and
  listContainsNamedVariable(nativeBuildInputs, "meson") and
  listContainsNamedVariable(nativeBuildInputs, "cmake")
select nativeBuildInputs,
  "This derivation declares both `meson` and `cmake` in `nativeBuildInputs`. Prefer one; the other is unused."
