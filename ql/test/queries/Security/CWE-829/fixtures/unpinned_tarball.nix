{ pkgs ? import <nixpkgs> { } }:

let
  src = builtins.fetchTarball "https://example.com/foo-1.0.tar.gz";
in
pkgs.stdenv.mkDerivation {
  pname = "foo";
  version = "1.0";
  inherit src;

  buildInputs = [ pkgs.cmake ];

  cmakeFlags = [
    "-DFOO=bar"
    "-DBAZ=qux"
  ];
}
