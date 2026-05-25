{
  stdenv,
  stdenvNoCC,
  pkgs,
  lib,
  buildPythonPackage,
  buildPythonApplication,
  callPackage,
  passthru,
  src ? null,
}:

let
  # Plain mkDerivation
  plainStdenv = stdenv.mkDerivation {
    pname = "plain";
    version = "1.0";
    src = ./.;
  };

  # stdenvNoCC.mkDerivation
  nocc = stdenvNoCC.mkDerivation {
    pname = "nocc";
    buildInputs = [ ];
  };

  # Parens around the arg
  paren = stdenv.mkDerivation ({
    pname = "paren";
    version = "2.0";
  });

  # Callback shape (finalAttrs:)
  callback = stdenv.mkDerivation (finalAttrs: {
    pname = "callback";
    version = "3.0";
  });

  # Callback + rec
  callbackRec = stdenv.mkDerivation (
    finalAttrs: rec {
      pname = "callback-rec";
      version = "4.0";
      src = "${pname}-${version}";
    }
  );

  # Callback + let-in body
  callbackLet = stdenv.mkDerivation (
    finalAttrs:
    let
      suffix = "-helper";
    in
    {
      pname = "callback-let${suffix}";
      version = "5.0";
    }
  );

  # Plain rec (no callback)
  plainRec = stdenv.mkDerivation rec {
    pname = "plain-rec";
    version = "6.0";
    src = "${pname}-${version}";
  };

  # buildPythonPackage
  py = buildPythonPackage {
    pname = "py-pkg";
    version = "1.0";
    format = "setuptools";
  };

  # buildPythonApplication
  pyApp = buildPythonApplication {
    pname = "py-app";
    version = "1.0";
  };

  # inherit shape
  inheritShape = stdenv.mkDerivation {
    inherit pname version src;
    buildInputs = [ ];
  };

  # inherit (expr) shape
  inheritFromShape = stdenv.mkDerivation {
    inherit (passthru) pname version;
    buildInputs = [ ];
  };

  # dotted attrpath at top level (e.g. meta.description = ...)
  dottedAttr = stdenv.mkDerivation {
    pname = "dotted";
    version = "1.0";
    meta.description = "A package with a dotted top-level attribute path";
    meta.homepage = "https://example.com";
  };

  # NOT a derivation — should not match
  notADerivation = callPackage ./. {
    someArg = true;
  };

  # Some shared pname/version for inherit to grab
  pname = "shared";
  version = "1.0";
in
{
  inherit
    plainStdenv
    nocc
    paren
    callback
    callbackRec
    callbackLet
    plainRec
    py
    pyApp
    inheritShape
    inheritFromShape
    dottedAttr
    notADerivation
    ;
}
