{ pkgs ? import <nixpkgs> { } }:

let
  # BAD: bare URI literals
  badHttps = https://example.com;
  badFtp = ftp://example.com/foo;
  url = https://example.com/x.tar.gz;

  # GOOD: quoted URI strings
  goodHttps = "https://example.com";
  goodFtp = "ftp://example.com/foo";

  # GOOD: other expression kinds
  goodLocalPath = ./local-path;
  goodAttr = pkgs.foo;
in
{
  inherit
    badHttps
    badFtp
    url
    goodHttps
    goodFtp
    goodLocalPath
    goodAttr;
}
