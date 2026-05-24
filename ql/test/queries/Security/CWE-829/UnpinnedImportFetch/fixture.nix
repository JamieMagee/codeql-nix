[
  # BAD: bare-string fetch
  (import (builtins.fetchTarball "https://example.com/x.tar.gz"))

  # BAD: attrset fetch missing hash
  (import (builtins.fetchTarball {
    url = "https://example.com/x.tar.gz";
  }))

  # BAD: bare identifier fetch
  (import (fetchTarball "https://example.com/x.tar.gz"))

  # BAD: fetchurl without a hash
  (import (pkgs.fetchurl {
    url = "https://example.com/default.nix";
  }))

  # GOOD: pinned tarball fetch
  (import (builtins.fetchTarball {
    url = "https://example.com/x.tar.gz";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  }))

  # GOOD: pinned GitHub fetch
  (import (pkgs.fetchFromGitHub {
    owner = "example";
    repo = "demo";
    rev = "0123456789abcdef0123456789abcdef01234567";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  }))

  # GOOD: local path import
  (import ./local-path)

  # GOOD: parenthesized local path import
  (import (./generated.nix))

  # GOOD: nix path lookup handled by a different query
  (import <nixpkgs>)
]
