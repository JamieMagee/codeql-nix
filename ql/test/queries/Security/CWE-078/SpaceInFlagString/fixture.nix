{ pkgs ? import <nixpkgs> { } }:

let
  # BAD: embedded space inside a single flag string.
  bad1 = {
    cmakeFlags = [ "-DFOO=bar baz" ];
  };

  # BAD: two flags packed into one list element.
  bad2 = {
    mesonFlags = [ "-Dprefix=/usr -Dlibdir=/usr/lib" ];
  };

  # BAD: configure flags combined into one string.
  bad3 = {
    configureFlags = [ "--with-foo=bar --with-baz" ];
  };

  # GOOD: each flag is its own list element.
  good1 = {
    cmakeFlags = [ "-DFOO=bar" "-DBAZ=qux" ];
  };

  # GOOD: interpolation means this is not a plain literal.
  good2 = {
    cmakeFlags = [ "-DPATH=${pkgs.foo}/bin" ];
  };

  # GOOD: empty string is allowed.
  good3 = {
    cmakeFlags = [ "" "-DFOO=bar" ];
  };

  # GOOD: trailing whitespace only is outside the current query scope.
  good4 = {
    cmakeFlags = [ "-DFOO=bar " ];
  };

  # NEUTRAL: space in a non-flag binding must not be flagged.
  neutral1 = {
    pname = "my package";
  };
in
{
  inherit bad1 bad2 bad3 good1 good2 good3 good4 neutral1;
}
