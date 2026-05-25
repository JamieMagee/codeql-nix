{ stdenv, lib, ... }:

let
  pkgConfigPath = "/opt/demo/lib/pkgconfig";
  ldflags = lib.concatStringsSep " " [ "-L/opt/demo/lib" ];
in
{
  # BAD: known environment variable at the top level.
  badNixCflagsCompile = stdenv.mkDerivation {
    pname = "bad-nix-cflags-compile";
    version = "1.0";
    NIX_CFLAGS_COMPILE = "-O3";
  };

  # BAD: PKG_CONFIG_.* variable at the top level.
  badPkgConfigPath = stdenv.mkDerivation {
    pname = "bad-pkg-config-path";
    version = "1.0";
    PKG_CONFIG_PATH = pkgConfigPath;
  };

  # GOOD: known variables belong under `env`.
  goodEnv = stdenv.mkDerivation {
    pname = "good-env";
    version = "1.0";
    env = {
      NIX_CFLAGS_COMPILE = "-O2";
      PKG_CONFIG_PATH = pkgConfigPath;
    };
  };

  # GOOD: arbitrary uppercase names are out of scope.
  goodFoo = stdenv.mkDerivation {
    pname = "good-foo";
    version = "1.0";
    FOO = "bar";
  };

  # EDGE: exact PKG_CONFIG must not match.
  edgePkgConfigExact = stdenv.mkDerivation {
    pname = "edge-pkg-config-exact";
    version = "1.0";
    PKG_CONFIG = "pkg-config";
  };

  # EDGE: callback-shape derivations still count.
  edgeCallback = stdenv.mkDerivation (_finalAttrs: {
    pname = "edge-callback";
    version = "1.0";
    NIX_LDFLAGS = ldflags;
  });
}
