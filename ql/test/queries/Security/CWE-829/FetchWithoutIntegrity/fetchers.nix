{ pkgs ? import <nixpkgs> { } }:

let
  # BAD: bare-string argument to a builtin fetcher (no hash anywhere)
  unsafe1 = builtins.fetchTarball "https://example.com/foo-1.0.tar.gz";

  # GOOD: attrset with sha256 attribute
  safe1 = builtins.fetchTarball {
    url = "https://example.com/foo-1.0.tar.gz";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };

  # GOOD: attrset with narHash attribute (modern form)
  safe2 = builtins.fetchTarball {
    url = "https://example.com/bar.tar.gz";
    narHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  # BAD: nixpkgs fetchurl in an attrset missing the hash attribute
  unsafe2 = pkgs.fetchurl {
    url = "https://example.com/baz.tar.gz";
  };

  # GOOD: nixpkgs fetchurl with hash
  safe3 = pkgs.fetchurl {
    url = "https://example.com/baz.tar.gz";
    hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
  };

  # BAD: fetchFromGitHub missing hash (rev alone is not enough)
  unsafe3 = pkgs.fetchFromGitHub {
    owner = "example";
    repo = "foo";
    rev = "v1.0";
  };

  # GOOD: fetchFromGitHub with hash
  safe4 = pkgs.fetchFromGitHub {
    owner = "example";
    repo = "foo";
    rev = "v1.0";
    hash = "sha256-CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=";
  };

  # BAD: bare fetchTarball after `with builtins;`
  unsafe4 = with builtins; fetchTarball "https://example.com/qux.tar.gz";

  # BAD: builtins.fetchGit with attrset missing hash
  unsafe5 = builtins.fetchGit {
    url = "https://example.com/repo.git";
    rev = "abc123";
  };

  # GOOD: builtins.fetchGit with narHash
  safe5 = builtins.fetchGit {
    url = "https://example.com/repo.git";
    rev = "abc123";
    narHash = "sha256-DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=";
  };

  # GOOD: inherit (source) hash — the hash IS in this attrset, via
  # inherit-from. The query must NOT flag this.
  source = { hash = "sha256-EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE="; };
  safe6 = pkgs.fetchFromGitHub {
    owner = "example";
    repo = "foo";
    rev = "v1.0";
    inherit (source) hash;
  };

  # GOOD: inherit hash; — same hash key is inherited from enclosing
  # `let` scope. Must NOT flag.
  hash = "sha256-FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF=";
  safe7 = pkgs.fetchurl {
    url = "https://example.com/x.tar.gz";
    inherit hash;
  };

  # GOOD: dynamic attribute name. We can't statically resolve
  # `${if cond then "hash" else "sha256"}`, so we conservatively assume
  # it might be an integrity key. Must NOT flag. (Real-world pattern from
  # pkgs/development/compilers/gcc/default.nix.)
  is13 = true;
  safe8 = pkgs.fetchurl {
    url = "https://example.com/y.tar.gz";
    ${if is13 then "hash" else "sha256"} = "sha256-GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG=";
  };

  # NEUTRAL: a non-fetcher function call that happens to take a string —
  # must NOT be flagged.
  someOtherCall = builtins.toString "hello";

  # NEUTRAL: a function defined locally called fetchTarball — same name
  # but not the real builtin. Our v0.1 query flags it as unpinned by name
  # (false positive — accepted scope for Phase 0; would need scope
  # resolution to filter out).
  localFetch = let fetchTarball = x: x; in fetchTarball "ignore";
in
{
  inherit
    unsafe1 unsafe2 unsafe3 unsafe4 unsafe5
    safe1 safe2 safe3 safe4 safe5 safe6 safe7 safe8
    someOtherCall localFetch;
}
