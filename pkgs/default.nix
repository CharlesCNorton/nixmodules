{ pkgs, pkgs-23_05, self }:

with pkgs.lib;

let
  modules = self.modules;
  revstring_long = self.rev or "dirty";
  revstring = builtins.substring 0 7 revstring_long;
  all-modules = builtins.fromJSON (builtins.readFile ../modules.json);

  upgrade-maps = import ./upgrade-maps {
    inherit pkgs;
  };

  bundle-locked-fn = { modulesLocks }: pkgs.callPackage ./bundle-locked {
    inherit self modulesLocks upgrade-maps;
  };

  mkPhonyOCI = pkgs.callPackage ./mk-phony-oci { ztoc-rs = self.inputs.ztoc-rs.packages.x86_64-linux.default; };

  mkPhonyOCIs = { moduleIds ? null }: pkgs.callPackage ./mk-phony-ocis {
    inherit mkPhonyOCI revstring;
    modulesLocks = import ./filter-modules-locks {
      inherit pkgs moduleIds;
    };
  };

  bundle-squashfs-fn = { moduleIds ? null, diskName ? "disk.raw" }:
    let
      modulesLocks = import ./filter-modules-locks {
        inherit pkgs upgrade-maps;
        inherit moduleIds;
      };
    in
    pkgs.callPackage ./bundle-image {
      bundle-locked = bundle-locked-fn {
        inherit modulesLocks;
      };
      inherit revstring diskName;
    };

in
rec {
  inherit upgrade-maps;

  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  bundle = pkgs.linkFarm "nixmodules-bundle-${revstring}" (
    mapAttrsToList (name: value: { inherit name; path = value; }) modules
  );

  rev = pkgs.writeText "rev" revstring;

  rev_long = pkgs.writeText "rev_long" revstring_long;

  bundle-locked = bundle-locked-fn {
    modulesLocks = import ./filter-modules-locks {
      inherit pkgs upgrade-maps;
    };
  };

  custom-bundle-locked = bundle-locked-fn {
    modulesLocks = import ./filter-modules-locks {
      inherit pkgs upgrade-maps;
      moduleIds = [ "python-3.10" "nodejs-20" ];
    };
  };

  inherit (bundle-locked) active-modules registry;

  bundle-image = bundle-squashfs-fn { };

  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle-image revstring; };

  bundle-squashfs = bundle-squashfs-fn {
    moduleIds = [ "python-3.10" "nodejs-18" "nodejs-20" "docker" "replit" ];
    diskName = "disk.sqsh";
  };

  custom-bundle-squashfs = bundle-squashfs-fn {
    # customize these IDs for dev. They can be like "python-3.10:v10-20230711-6807d41" or "python-3.10"
    # publish your feature branch first and make sure modules.json is current, then
    # in goval dir (next to nixmodules), run `make custom-nixmodules-disk` to use this disk in conman
    # There is no need to check in changes to this.
    moduleIds = [ "python-3.10" "nodejs-18" "nodejs-20" "docker" "replit" ];
    diskName = "disk.sqsh";
  };

  all-historical-modules = mapAttrs
    (moduleId: module:
      let
        flake = builtins.getFlake "github:replit/nixmodules/${module.commit}";
        shortModuleId = elemAt (strings.splitString ":" moduleId) 0;
      in
      flake.modules.${shortModuleId})
    all-modules;

  custom-bundle-phony-ocis = mkPhonyOCIs { moduleIds = [ "nodejs-18" "nodejs-20" ]; };

  all-phony-oci-bundles = mapAttrs
    (moduleId: module:
      let
        flake = builtins.getFlake "github:replit/nixmodules/${module.commit}";
        shortModuleId = elemAt (strings.splitString ":" moduleId) 0;
      in
      mkPhonyOCI {
        inherit moduleId;
        module = flake.deploymentModules.${shortModuleId};
      })
    all-modules;

  bundle-phony-ocis = mkPhonyOCIs { };

  inherit all-modules;

  deploymentModules = self.deploymentModules;

  allModules = [
    (import ./moduleit/module-definition.nix)
    (import ./modules/bundles/go)
    (import ./modules/compilers/go)
    (import ./modules/languageServers/gopls)
    (import ./modules/formatters/gofmt)
    (import ./modules/bundles/ruby)
    (import ./modules/interpreters/ruby)
    (import ./modules/languageServers/solargraph)
    (import ./modules/packagers/rubygems)
    (import ./modules/bundles/nodejs)
    (import ./modules/interpreters/nodejs)
    (import ./modules/formatters/prettier)
    (import ./modules/languageServers/typescript-language-server)
    (import ./modules/packagers/nodejs-packager)
    (import ./modules/debuggers/node-dap)
    (import ./modules/bundles/bun)
    (import ./modules/interpreters/bun)
    (import ./modules/packagers/bun)
    (import ./modules/bundles/web)
    (import ./modules/languageServers/css-language-server)
    (import ./modules/languageServers/html-language-server)
  ];

  myEvalModule = path:
    (pkgs.lib.evalModules {
      modules = [
        (import path)
      ] ++ allModules;
      specialArgs = {
        inherit pkgs pkgs-23_05;
        pkgs-unstable = pkgs;
        modulesPath = builtins.toString ./.;
      };
    });

  v2BuildModule = path:
    (myEvalModule path).config.replit.buildModule;

  buildConfig = path:
    builtins.removeAttrs (myEvalModule path).config ["description" "displayVersion" "id" "name" "replit"];

  allModulesOptions =
    let eval = (pkgs.lib.evalModules {
      modules = allModules;
      specialArgs = {
        inherit pkgs pkgs-23_05;
        pkgs-unstable = pkgs;
        modulesPath = builtins.toString ./.;
      };
    });
    lib = pkgs.lib;
    options = eval.options;
    filteredOptions = builtins.removeAttrs options ["_module" "description" "displayVersion" "id" "name" "replit"];
    docsJson = (pkgs.nixosOptionsDoc {
      options = filteredOptions;
    }).optionsJSON;
    in filteredOptions;

  v2 = {
    go = v2BuildModule ./v2/go.nix;
    ruby = v2BuildModule ./v2/ruby.nix;
    web = v2BuildModule ./v2/web.nix;
    bun = v2BuildModule ./v2/bun.nix;
    nodejs = v2BuildModule ./v2/nodejs.nix;
  };

}
