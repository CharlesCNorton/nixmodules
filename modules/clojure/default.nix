{ pkgs, lib, ... }:
let clojure-version = lib.versions.majorMinor pkgs.clojure.version;
in
{
  id = "clojure-${clojure-version}";
  name = "Clojure Tools";

  replit.runners.clojure = {
    name = "Clojure";
    language = "clojure";

    start = "${pkgs.clojure}/bin/clojure -M $file";
    fileParam = true;
  };

  replit.languageServers.clojure-lsp = {
    name = "Clojure LSP";
    language = "clojure";

    start = "${pkgs.clojure-lsp}/bin/clojure-lsp";
  };
}
