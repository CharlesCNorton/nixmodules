{ pkgs, pkgs-unstable, lib, ... }:
let
  cargoRun = pkgs-unstable.writeScriptBin "cargo_run" ''
  
    if [ ! -f "$HOME/$REPL_SLUG/Cargo.toml" ]; then
      NAME=$(echo $REPL_SLUG | sed -r 's/([a-z0-9])([A-Z])/\1_\2/g'| tr '[:upper:]' '[:lower:]')
      ${pkgs-unstable.cargo}/bin/cargo init --name=$NAME
    fi

    ${pkgs-unstable.cargo}/bin/cargo run
  '';
  rust-version = lib.versions.majorMinor pkgs-unstable.rustc.version;
in
{
  id = "rust-${rust-version}";
  name = "Rust Tools";
  version = "1.0";

  packages = with pkgs-unstable; [
    cargo
    clang
    rustc
    rustfmt
    rust-analyzer
  ];

  replit.runners.cargo = {
    name = "cargo run";
    language = "rust";

    start = "${cargoRun}/bin/cargo_run";
    fileParam = false;
  };

  replit.languageServers.rust-analyzer = {
    name = "rust-analyzer";
    language = "rust";

    start = "${pkgs-unstable.rust-analyzer}/bin/rust-analyzer";
  };

  replit.formatters.cargo-fmt = {
    name = "cargo fmt";
    language = "rust";

    start = "${pkgs-unstable.cargo}/bin/cargo fmt";
    stdin = false;
  };

  replit.formatters.rustfmt = {
    name = "rustfmt";
    language = "rust";

    start = "${pkgs-unstable.rustfmt}/bin/rustfmt $file";
    stdin = false;
  };

  replit.packagers.rust = {
    name = "Rust";
    language = "rust";
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };

  replit.env = {
    CARGO_HOME = "$REPL_HOME/.cargo";
  };
}
