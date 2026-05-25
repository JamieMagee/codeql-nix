/**
 * @name Phase explicitly overridden
 * @description Overriding a derivation phase (`configurePhase`, `buildPhase`, `checkPhase`, `installPhase`)
 *              bypasses the stdenv defaults. Use the `preX` / `postX` hooks instead unless the default phase
 *              is unsuitable. Port of nixpkgs-hammering's `explicit-phases` rule.
 * @kind problem
 * @problem.severity recommendation
 * @precision high
 * @id nix/explicit-phases
 * @tags quality
 *       maintainability
 */

import codeql.nix.Derivation

private predicate isExplicitPhase(string phase, string hookStem) {
  phase = "configurePhase" and hookStem = "Configure"
  or
  phase = "buildPhase" and hookStem = "Build"
  or
  phase = "checkPhase" and hookStem = "Check"
  or
  phase = "installPhase" and hookStem = "Install"
}

from DerivationCall drv, Binding binding, string phase, string hookStem
where
  isExplicitPhase(phase, hookStem) and
  binding = drv.getDirectBinding(phase)
select binding,
  "Derivation phase `" + phase + "` is explicitly overridden; prefer `pre" + hookStem + "` / `post" +
    hookStem + "` hooks unless the default phase is unsuitable."
