{ python, pypkgs }:
{ pkgs, lib, ... }:
let
  inherit (import ./wrap.nix { inherit pkgs pypkgs python; })
    python-ld-library-path
    wrapPython;

  pythonVersion = lib.versions.majorMinor python.version;

  pylibs-dir = ".pythonlibs";

  pip = pkgs.callPackage ../../pip {
    inherit pypkgs;
  };

  pip-config = pkgs.writeTextFile {
    name = "pip.conf";
    text = ''
      [global]
      user = yes
      disable-pip-version-check = yes
      index-url = https://package-proxy.replit.com/pypi/simple/

      [install]
      use-feature = content-addressable-pool
      content-addressable-pool-symlink = yes
    '';
  };

  pip-wrapper = wrapPython { bin = "${pip}/bin/pip"; name = "pip"; };

  poetry = pkgs.callPackage (../../poetry/poetry-py + "${pythonVersion}.nix") {
    inherit python;
    inherit pypkgs;
  };

  poetry-config = pkgs.writeTextFile {
    name = "poetry-config";
    text = ''
      [[tool.poetry.source]]
      name = "replit"
      url = "https://package-proxy.replit.com/pypi/simple/"
      default = true
    '';
    destination = "/conf.toml";
  };

  prybar-bin-version = if pythonVersion == "3.8" then "3" else "310";
  prybar-python = pkgs.prybar."prybar-python${prybar-bin-version}";

  stderred = pkgs.callPackage ../../stderred { };

  dapPython = pkgs.callPackage ../../dapPython {
    inherit pkgs python pypkgs;
  };

  debuggerConfig = if (pythonVersion == "3.11") then ({ }) else
  ({
    dapPython = {
      name = "DAP Python";
      language = "python3";
      start = {
        args = [ "${dapPython}/bin/dap-python" "$file" ];
      };
      fileParam = true;
      transport = "localhost:0";
      integratedAdapter = {
        dapTcpAddress = "localhost:0";
      };
      initializeMessage = {
        command = "initialize";
        type = "request";
        arguments = {
          adapterID = "debugpy";
          clientID = "replit";
          clientName = "replit.com";
          columnsStartAt1 = true;
          linesStartAt1 = true;
          locale = "en-us";
          pathFormat = "path";
          supportsInvalidatedEvent = true;
          supportsProgressReporting = true;
          supportsRunInTerminalRequest = true;
          supportsVariablePaging = true;
          supportsVariableType = true;
        };
      };
      launchMessage = {
        command = "attach";
        type = "request";
        arguments = {
          logging = { };
        };
      };
    };
  });

  python3-wrapper = wrapPython { bin = "${python}/bin/python3"; name = "python3"; aliases = [ "python" "python${pythonVersion}" ]; };

  run-prybar-bin = pkgs.writeShellScriptBin "run-prybar" ''
    ${stderred}/bin/stderred -- ${prybar-python}/bin/prybar-python${prybar-bin-version} -q --ps1 "''$(printf '\u0001\u001b[33m\u0002\u0001\u001b[00m\u0002 ')" -i ''$1
  '';

  run-prybar = wrapPython { bin = "${run-prybar-bin}/bin/run-prybar"; name = "run-prybar"; };

  poetry-wrapper = wrapPython { bin = "${poetry}/bin/poetry"; name = "poetry"; };

  pyright-extended = pkgs.callPackage ../../pyright-extended { };
in
{
  id = "python-${pythonVersion}";
  name = "Python ${pythonVersion} Tools";

  packages = [
    python3-wrapper
    pip-wrapper
    poetry-wrapper
    run-prybar
  ];

  replit.runners.python = {
    name = "Python ${pythonVersion}";
    fileParam = true;
    language = "python3";
    start = "${python3-wrapper}/bin/python3 $file";
  };

  replit.runners.python-prybar = {
    name = "Prybar for Python ${pythonVersion}";
    optionalFileParam = true;
    language = "python3";
    start = "${run-prybar}/bin/run-prybar $file";
    interpreter = true;
  };

  replit.debuggers = debuggerConfig;

  replit.languageServers.pyright-extended = {
    name = "pyright-extended";
    language = "python3";
    start = "${pyright-extended}/bin/langserver.index.js --stdio";
  };

  replit.packagers.upmPython = {
    name = "Python";
    language = "python3";
    ignoredPackages = [ "unit_tests" ];
    ignoredPaths = [ pylibs-dir ];
    features = {
      packageSearch = true;
      guessImports = true;
      enabledForHosting = false;
    };
  };

  replit.env =
    let userbase = "$REPL_HOME/${pylibs-dir}";
    in {
      PYTHONPATH = "${python}/lib/python${pythonVersion}:${userbase}/${python.sitePackages}";
      PIP_CONFIG_FILE = pip-config.outPath;
      POETRY_CONFIG_DIR = poetry-config.outPath;
      POETRY_CACHE_DIR = "$REPL_HOME/.cache/pypoetry";
      POETRY_VIRTUALENVS_CREATE = "0";
      POETRY_INSTALLER_MODERN_INSTALLATION = "0";
      POETRY_PIP_USE_PIP_CACHE = "1";
      POETRY_PIP_NO_ISOLATE = "1";
      POETRY_PIP_NO_PREFIX = "1";
      POETRY_PIP_FROM_PATH = "1";
      POETRY_USE_USER_SITE = "1";
      PYTHONUSERBASE = userbase;
      # Even though it is set-default in the wrapper, add it to the
      # environment too, so that when someone wants to override it,
      # they can keep the defaults if they want to.
      PYTHON_LD_LIBRARY_PATH = python-ld-library-path;
      PATH = "${userbase}/bin";
    };
}
