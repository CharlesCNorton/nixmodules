{ pkgs, lib, ... }:
let
  php-version = lib.versions.majorMinor pkgs.php.version;
in
{
  id = "php-${php-version}";
  name = "PHP Tools";

  replit.packages = with pkgs; [
    php
    pkgs.phpPackages.composer
  ];

  replit.runners.php = {
    name = "php run";
    language = "php";
    start = "${pkgs.php}/bin/php $file";
    fileParam = true;
  };

  replit.dev.languageServers.phpactor = {
    name = "phpactor";
    language = "php";

    displayVersion = pkgs.phpactor.version;

    start = "${pkgs.phpactor}/bin/phpactor language-server";
  };

  replit.dev.packagers.php = {
    name = "Composer";
    language = "php";
    displayVersion = pkgs.phpPackages.composer.version;
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };
}
