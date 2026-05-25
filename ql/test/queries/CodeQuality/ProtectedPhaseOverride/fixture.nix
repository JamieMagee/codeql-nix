{ stdenv, lib, ... }:

let
  # BAD: direct fixupPhase override.
  badFixup = stdenv.mkDerivation {
    pname = "bad-fixup";
    version = "1.0";
    fixupPhase = ''
      echo bad
    '';
  };

  # BAD: direct patchPhase override.
  badPatch = stdenv.mkDerivation {
    pname = "bad-patch";
    version = "1.0";
    patchPhase = ''
      echo bad
    '';
  };

  # GOOD: fixup hooks extend the default phase.
  goodFixupHooks = stdenv.mkDerivation {
    pname = "good-fixup-hooks";
    version = "1.0";
    preFixup = ''
      echo good
    '';
    postFixup = ''
      echo good
    '';
  };

  # GOOD: patch hooks extend the default phase.
  goodPatchHooks = stdenv.mkDerivation {
    pname = "good-patch-hooks";
    version = "1.0";
    prePatch = ''
      echo good
    '';
    postPatch = ''
      echo good
    '';
  };

  # GOOD: buildPhase is handled by a different query.
  goodBuildPhase = stdenv.mkDerivation {
    pname = "good-build-phase";
    version = "1.0";
    buildPhase = ''
      echo allowed here
    '';
  };

  # EDGE: callback shape still exposes direct fixupPhase bindings.
  edgeCallbackFixup = stdenv.mkDerivation (finalAttrs: {
    pname = "edge-callback-fixup";
    version = "1.0";
    fixupPhase = ''
      echo bad
    '';
  });
in
{
  inherit
    badFixup
    badPatch
    goodFixupHooks
    goodPatchHooks
    goodBuildPhase
    edgeCallbackFixup;
}
