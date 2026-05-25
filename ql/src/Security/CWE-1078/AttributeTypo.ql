/**
 * @name Likely typo in derivation attribute
 * @description Flags likely typos in top-level derivation attributes when they differ from a known
 *              `stdenv.mkDerivation` or Python-wrapper attribute only by casing or a curated
 *              handwritten typo allow-list.
 * @kind problem
 * @problem.severity recommendation
 * @precision high
 * @id nix/attribute-typo
 * @tags quality
 *       maintainability
 */

import codeql.nix.Nix
import codeql.nix.Derivation

private predicate knownAttr(string name) {
  name =
    [
      "name", "pname", "version", "outputs", "src", "srcs", "patches", "nativeBuildInputs",
      "buildInputs", "propagatedNativeBuildInputs", "propagatedBuildInputs", "nativeCheckInputs",
      "checkInputs", "installCheckInputs", "cmakeFlags", "mesonFlags", "configureFlags",
      "qmakeFlags", "makeFlags", "ninjaFlags", "buildFlags", "yarnBuildFlags", "checkTarget",
      "checkFlags", "installFlags", "installCheckFlags", "enableParallelBuilding",
      "enableParallelChecking", "env", "doCheck", "doInstallCheck", "doDist", "dontUnpack",
      "dontPatch", "dontConfigure", "dontBuild", "dontUseNinjaBuild", "dontInstall",
      "dontUseNinjaInstall", "dontFixup", "dontUseNinjaCheck", "dontNpmInstall", "preUnpack",
      "unpackPhase", "postUnpack", "prePatch", "patchPhase", "postPatch", "preConfigure",
      "configurePhase", "postConfigure", "preBuild", "buildPhase", "postBuild", "preCheck",
      "checkPhase", "postCheck", "preInstall", "installPhase", "postInstall", "preFixup",
      "fixupOutput", "fixupPhase", "postFixup", "preInstallCheck", "installCheckPhase",
      "postInstallCheck", "distPhase", "passthru", "meta", "strictDeps", "phases", "sourceRoot",
      "patchFlags", "configureScript", "configureFlagsArray", "makeFlagsArray", "installTargets",
      "dontStrip", "dontPatchELF", "dontPatchShebangs", "setupHook", "allowedReferences",
      "allowedRequisites", "disallowedReferences", "disallowedRequisites", "outputHash",
      "outputHashAlgo", "outputHashMode", "passAsFile", "preferLocalBuild", "allowSubstitutes",
      "hardeningDisable", "hardeningEnable", "format", "pyproject", "dependencies",
      "optional-dependencies", "build-system", "disabled", "pythonPath", "pythonImportsCheck",
      "pythonRelaxDeps", "pythonRemoveDeps", "disabledTests", "disabledTestPaths",
      "disabledTestMarks", "enabledTests", "enabledTestPaths", "enabledTestMarks", "pytestFlags",
      "nativeInstallCheckInputs"
    ]
}

private predicate typoOf(string canonical, string typo) {
  canonical = "configureFlags" and typo = ["configFlags", "confgureFlags"]
  or
  canonical = "buildPhase" and typo = ["buidPhase", "bulidPhase"]
  or
  canonical = "installPhase" and typo = ["instalPhase", "intallPhase"]
  or
  canonical = "maintainers" and typo = ["mainainers", "maintianers"]
  or
  canonical = "description" and typo = ["decription", "descritpion", "desciption"]
  or
  canonical = "homepage" and typo = ["homePage", "hompage"]
  or
  canonical = "license" and typo = ["licens", "liscense", "licence"]
  or
  canonical = "python" and typo = "pyhton"
  or
  canonical = "postPatch" and typo = "postPach"
  or
  canonical = "prePatch" and typo = "prePach"
  or
  canonical = "doCheck" and typo = "doChek"
  or
  canonical = "doInstallCheck" and typo = "doInstallChek"
  or
  canonical = "buildInputs" and typo = "buildInput"
  or
  canonical = "nativeBuildInputs" and typo = "nativeBuildInput"
  or
  canonical = "propagatedBuildInputs" and typo = "propogatedBuildInputs"
  or
  canonical = "nativeCheckInputs" and typo = "nativeCheckInput"
  or
  canonical = "pythonImportsCheck" and typo = ["pythonImportCheck", "pythonImportsChek"]
  or
  canonical = "dependencies" and typo = "dependenices"
  or
  canonical = "optional-dependencies" and typo = "optionalDependencies"
  or
  canonical = "build-system" and typo = "buildSystem"
  or
  canonical = "disabledTests" and typo = "disabledTest"
  or
  canonical = "disabledTestPaths" and typo = "disabledTestPath"
  or
  canonical = "enabledTests" and typo = "enabledTest"
  or
  canonical = "enabledTestPaths" and typo = "enabledTestPath"
  or
  canonical = "pytestFlags" and typo = "pytestFlag"
  or
  canonical = "version" and typo = "verison"
}

cached
private predicate directBindingName(string name) {
  exists(DerivationCall d | exists(d.getDirectBinding(name)))
}

cached
private predicate suggestedName(string name, string canonical) {
  directBindingName(name) and
  not knownAttr(name) and
  not name.regexpMatch("^_.*") and
  not name.regexpMatch(".*\\..*") and
  (
    knownAttr(canonical) and
    name != canonical and
    name.toLowerCase() = canonical.toLowerCase()
    or
    typoOf(canonical, name)
  )
}

from DerivationCall d, Binding b, Identifier attr, string name, string canonical
where
  suggestedName(name, canonical) and
  b = d.getDirectBinding(name) and
  attr = b.getAttrpath().getAttr(0).(Identifier)
select attr, "Unknown derivation attribute `" + name + "`; did you mean `" + canonical + "`?"
