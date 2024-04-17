{
  description = "Nix expressions for defining Replit development environments";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/?rev=7c4c20509c4363195841faa6c911777a134acdf3";
  # inputs.fenix.url = "github:nix-community/fenix";
  # inputs.fenix.inputs.nixpkgs.follows = "nixpkgs-unstable";
  # inputs.nixd.url = "github:nix-community/nixd";
  # inputs.nixd.inputs.nixpkgs.follows = "nixpkgs-unstable";
  # inputs.prybar.url = "github:replit/prybar";
  # inputs.prybar.inputs.nixpkgs.follows = "nixpkgs-unstable";
  # inputs.java-language-server.url = "github:replit/java-language-server";
  # inputs.java-language-server.inputs.nixpkgs.follows = "nixpkgs-unstable";
  # inputs.ztoc-rs.url = "github:replit/ztoc-rs";
  # inputs.ztoc-rs.inputs.nixpkgs.follows = "nixpkgs-unstable";
  inputs.replit-rtld-loader.url = "github:replit/replit_rtld_loader";
  inputs.replit-rtld-loader.inputs.nixpkgs.follows = "nixpkgs-unstable";

  outputs = { self, nixpkgs-unstable, replit-rtld-loader, ... }:
    let
      nixpkgs = nixpkgs-unstable;
      mkPkgs = nixpkgs-spec: system: import nixpkgs-spec {
        inherit system;
        overlays = [
          self.overlays.default
          # prybar.overlays.default
          # java-language-server.overlays.default
          # nixd.overlays.default
          # fenix.overlays.default
          replit-rtld-loader.overlays.default
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
      overlays.default = import ./pkgs/overlay { inherit pkgs self; };
      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
      packages.x86_64-linux = import ./pkgs {
        inherit pkgs self pkgs-23_05;
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
