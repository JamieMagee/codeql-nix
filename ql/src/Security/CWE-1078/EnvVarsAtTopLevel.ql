/**
 * @name Environment variables declared at the top level of a derivation
 * @description Certain builder environment variables should be placed under the `env` attribute
 *              instead of being passed directly as top-level derivation attributes. This keeps
 *              environment customization explicit and avoids mixing structured attributes with
 *              environment-variable bindings.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id nix/env-vars-at-top-level
 * @tags quality
 *       maintainability
 */

import codeql.nix.Nix
import codeql.nix.Derivation

cached
private predicate isListedEnvVarBinding(Binding binding, string name) {
  name = "CFLAGS" and exists(DerivationCall drv | binding = drv.getDirectBinding("CFLAGS"))
  or
  name = "CPPFLAGS" and exists(DerivationCall drv | binding = drv.getDirectBinding("CPPFLAGS"))
  or
  name = "CXXFLAGS" and exists(DerivationCall drv | binding = drv.getDirectBinding("CXXFLAGS"))
  or
  name = "FCFLAGS" and exists(DerivationCall drv | binding = drv.getDirectBinding("FCFLAGS"))
  or
  name = "FONTCONFIG_FILE" and
  exists(DerivationCall drv | binding = drv.getDirectBinding("FONTCONFIG_FILE"))
  or
  name = "NIX_CFLAGS_COMPILE" and
  exists(DerivationCall drv | binding = drv.getDirectBinding("NIX_CFLAGS_COMPILE"))
  or
  name = "NIX_CFLAGS_LINK" and
  exists(DerivationCall drv | binding = drv.getDirectBinding("NIX_CFLAGS_LINK"))
  or
  name = "NIX_ENFORCE_NO_NATIVE" and
  exists(DerivationCall drv | binding = drv.getDirectBinding("NIX_ENFORCE_NO_NATIVE"))
  or
  name = "NIX_LDFLAGS" and
  exists(DerivationCall drv | binding = drv.getDirectBinding("NIX_LDFLAGS"))
}

cached
private predicate isPkgConfigEnvVarBinding(Binding binding, string name) {
  exists(DerivationCall drv, string suffix |
    binding = drv.getADirectBinding() and
    name = binding.getAttrpath().getAttr(0).(Identifier).getValue() and
    name = "PKG_CONFIG_" + suffix and
    suffix != ""
  )
}

from Binding binding, string name
where
  isListedEnvVarBinding(binding, name)
  or
  isPkgConfigEnvVarBinding(binding, name)
select binding,
  "Environment variable `" + name +
    "` should be moved under `env` instead of being passed directly to this derivation."
