{ stdenv, lib, pytest, requests, ... }:

let
  # BAD: propagatedBuildInputs duplicate in checkInputs.
  badCheckInputs = stdenv.mkDerivation {
    pname = "bad-check-inputs";
    version = "1.0";
    propagatedBuildInputs = [ requests pytest ];
    checkInputs = [ pytest ];
  };

  # BAD: propagatedBuildInputs duplicate in nativeCheckInputs.
  badNativeCheckInputs = stdenv.mkDerivation {
    pname = "bad-native-check-inputs";
    version = "1.0";
    propagatedBuildInputs = [ requests pytest ];
    nativeCheckInputs = [ pytest ];
  };

  # GOOD: pytest only appears in checkInputs.
  goodCheckOnly = stdenv.mkDerivation {
    pname = "good-check-only";
    version = "1.0";
    checkInputs = [ pytest ];
  };

  # GOOD: buildInputs does not count for this rule.
  goodBuildInputsAndCheckInputs = stdenv.mkDerivation {
    pname = "good-build-inputs-and-check-inputs";
    version = "1.0";
    buildInputs = [ pytest ];
    checkInputs = [ pytest ];
  };

  # BAD/EDGE: callback shape derivation still exposes direct bindings.
  edgeCallback = stdenv.mkDerivation (finalAttrs: {
    pname = "edge-callback";
    version = "1.0";
    propagatedBuildInputs = [ requests pytest ];
    checkInputs = [ pytest ];
  });

  # EDGE: dynamic propagatedBuildInputs is intentionally out of scope.
  edgeDynamic = stdenv.mkDerivation {
    pname = "edge-dynamic";
    version = "1.0";
    propagatedBuildInputs = lib.optionals true [ pytest ];
    checkInputs = [ pytest ];
  };
in
{
  inherit
    badCheckInputs
    badNativeCheckInputs
    goodCheckOnly
    goodBuildInputsAndCheckInputs
    edgeCallback
    edgeDynamic;
}
