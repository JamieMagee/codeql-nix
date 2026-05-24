{ stdenv, lib, version, pname, pkgs }:

let
  # BAD: direct interpolation of untrusted formal `version` into buildPhase
  unsafeVersion = stdenv.mkDerivation {
    inherit pname version;
    buildPhase = ''
      ./configure --version="${version}"
    '';
  };

  # BAD: untrusted formal flows via a let-binding
  unsafeLetBound = stdenv.mkDerivation {
    inherit pname;
    buildPhase =
      let
        ver = version;
      in
      ''
        ./configure --version="${ver}"
      '';
  };

  # BAD: string concatenation propagates taint
  unsafeConcat = stdenv.mkDerivation {
    inherit pname;
    buildPhase = "./configure --version=" + version;
  };

  # BAD: indented string with interpolation in installPhase
  unsafeIndented = stdenv.mkDerivation {
    inherit pname;
    installPhase = ''
      cp -r src $out/${pname}
    '';
  };

  # GOOD: explicit escape — sanitizer breaks the flow
  safeEscaped = stdenv.mkDerivation {
    inherit pname version;
    buildPhase = ''
      ./configure --version=${lib.escapeShellArg version}
    '';
  };

  # GOOD: stdenv is in the trusted-formal allow-list
  safeStdenvPath = stdenv.mkDerivation {
    inherit pname;
    buildPhase = ''
      cp ${stdenv.cc.cc.lib}/lib/libfoo.so $out/
    '';
  };

  # GOOD: pkgs is trusted
  safePkgsPath = stdenv.mkDerivation {
    inherit pname;
    buildPhase = ''
      ln -s ${pkgs.zlib}/include $out/include
    '';
  };

  # NEUTRAL: interpolation outside a shell-context attribute. `homepage`
  # is in `meta`, not a phase attribute. Must not flag.
  metaInterpolation = stdenv.mkDerivation {
    inherit pname;
    meta = {
      homepage = "https://example.com/${pname}";
    };
  };

  # BAD: pname is NOT in the trusted-formal allow-list (packages often
  # take pname from upstream metadata).
  unsafePname = stdenv.mkDerivation {
    inherit pname;
    postInstall = ''
      mv $out/bin/foo $out/bin/${pname}-bin
    '';
  };
in
{
  inherit
    unsafeVersion
    unsafeLetBound
    unsafeConcat
    unsafeIndented
    safeEscaped
    safeStdenvPath
    safePkgsPath
    metaInterpolation
    unsafePname;
}
