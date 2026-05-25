{ stdenv }:

let
  # BAD: direct buildPhase override.
  badBuild = stdenv.mkDerivation {
    pname = "bad-build";
    version = "1.0";
    buildPhase = ''
      runHook preBuild
      make
      runHook postBuild
    '';
  };

  # BAD: direct installPhase override.
  badInstall = stdenv.mkDerivation {
    pname = "bad-install";
    version = "1.0";
    installPhase = ''
      make install
    '';
  };

  # BAD: direct configurePhase override.
  badConfigure = stdenv.mkDerivation {
    pname = "bad-configure";
    version = "1.0";
    configurePhase = ''
      ./configure --prefix=$out
    '';
  };

  # BAD: direct checkPhase override.
  badCheck = stdenv.mkDerivation {
    pname = "bad-check";
    version = "1.0";
    checkPhase = ''
      make check
    '';
  };

  # GOOD: use hooks instead of replacing buildPhase.
  goodHooks = stdenv.mkDerivation {
    pname = "good-hooks";
    version = "1.0";
    preBuild = ''
      echo before
    '';
    postBuild = ''
      echo after
    '';
  };

  # GOOD: unpackPhase is outside nixpkgs-hammering's explicit-phases list.
  goodUnpack = stdenv.mkDerivation {
    pname = "good-unpack";
    version = "1.0";
    unpackPhase = ''
      true
    '';
  };

  # GOOD: fixupPhase / patchPhase belong to protected-phase-override, not here.
  goodProtectedPhases = stdenv.mkDerivation {
    pname = "good-protected-phases";
    version = "1.0";
    fixupPhase = ''
      true
    '';
    patchPhase = ''
      true
    '';
  };

  # EDGE: dotted attrpath must not match.
  dottedAttrpath = stdenv.mkDerivation {
    pname = "dotted";
    version = "1.0";
    meta.something = "buildPhase";
  };

  # EDGE: callback-style mkDerivation arguments must still match.
  callbackShape = stdenv.mkDerivation (finalAttrs: {
    pname = "callback-shape";
    version = "1.0";
    buildPhase = ''
      make callback
    '';
  });

  # EDGE: nested attrset that is not a derivation arg must not match.
  nestedAttrset = {
    buildPhase = ''
      make nested
    '';
  };

  # EDGE: nested attrset inside a derivation also must not match.
  nestedInDerivation = stdenv.mkDerivation {
    pname = "nested-in-derivation";
    version = "1.0";
    passthru = {
      buildPhase = ''
        make passthru
      '';
    };
  };
in
{
  inherit
    badBuild
    badInstall
    badConfigure
    badCheck
    goodHooks
    goodUnpack
    goodProtectedPhases
    dottedAttrpath
    callbackShape
    nestedAttrset
    nestedInDerivation
    ;
}
