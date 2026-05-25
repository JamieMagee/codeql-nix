/**
 * @name Duplicate packages in propagated build and check inputs
 * @description A derivation that lists the same package in `propagatedBuildInputs` and in
 *              `checkInputs` or `nativeCheckInputs` is redundant. Everything from
 *              `propagatedBuildInputs` is already available during the check phase. Port of
 *              nixpkgs-hammering's `duplicate-check-inputs` rule.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id nix/duplicate-check-inputs
 * @tags quality
 *       maintainability
 */

import codeql.nix.Nix
import codeql.nix.Derivation

private predicate isCheckInputAttribute(string attrName) {
  attrName = "checkInputs" or attrName = "nativeCheckInputs"
}

cached
private ListExpression getDirectListBinding(DerivationCall drv, string attrName) {
  result = drv.getDirectBinding(attrName).getExpression().(ListExpression)
}

cached
private predicate propagatedBuildInputName(DerivationCall drv, string name) {
  exists(VariableExpression propagatedInput |
    propagatedInput =
      getDirectListBinding(drv, "propagatedBuildInputs").getElement(_).(VariableExpression) and
    name = propagatedInput.getName().getValue()
  )
}

from DerivationCall drv, string attrName, VariableExpression checkInput
where
  isCheckInputAttribute(attrName) and
  checkInput = getDirectListBinding(drv, attrName).getElement(_).(VariableExpression) and
  propagatedBuildInputName(drv, checkInput.getName().getValue())
select checkInput,
  "`" + checkInput.getName().getValue() +
    "` is already listed in `propagatedBuildInputs` and need not be repeated in `" + attrName + "`."
