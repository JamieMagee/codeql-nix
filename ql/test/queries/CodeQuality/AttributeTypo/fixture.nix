{ stdenv, lib, ... }:

let
  # BAD: case-only mistake.
  badCaseMismatch = stdenv.mkDerivation {
    pName = "bad-case";
    version = "1.0";
  };

  # BAD: handwritten typo allow-list.
  badConfigFlags = stdenv.mkDerivation {
    pname = "bad-config-flags";
    version = "1.0";
    configFlags = [ "--enable-foo" ];
  };

  # BAD: common transposition.
  badBuildPhase = stdenv.mkDerivation {
    pname = "bad-build-phase";
    version = "1.0";
    buidPhase = "echo building";
  };

  # GOOD: canonical spelling.
  goodCanonical = stdenv.mkDerivation {
    pname = "good-canonical";
    version = "1.0";
  };

  # GOOD: underscore-prefixed helpers are exempt.
  goodPrivate = stdenv.mkDerivation {
    pname = "good-private";
    version = "1.0";
    _privateAttr = lib.id "ignored";
  };

  # GOOD: unknown custom attributes are accepted.
  goodCustom = stdenv.mkDerivation {
    pname = "good-custom";
    version = "1.0";
    customAttr = true;
  };

  # EDGE: dotted attrpaths are handled by their first segment.
  edgeDottedMeta = stdenv.mkDerivation {
    pname = "edge-dotted-meta";
    version = "1.0";
    meta.description = "ignored";
  };
in
{
  inherit
    badCaseMismatch
    badConfigFlags
    badBuildPhase
    goodCanonical
    goodPrivate
    goodCustom
    edgeDottedMeta;
}
