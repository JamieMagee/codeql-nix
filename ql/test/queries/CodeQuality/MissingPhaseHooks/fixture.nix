{ stdenv, lib, ... }:

let
  cond = true;

  badBuildBothMissing = stdenv.mkDerivation {
    pname = "bad-build-both-missing";
    version = "1.0";
    buildPhase = "make";
  };

  badInstallPostMissing = stdenv.mkDerivation {
    pname = "bad-install-post-missing";
    version = "1.0";
    installPhase = ''
      runHook preInstall
      make install
    '';
  };

  goodBuildHooks = stdenv.mkDerivation {
    pname = "good-build-hooks";
    version = "1.0";
    buildPhase = ''
      runHook preBuild
      make
      runHook postBuild
    '';
  };

  goodNoBuildOverride = stdenv.mkDerivation {
    pname = "good-no-build-override";
    version = "1.0";
  };

  edgeNonStringInstallPhase = stdenv.mkDerivation {
    pname = "edge-non-string-install-phase";
    version = "1.0";
    installPhase = lib.optionalString cond ''
      runHook preInstall
      make install
    '';
  };
in
{
  inherit
    badBuildBothMissing
    badInstallPostMissing
    goodBuildHooks
    goodNoBuildOverride
    edgeNonStringInstallPhase;
}
