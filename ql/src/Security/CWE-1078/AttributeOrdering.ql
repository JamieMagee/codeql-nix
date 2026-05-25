/**
 * @name Derivation attributes out of canonical order
 * @description Many nixpkgs maintainers prefer a consistent top-level attribute order in
 *              derivations so package updates and reviews are easier. This query ports
 *              nixpkgs-hammering's `attribute-ordering` rule.
 * @kind problem
 * @problem.severity recommendation
 * @precision high
 * @id nix/attribute-ordering
 * @tags quality
 *       maintainability
 */

import codeql.nix.Derivation

/**
 * Holds if `name` has canonical derivation-attribute order rank `ord`.
 *
 * Copied verbatim from nixpkgs-hammering's
 * `lib/derivation-attributes.nix`:
 * https://github.com/jtojnar/nixpkgs-hammering/blob/main/lib/derivation-attributes.nix
 */
predicate canonicalOrderRank(string name, int ord) {
  name = "name" and ord = 0
  or
  name = "pname" and ord = 1
  or
  name = "version" and ord = 2
  or
  name = "outputs" and ord = 3
  or
  name = "src" and ord = 4
  or
  name = "srcs" and ord = 5
  or
  name = "patches" and ord = 6
  or
  name = "nativeBuildInputs" and ord = 7
  or
  name = "buildInputs" and ord = 8
  or
  name = "propagatedNativeBuildInputs" and ord = 9
  or
  name = "propagatedBuildInputs" and ord = 10
  or
  name = "nativeCheckInputs" and ord = 11
  or
  name = "checkInputs" and ord = 12
  or
  name = "installCheckInputs" and ord = 13
  or
  name = "cmakeFlags" and ord = 14
  or
  name = "mesonFlags" and ord = 15
  or
  name = "configureFlags" and ord = 16
  or
  name = "qmakeFlags" and ord = 17
  or
  name = "makeFlags" and ord = 18
  or
  name = "ninjaFlags" and ord = 19
  or
  name = "buildFlags" and ord = 20
  or
  name = "yarnBuildFlags" and ord = 21
  or
  name = "checkTarget" and ord = 22
  or
  name = "checkFlags" and ord = 23
  or
  name = "installFlags" and ord = 24
  or
  name = "installCheckFlags" and ord = 25
  or
  name = "enableParallelBuilding" and ord = 26
  or
  name = "enableParallelChecking" and ord = 27
  or
  name = "env" and ord = 28
  or
  name = "doCheck" and ord = 29
  or
  name = "doInstallCheck" and ord = 30
  or
  name = "doDist" and ord = 31
  or
  name = "dontUnpack" and ord = 32
  or
  name = "dontPatch" and ord = 33
  or
  name = "dontConfigure" and ord = 34
  or
  name = "dontBuild" and ord = 35
  or
  name = "dontUseNinjaBuild" and ord = 36
  or
  name = "dontInstall" and ord = 37
  or
  name = "dontUseNinjaInstall" and ord = 38
  or
  name = "dontFixup" and ord = 39
  or
  name = "dontUseNinjaCheck" and ord = 40
  or
  name = "dontNpmInstall" and ord = 41
  or
  name = "preUnpack" and ord = 42
  or
  name = "unpackPhase" and ord = 43
  or
  name = "postUnpack" and ord = 44
  or
  name = "prePatch" and ord = 45
  or
  name = "patchPhase" and ord = 46
  or
  name = "postPatch" and ord = 47
  or
  name = "preConfigure" and ord = 48
  or
  name = "configurePhase" and ord = 49
  or
  name = "postConfigure" and ord = 50
  or
  name = "preBuild" and ord = 51
  or
  name = "buildPhase" and ord = 52
  or
  name = "postBuild" and ord = 53
  or
  name = "preCheck" and ord = 54
  or
  name = "checkPhase" and ord = 55
  or
  name = "postCheck" and ord = 56
  or
  name = "preInstall" and ord = 57
  or
  name = "installPhase" and ord = 58
  or
  name = "postInstall" and ord = 59
  or
  name = "preFixup" and ord = 60
  or
  name = "fixupOutput" and ord = 61
  or
  name = "fixupPhase" and ord = 62
  or
  name = "postFixup" and ord = 63
  or
  name = "preInstallCheck" and ord = 64
  or
  name = "installCheckPhase" and ord = 65
  or
  name = "postInstallCheck" and ord = 66
  or
  name = "distPhase" and ord = 67
  or
  name = "passthru" and ord = 68
  or
  name = "meta" and ord = 69
}

private predicate knownNthAttr(DerivationCall drv, int i, string name, int ord) {
  name = drv.getNthAttrName(i) and
  canonicalOrderRank(name, ord)
}

/**
 * Holds if `name` is immediately followed by `followName` among known direct
 * derivation attributes, but `followName` should canonically come earlier.
 */
private predicate shouldFollow(
  DerivationCall drv,
  string name, int ord,
  string followName, int followOrd
) {
  exists(int i, int j |
    knownNthAttr(drv, i, name, ord) and
    knownNthAttr(drv, j, followName, followOrd) and
    i < j and
    ord > followOrd and
    not exists(int k, string skippedName, int skippedOrd |
      knownNthAttr(drv, k, skippedName, skippedOrd) and
      i < k and
      k < j
    )
  )
}

from DerivationCall drv, Binding binding, string name, int ord,
  Binding followBinding, string followName, int followOrd
where
  shouldFollow(drv, name, ord, followName, followOrd) and
  binding = drv.getDirectBinding(name) and
  followBinding = drv.getDirectBinding(followName)
select binding,
  "Attribute `" + name + "` is out of canonical nixpkgs order; it should follow $@.",
  followBinding, followName
