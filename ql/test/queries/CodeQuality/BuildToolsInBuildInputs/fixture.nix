{ stdenv, cmake, meson, pkg-config, qt5, openssl, ... }:

let
  badCmake = stdenv.mkDerivation {
    pname = "bad-cmake";
    version = "1.0";
    buildInputs = [ cmake ];
  };

  badMesonAndPkgConfig = stdenv.mkDerivation {
    pname = "bad-meson-pkg-config";
    version = "1.0";
    buildInputs = [ meson pkg-config ];
  };

  goodNativeBuildInputs = stdenv.mkDerivation {
    pname = "good-native-build-inputs";
    version = "1.0";
    nativeBuildInputs = [ cmake meson pkg-config qt5.qmake ];
  };

  goodRuntimeDep = stdenv.mkDerivation {
    pname = "good-runtime-dep";
    version = "1.0";
    buildInputs = [ openssl ];
  };

  edgeDotted = stdenv.mkDerivation {
    pname = "edge-dotted";
    version = "1.0";
    buildInputs = [ qt5.qmake ];
  };

  edgeCallback = stdenv.mkDerivation (finalAttrs: {
    pname = "edge-callback";
    version = "1.0";
    buildInputs = [ cmake ];
  });

in
{
  inherit
    badCmake
    badMesonAndPkgConfig
    goodNativeBuildInputs
    goodRuntimeDep
    edgeDotted
    edgeCallback;
}
