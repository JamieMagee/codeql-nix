/**
 * @name Protected phase overridden directly
 * @description A derivation overrides `patchPhase` or `fixupPhase` directly. That replaces
 *              stdenv's default phase logic, which is where patch application and post-install
 *              fixups such as stripping and RPATH repair normally happen. Port of
 *              nixpkgs-hammering's `fixup-phase` and `patch-phase` rules.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id nix/protected-phase-override
 * @tags quality
 *       maintainability
 */

import codeql.nix.Nix
import codeql.nix.Derivation

private predicate isProtectedPhaseAttr(Identifier phaseAttr, string hookStem) {
  phaseAttr.getValue() = "fixupPhase" and hookStem = "Fixup"
  or
  phaseAttr.getValue() = "patchPhase" and hookStem = "Patch"
}

from Binding phaseBinding, Identifier phaseAttr, string hookStem
where
  exists(DerivationCall drv | phaseBinding = drv.getADirectBinding()) and
  phaseAttr = phaseBinding.getAttrpath().getAttr(0).(Identifier) and
  isProtectedPhaseAttr(phaseAttr, hookStem)
select phaseAttr,
  "This derivation overrides `" + phaseAttr.getValue() + "` directly. Keep stdenv's default `" +
    phaseAttr.getValue() + "` and add custom commands in `pre" + hookStem + "` or `post" + hookStem +
    "` instead."
