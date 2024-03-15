{ pkgs, lib, ... }:

let
  inherit (pkgs) deno;
  version = lib.versions.major deno.version;

  extensions = [ ".json" ".jsonc" ".js" ".jsx" ".ts" ".tsx" ];
in

{
  id = "deno-${version}";
  name = "Deno Tools";

  replit.packages = [
    deno
  ];

  replit.runners.deno-script-runner = {
    name = "deno";
    language = "javascript";
    inherit extensions;
    fileParam = true;
    start = "${deno}/bin/deno run --allow-all $file";
  };

  replit.dev.languageServers.deno = {
    name = "deno";
    language = "javascript";
    displayVersion = "Deno ${version}";
    inherit extensions;
    start = "${deno}/bin/deno lsp --quiet";
  };
}
