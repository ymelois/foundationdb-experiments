{
  description = "FoundationDB";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      supportedSystems = [
        "x86_64-linux"
      ];
      forAllSystems = lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;

            overlays = [
              (final: prev: {
                ccacheWrapper = prev.ccacheWrapper.override {
                  extraConfig = ''
                    export CCACHE_DIR=/var/cache/ccache
                    export CCACHE_MAXSIZE=20GiB
                    export CCACHE_COMPRESS=1
                    export CCACHE_UMASK=007
                    export CCACHE_SLOPPINESS=random_seed
                  '';
                };
              })
            ];
          };
          foundationdb = pkgs.callPackage ./nix/pkgs/foundationdb {
            stdenv = pkgs.ccacheStdenv;
          };
        in
        {
          inherit foundationdb;
          default = foundationdb;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [ ];
          };
        }
      );
    };
}
