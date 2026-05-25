/**
 * @name Unnecessary enableParallelBuilding
 * @description Meson, CMake, and qmake already enable parallel building through their
 *              configure hooks. Explicit `enableParallelBuilding = true;` is redundant
 *              unless the default configure phase is overridden or the relevant hook is
 *              disabled. Port of nixpkgs-hammering's `unnecessary-parallel-building` rule.
 * @kind problem
 * @problem.severity recommendation
 * @precision high
 * @id nix/unnecessary-parallel-building
 * @tags quality
 *       maintainability
 */

import codeql.nix.Nix
import codeql.nix.Derivation

private predicate isLiteralTrue(Expr e) { e.(VariableExpression).getName().getValue() = "true" }

private predicate isEnableParallelBuildingBinding(Binding binding) {
  not exists(binding.getAttrpath().getAttr(1)) and
  binding.getAttrpath().getAttr(0).(Identifier).getValue() = "enableParallelBuilding"
}

private predicate isNativeBuildInputsBinding(Binding binding) {
  not exists(binding.getAttrpath().getAttr(1)) and
  binding.getAttrpath().getAttr(0).(Identifier).getValue() = "nativeBuildInputs"
}

private predicate isConfigurePhaseBinding(Binding binding) {
  not exists(binding.getAttrpath().getAttr(1)) and
  binding.getAttrpath().getAttr(0).(Identifier).getValue() = "configurePhase"
}

private predicate isDontUseMesonConfigureBinding(Binding binding) {
  not exists(binding.getAttrpath().getAttr(1)) and
  binding.getAttrpath().getAttr(0).(Identifier).getValue() = "dontUseMesonConfigure"
}

private predicate isDontUseCmakeConfigureBinding(Binding binding) {
  not exists(binding.getAttrpath().getAttr(1)) and
  binding.getAttrpath().getAttr(0).(Identifier).getValue() = "dontUseCmakeConfigure"
}

private predicate isDontUseQmakeConfigureBinding(Binding binding) {
  not exists(binding.getAttrpath().getAttr(1)) and
  binding.getAttrpath().getAttr(0).(Identifier).getValue() = "dontUseQmakeConfigure"
}

private predicate listContainsMeson(ListExpression list) {
  exists(VariableExpression v |
    v = list.getElement(_) and
    v.getName().getValue() = "meson"
  )
}

private predicate listContainsCmake(ListExpression list) {
  exists(VariableExpression v |
    v = list.getElement(_) and
    v.getName().getValue() = "cmake"
  )
}

private predicate listContainsQmake(ListExpression list) {
  exists(SelectExpression sel, Attrpath ap, int last |
    sel = list.getElement(_) and
    ap = sel.getAttrpath() and
    ap.getAttr(last).(Identifier).getValue() = "qmake" and
    not exists(ap.getAttr(last + 1))
  )
}

private predicate dontUseMesonConfigureIsTrue(DerivationCall drv) {
  exists(Binding b |
    b = drv.getADirectBinding() and
    isDontUseMesonConfigureBinding(b) and
    isLiteralTrue(b.getExpression())
  )
}

private predicate dontUseCmakeConfigureIsTrue(DerivationCall drv) {
  exists(Binding b |
    b = drv.getADirectBinding() and
    isDontUseCmakeConfigureBinding(b) and
    isLiteralTrue(b.getExpression())
  )
}

private predicate dontUseQmakeConfigureIsTrue(DerivationCall drv) {
  exists(Binding b |
    b = drv.getADirectBinding() and
    isDontUseQmakeConfigureBinding(b) and
    isLiteralTrue(b.getExpression())
  )
}

from Binding enableParallelBuildingBinding, ListExpression nativeBuildInputs, string hookSummary
where
  isEnableParallelBuildingBinding(enableParallelBuildingBinding) and
  isLiteralTrue(enableParallelBuildingBinding.getExpression()) and
  exists(DerivationCall drv, Binding nativeBuildInputsBinding |
    enableParallelBuildingBinding = drv.getADirectBinding() and
    nativeBuildInputsBinding = drv.getADirectBinding() and
    isNativeBuildInputsBinding(nativeBuildInputsBinding) and
    nativeBuildInputs = nativeBuildInputsBinding.getExpression().(ListExpression) and
    not exists(Binding configurePhaseBinding |
      configurePhaseBinding = drv.getADirectBinding() and
      isConfigurePhaseBinding(configurePhaseBinding)
    ) and
    (
      listContainsMeson(nativeBuildInputs) and
      not dontUseMesonConfigureIsTrue(drv) and
      hookSummary = "The Meson configure hook"
      or
      listContainsCmake(nativeBuildInputs) and
      not dontUseCmakeConfigureIsTrue(drv) and
      hookSummary = "The CMake configure hook"
      or
      listContainsQmake(nativeBuildInputs) and
      not dontUseQmakeConfigureIsTrue(drv) and
      hookSummary = "The qmake configure hook"
    )
  )
select enableParallelBuildingBinding,
  hookSummary +
    " already sets `enableParallelBuilding = true` by default, so this binding is redundant."
