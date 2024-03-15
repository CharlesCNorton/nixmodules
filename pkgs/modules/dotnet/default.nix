{ pkgs, lib, ... }:

let
  dotnet = pkgs.dotnet-sdk_7;

  extensions = [ ".cs" ".csproj" ".fs" ".fsproj" ];

  dotnet-version = lib.versions.majorMinor dotnet.version;
in

{
  id = "dotnet-${dotnet-version}";
  name = ".NET 7 Tools";

  replit.packages = [
    dotnet
  ];

  replit.runners.dotnet = {
    inherit extensions;
    name = ".NET";
    language = "dotnet";

    start = "${dotnet}/bin/dotnet run";
  };

  replit.dev.languageServers.omni-sharp = {
    inherit extensions;
    name = "OmniSharp";
    language = "dotnet";

    displayVersion = pkgs.omnisharp-roslyn.version;
    start = "${pkgs.omnisharp-roslyn}/bin/OmniSharp --languageserver";
  };

  replit.dev.packagers.dotnet = {
    name = ".NET";
    language = "dotnet";
    displayVersion = dotnet.version;
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };
}
