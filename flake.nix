{
  description = "Nix expressions for defining Replit development environments";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.fenix.url = "github:nix-community/fenix";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixd.url = "github:nix-community/nixd";
  inputs.nixd.inputs.nixpkgs.follows = "nixpkgs";
  inputs.prybar.url = "github:replit/prybar";
  inputs.prybar.inputs.nixpkgs.follows = "nixpkgs";
  inputs.java-language-server.url = "github:replit/java-language-server";
  inputs.java-language-server.inputs.nixpkgs.follows = "nixpkgs";
  inputs.ztoc-rs.url = "github:replit/ztoc-rs";
  inputs.ztoc-rs.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, nixpkgs-unstable, prybar, java-language-server, nixd, fenix, ... }:
    let
      mkPkgs = nixpkgs-spec: system: import nixpkgs-spec {
        inherit system;
        overlays = [
          self.overlays.default
          prybar.overlays.default
          java-language-server.overlays.default
          nixd.overlays.default
          fenix.overlays.default
        ];
        # replbox has an unfree license
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          "@replit/replbox"
        ];
      };

      pkgs-23_05 = mkPkgs nixpkgs "x86_64-linux";

      pkgs = mkPkgs nixpkgs-unstable "x86_64-linux";
    in
    {
      overlays.default = final: prev: {
        moduleit = self.packages.${prev.system}.moduleit;
      };
      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
      packages.x86_64-linux = import ./pkgs {
        inherit pkgs self;
      };
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          python310
          pigz
          coreutils
          findutils
          e2fsprogs
          gnutar
          gzip
        ];
      };
    } // (
      import ./pkgs/modules {
        inherit pkgs;
        inherit pkgs-23_05;
      }
    );
}
