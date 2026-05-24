let
  # BAD: import from ambient NIX_PATH
  bad1 = import <nixpkgs> { };

  # BAD: lookup path inside a let binding
  bad2 = let pkgs = import <nixpkgs> { }; in pkgs;

  # BAD: bare lookup path reference
  bad3 = <unstable>;

  # GOOD: repository-local path
  good1 = import ./local-path;

  # GOOD: direct URL string import (not a lookup path)
  good2 = import "https://example.com/x.nix";

  # GOOD: content-pinned fetch
  good3 = import (builtins.fetchTarball {
    url = "https://example.com/x.tar.gz";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  });
in
{
  inherit bad1 bad2 bad3 good1 good2 good3;
}
