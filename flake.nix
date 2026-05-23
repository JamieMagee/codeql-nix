{
  description = "CodeQL extractor and query pack for the Nix expression language";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # CodeQL is unfree; allow it specifically.
          config.allowUnfreePredicate =
            pkg:
            builtins.elem (pkgs.lib.getName pkg) [
              "codeql"
            ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "codeql-nix-dev";

          packages = with pkgs; [
            # Rust toolchain
            rustc
            cargo
            rustfmt
            rust-analyzer
            clippy

            # CodeQL tooling
            codeql

            # Tree-sitter
            tree-sitter

            # Utilities
            just
            jq
            git
          ];

          shellHook = ''
            echo "codeql-nix dev shell"
            echo "  rustc:        $(rustc --version)"
            echo "  cargo:        $(cargo --version)"
            echo "  codeql:       $(codeql version 2>/dev/null | head -n1 || echo 'codeql not in PATH')"
            echo "  tree-sitter:  $(tree-sitter --version 2>/dev/null | head -n1 || echo 'tree-sitter not in PATH')"
          '';
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
