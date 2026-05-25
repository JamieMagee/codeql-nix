{ stdenv, lib, ... }:

let
  callPackage = path: args: { inherit path args; };

  # BAD: direct dotted meta.license binding.
  badDirect = stdenv.mkDerivation {
    pname = "bad-direct";
    version = "1.0";
    meta.license = lib.licenses.gpl2;
  };

  # BAD: nested meta attrset binding.
  badNestedMeta = stdenv.mkDerivation {
    pname = "bad-nested-meta";
    version = "1.0";
    meta = {
      license = lib.licenses.gpl3;
    };
  };

  # BAD: with-scope list uses a deprecated alias.
  badWithList = stdenv.mkDerivation {
    pname = "bad-with-list";
    version = "1.0";
    meta.license = with lib.licenses; [ gpl2 mit ];
  };

  # GOOD: explicit exact-version alias.
  goodOnly = stdenv.mkDerivation {
    pname = "good-only";
    version = "1.0";
    meta.license = lib.licenses.gpl2Only;
  };

  # GOOD: unrelated non-GPL license.
  goodMit = stdenv.mkDerivation {
    pname = "good-mit";
    version = "1.0";
    meta.license = lib.licenses.mit;
  };

  # EDGE: not a derivation wrapper, so it must not match.
  edgeCallPackage = callPackage ./dummy.nix {
    meta.license = lib.licenses.gpl2;
  };
in
{
  inherit
    badDirect
    badNestedMeta
    badWithList
    goodOnly
    goodMit
    edgeCallPackage;
}
