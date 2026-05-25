{ stdenv, lib, ... }:

let
  # BAD: `version` should follow `pname`.
  badVersionBeforePname = stdenv.mkDerivation {
    version = "1.0";
    pname = "bad-version-before-pname";
  };

  # BAD: `src` should follow `pname`.
  badSrcBeforePnameAndVersion = stdenv.mkDerivation {
    src = ./.;
    pname = "bad-src-before-pname-and-version";
    version = "1.0";
  };

  # BAD: `meta` should follow `nativeBuildInputs`.
  badMetaBeforeNativeBuildInputs = stdenv.mkDerivation {
    pname = "bad-meta-before-native-build-inputs";
    version = "1.0";
    meta = with lib; {
      description = "bad";
    };
    nativeBuildInputs = [ ];
  };

  # GOOD: canonical order.
  goodCanonical = stdenv.mkDerivation {
    pname = "good-canonical";
    version = "1.0";
    src = ./.;
    nativeBuildInputs = [ ];
    meta = with lib; {
      description = "good";
    };
  };

  # GOOD: unknown attrs do not constrain known-attribute ordering.
  goodUnknownInterspersed = stdenv.mkDerivation {
    pname = "good-unknown-interspersed";
    customPhase = "echo custom";
    version = "1.0";
    anotherUnknown = true;
    src = ./.;
    yetAnotherUnknown = [ ];
    nativeBuildInputs = [ ];
    meta = with lib; {
      description = "still good";
    };
  };

  # EDGE: `inherit` does not contribute to direct known-attribute ordering.
  edgeInherit =
    let
      pname = "edge-inherit";
      version = "1.0";
    in
    stdenv.mkDerivation {
      inherit pname version;
      src = ./.;
    };
in
{
  inherit
    badVersionBeforePname
    badSrcBeforePnameAndVersion
    badMetaBeforeNativeBuildInputs
    goodCanonical
    goodUnknownInterspersed
    edgeInherit;
}
