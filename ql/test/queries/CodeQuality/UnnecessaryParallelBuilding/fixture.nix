{ stdenv, lib, meson, cmake, qt5, ... }:

let
  x = lib;
in
{
  # BAD: CMake already enables parallel building.
  badCmake = stdenv.mkDerivation {
    pname = "bad-cmake";
    version = "1.0";
    enableParallelBuilding = true;
    nativeBuildInputs = [ cmake ];
  };

  # BAD: Meson already enables parallel building.
  badMeson = stdenv.mkDerivation {
    pname = "bad-meson";
    version = "1.0";
    enableParallelBuilding = true;
    nativeBuildInputs = [ meson ];
  };

  # BAD: qmake already enables parallel building.
  badQmake = stdenv.mkDerivation {
    pname = "bad-qmake";
    version = "1.0";
    enableParallelBuilding = true;
    nativeBuildInputs = [ qt5.qmake ];
  };

  # GOOD: explicit opt-in without an automatic configure hook.
  goodManual = stdenv.mkDerivation {
    pname = "good-manual";
    version = "1.0";
    enableParallelBuilding = true;
  };

  # GOOD: CMake hook disabled, so the explicit opt-in is meaningful.
  goodDontUseCmake = stdenv.mkDerivation {
    pname = "good-dont-use-cmake";
    version = "1.0";
    enableParallelBuilding = true;
    nativeBuildInputs = [ cmake ];
    dontUseCmakeConfigure = true;
  };

  # GOOD: custom configurePhase may bypass the hook.
  goodCustomConfigurePhase = stdenv.mkDerivation {
    pname = "good-custom-configure-phase";
    version = "1.0";
    enableParallelBuilding = true;
    nativeBuildInputs = [ cmake ];
    configurePhase = ''
      runHook preConfigure
      echo custom configure
      runHook postConfigure
    '';
  };

  # GOOD: enableParallelBuilding is not enabled.
  goodDisabled = stdenv.mkDerivation {
    pname = "good-disabled";
    version = "1.0";
    enableParallelBuilding = false;
    nativeBuildInputs = [ cmake ];
  };
}
