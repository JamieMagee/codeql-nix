{ stdenv, lib, buildPythonPackage, ... }:

let
  version = "2.0";

  # BAD: sets name + version directly, but no pname.
  badDirect = stdenv.mkDerivation {
    name = "bad-direct";
    version = "1.0";
  };

  # BAD: inherit version still counts as a version attribute.
  badInheritVersion = stdenv.mkDerivation {
    name = lib.concatStringsSep "-" [ "bad" "inherit-version" ];
    inherit version;
  };

  # GOOD: canonical pname + version form.
  goodPnameVersion = stdenv.mkDerivation {
    pname = "good";
    version = "1.0";
  };

  # GOOD: explicit name without version is outside the rule's scope.
  goodNameOnly = stdenv.mkDerivation {
    name = "name-only";
  };

  # GOOD: explicit name is allowed when pname is also present.
  goodNamePnameVersion = stdenv.mkDerivation {
    name = "good-explicit-name";
    pname = "good";
    version = "1.0";
  };

  # BAD: callback-form derivation attrset.
  badCallback = stdenv.mkDerivation (finalAttrs: {
    name = "callback";
    version = "4.0";
  });

  # BAD: recognised wrapper should behave like mkDerivation.
  badBuildPythonPackage = buildPythonPackage {
    name = "py-demo";
    version = "5.0";
    format = "setuptools";
  };
in
{
  inherit
    badDirect
    badInheritVersion
    goodPnameVersion
    goodNameOnly
    goodNamePnameVersion
    badCallback
    badBuildPythonPackage;
}
