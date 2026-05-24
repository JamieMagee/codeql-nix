{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib }:

let
  # BAD: dotted builtin calls read the host environment.
  bad1 = builtins.getEnv "HOME";
  bad2 = builtins.getEnv "PATH";

  # BAD: bare builtin call under `with builtins;`.
  bad3 = with builtins; getEnv "HOME";

  # GOOD: a locally shadowed helper named getEnv.
  good1 = let getEnv = x: x; in getEnv "X";

  # GOOD: different namespaces.
  good2 = pkgs.lib.getEnv "HOME";
  good3 = lib.getEnv "PATH";

  # GOOD: bare getEnv with no surrounding `with builtins;`.
  good4 = getEnv "X";
in
{
  inherit bad1 bad2 bad3 good1 good2 good3 good4;
}
