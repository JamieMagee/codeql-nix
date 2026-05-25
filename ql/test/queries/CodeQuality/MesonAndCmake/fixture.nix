{ stdenv, lib, meson, cmake, ... }:

let
  callPackage = path: args: { inherit path args; };

  # BAD: both configure-phase build systems in nativeBuildInputs.
  badBoth = stdenv.mkDerivation {
    pname = "bad-both";
    version = "1.0";
    nativeBuildInputs = [ meson cmake ];
  };

  # GOOD: only Meson.
  goodMesonOnly = stdenv.mkDerivation {
    pname = "good-meson-only";
    version = "1.0";
    nativeBuildInputs = [ meson ];
  };

  # GOOD: only CMake.
  goodCmakeOnly = stdenv.mkDerivation {
    pname = "good-cmake-only";
    version = "1.0";
    nativeBuildInputs = [ cmake ];
  };

  # EDGE: buildInputs does not matter for this rule.
  edgeBuildInputsOnly = stdenv.mkDerivation {
    pname = "edge-build-inputs-only";
    version = "1.0";
    nativeBuildInputs = [ meson ];
    buildInputs = [ cmake ];
  };

  # EDGE: neither build system is present.
  edgeNeither = stdenv.mkDerivation {
    pname = "edge-neither";
    version = "1.0";
  };

  # EDGE: not a derivation wrapper, so it must not match.
  edgeCallPackage = callPackage ./dummy.nix {
    nativeBuildInputs = [ meson cmake ];
  };
in
{
  inherit
    badBoth
    goodMesonOnly
    goodCmakeOnly
    edgeBuildInputsOnly
    edgeNeither
    edgeCallPackage;
}
