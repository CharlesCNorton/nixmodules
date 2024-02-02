{ config, lib, pkgs, ... }:

with lib;

let
  initializerModule = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The name of the initializer. An initializer is usually used to scaffold
          a project by creating some files and/or directories.
        '';
      };

      start = mkOption {
        type = commandType;
        description = lib.mdDoc ''
          The command to run the initializer.
        '';
      };

      runOnce = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc ''
          If runOnce is true, the initializer will only be run once.
        '';
      };
    };
  };

  commandModule = { name, config, ... }: {
    options = {
      args = mkOption {
        type = types.listOf (types.str);
        description = lib.mdDoc ''
          The first element is looked up on PATH, and the rest of the elements
          are arguments.
        '';
      };

      env = mkOption {
        type = types.attrsOf (types.str);
        default = { };
        description = lib.mdDoc ''
          Environment variables to set when running this command.
        '';
      };
    };
  };

  # You can specify a command as either a string, or an object having args and env(commandModule)
  commandType = types.either types.str (types.submodule commandModule);

  fileTypeAttrs = {
    extensions = mkOption {
      type = types.listOf (types.str);
      default = [ ];
      description = lib.mdDoc ''
        A list of file extensions that are supported.
      '';
    };

    files = mkOption {
      type = types.listOf (types.str);
      default = [ ];
      description = lib.mdDoc ''
        A list of file names (exact match) that are supported.
      '';
    };

    filePattern = mkOption {
      type = types.str;
      default = "";
      description = lib.mdDoc ''
        A glob pattern matching file names that are supported.
      '';
    };
  };

  runnerOptions =
    let
      runnerProductionOverrides = { name, config, ... }:
        {
          options = {
            start = mkOption {
              type = commandType;
              description = lib.mdDoc ''
                The command to run a file in production. Use $file to substitute in the file path.
              '';
            };

            compile = mkOption {
              type = types.nullOr commandType;
              default = null;
              description = lib.mdDoc ''
                The command to compile a source file in production. Use $file to substitute in the file path.
              '';
            };

            fileParam = mkOption {
              type = types.bool;
              default = false;
              description = lib.mdDoc ''
                Whether this runner accepts a $file paramater in production.
              '';
            };
          };
        };
    in
    {
      name = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The name of the runner.
        '';
      };

      language = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The language this runner supports.
        '';
      };

      start = mkOption {
        type = commandType;
        description = lib.mdDoc ''
          The command to run a file. Use $file to substitute in the file path.
        '';
      };

      fileParam = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether this runner accepts a $file paramater.
        '';
      };

      optionalFileParam = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether this runner optionally accepts a $file paramater. Only set this if fileParam is not set.
        '';
      };

      interpreter = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether this runner starts an interpreter. Default: false.
        '';
      };

      prompt = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc ''
          If interpreter is true, this prompt is displayed.
        '';
      };

      compile = mkOption {
        type = types.nullOr commandType;
        default = null;
        description = lib.mdDoc ''
          The command to compile a source file. Use $file to substitute in the file path.
        '';
      };

      productionOverride = mkOption {
        type = types.nullOr (types.submodule runnerProductionOverrides);
        default = null;
        description = lib.mdDoc ''
          The command configurations to use in production overriding the normal commands
          that are used in development.
        '';
      };

    } // fileTypeAttrs;

  runnerModule = { name, config, ... }: { options = runnerOptions; };

  languageServerModule = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The name of the language server.
        '';
      };

      language = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The language this language server supports.
        '';
      };

      extensions = mkOption {
        type = types.listOf (types.str);
        default = [ ];
        description = lib.mdDoc ''
          A list of file extensions this language server supports.
        '';
      };

      start = mkOption {
        type = commandType;
        description = lib.mdDoc ''
          The command to start the language server.
        '';
      };

      configuration = mkOption {
        type = types.anything;
        default = null;
        description = lib.mdDoc ''
          Some configuration options that the client can send to the server
          https://microsoft.github.io/language-server-protocol/specification#workspace_configuration
        '';
      };

      initializationOptions = mkOption {
        type = types.anything;
        default = null;
        description = lib.mdDoc ''
          InitializationOptions is sent to the LSP server with the initialize request.
          https://microsoft.github.io/language-server-protocol/specification#initialize
        '';
      };

    } // fileTypeAttrs;
  };

  formatterModule = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The name of the formatter.
        '';
      };

      language = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The language this formatter supports.
        '';
      };

      extensions = mkOption {
        type = types.listOf (types.str);
        default = [ ];
        description = lib.mdDoc ''
          A list of file extensions this formatter supports.
        '';
      };

      start = mkOption {
        type = commandType;
        description = lib.mdDoc ''
          The command to run a code formatter. Use $file to substitute in the file path.
        '';
      };

      stdin = mkOption {
        type = types.bool;
        description = lib.mdDoc ''
          Whether to pass in file contents from stdin or from $file parameter.
        '';
      };
    } // fileTypeAttrs;
  };

  debuggerModule = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The name of the debugger.
        '';
      };

      language = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The language this debugger supports.
        '';
      };

      extensions = mkOption {
        type = types.listOf (types.str);
        default = [ ];
        description = lib.mdDoc ''
          A list of file extensions this debugger supports.
        '';
      };

      start = mkOption {
        type = commandType;
        description = lib.mdDoc ''
          The command to start the debug (dap) server.
        '';
      };

      fileParam = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether this debugger accepts a $file paramater.
        '';
      };

      transport = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc ''
          The transport of the debug server.
        '';
      };

      compile = mkOption {
        type = types.nullOr commandType;
        default = null;
        description = lib.mdDoc ''
          The command to compile a source file for debugging. Use $file to substitute in the file path.
        '';
      };

      integratedAdapter = {
        dapTcpAddress = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = lib.mdDoc ''
            The TCP address to use to connect to the DAP server.
          '';
        };
      };

      initializeMessage = {
        command = mkOption {
          type = types.str;
          description = lib.mdDoc ''
            The launch command type. Should be initialize.
          '';
        };

        type = mkOption {
          type = types.str;
          default = "request";
          description = lib.mdDoc ''
            Type of the message. Usually 'request'.
          '';
        };

        arguments = mkOption {
          type = types.anything;
          description = lib.mdDoc ''
            This object should be based on InitializeRequestArguments of the DAP spec:
            https://microsoft.github.io/debug-adapter-protocol/specification
          '';
        };
      };

      launchMessage = {
        command = mkOption {
          type = types.str;
          description = lib.mdDoc ''
            The launch command type. One of launch and attach.
          '';
        };

        type = mkOption {
          type = types.str;
          default = "request";
          description = lib.mdDoc ''
            Type of the message. Usually request.
          '';
        };

        arguments = mkOption {
          # The doc is very underspecified wrt this. I think this is specific to the DAP adapter you use.
          # LaunchRequestArguments in https://microsoft.github.io/debug-adapter-protocol/specification
          type = types.anything;
          description = lib.mdDoc ''
            A set of attributes to send as the arguments of the launch request.
          '';
        };
      };
    } // fileTypeAttrs;
  };

  packagerModule = { ... }: {
    options = {

      name = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The name of the packager.
        '';
      };

      language = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The language this packager supports.
        '';
      };

      ignoredPackages = mkOption {
        type = types.listOf (types.str);
        description = lib.mdDoc ''
          Packages for UPM to ignore when guessing.
        '';
        default = [ ];
      };

      ignoredPaths = mkOption {
        type = types.listOf (types.str);
        description = lib.mdDoc ''
          Paths for UPM to ignore when guessing.
        '';
        default = [ ];
      };

      env = mkOption {
        type = types.attrsOf (types.str);
        default = { };
        description = lib.mdDoc ''
          Environment variables to set for UPM.
        '';
      };

      afterInstall = mkOption {
        type = types.nullOr commandType;
        default = null;
        description = lib.mdDoc ''
          Command to execute after install.
        '';
      };

      features = {
        enabledForHosting = mkOption {
          type = types.bool;
          description = lib.mdDoc ''
            If false, packager will assume the libraries have been installed in replspace.
          '';
        };

        packageSearch = mkOption {
          type = types.bool;
          description = lib.mdDoc ''
            Whether package search is supported for this language.
          '';
        };

        guessImports = mkOption {
          type = types.bool;
          description = lib.mdDoc ''
            Whether package guesser is supported for this language.
          '';
        };
      };
    };
  };

  envWithMergedPath = (env: packagesPath:
    if builtins.hasAttr "PATH" env
    then env // { PATH = env.PATH + ":" + packagesPath; }
    else { PATH = packagesPath; } // env
  );

  stripAttrsWithDefaultValues = (attrset: options: attrsToStrip:
    let attrs = lib.attrsets.mapAttrsToList (attr: value: attr) attrset;
    in
    foldr
      (attr: acc:
        let defaultValue = options.${attr}.default;
        in
        if builtins.elem attr attrsToStrip then
          (if defaultValue == attrset.${attr} then
            builtins.removeAttrs attrset [ attr ]
          else
            acc)
        else acc
      )
      attrset
      attrs
  );

  replitOptions = {
    packages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "The set of packages to appear in the repl.";
    };

    initializers = mkOption {
      type = types.attrsOf (types.submodule initializerModule);
      default = { };
      description = lib.mdDoc ''
        A set of initializers provided by the module.
      '';
    };

    runners = mkOption {
      type = types.attrsOf (types.submodule runnerModule);
      default = { };
      description = lib.mdDoc ''
        A set of runners provided by the module.
      '';
    };

    packagers = mkOption {
      type = types.attrsOf (types.submodule packagerModule);
      default = { };
      description = lib.mdDoc ''
        A set of packager configuration settings for UPM.
      '';
    };

    debuggers = mkOption {
      type = types.attrsOf (types.submodule debuggerModule);
      default = { };
      description = lib.mdDoc ''
        A set of debuggers provided by the module.
      '';
    };

    formatters = mkOption {
      type = types.attrsOf (types.submodule formatterModule);
      default = { };
      description = lib.mdDoc ''
        A set of formatters provided by the module.
      '';
    };

    languageServers = mkOption {
      type = types.attrsOf (types.submodule languageServerModule);
      default = { };
      description = lib.mdDoc ''
        A set language servers provided by the module.
      '';
    };

    env = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = lib.mdDoc ''
        A set of environment variables to export.
      '';
    };
  };

in

{
  options = {
    id = mkOption {
      type = types.str;
      description = "ID of the module";
    };

    name = mkOption {
      type = types.str;
      description = "Name of the module";
    };

    community-version = mkOption {
      type = types.str;
      description = "Community version - the version of the runtime or compiler provided by this module";
    };

    description = mkOption {
      type = types.str;
      description = "Description of the module";
      default = "";
    };

    replit = replitOptions // {
      dev = replitOptions;
    } // {
      builtPackages = mkOption {
        internal = true;
      };

      buildModule = mkOption {
        internal = true;
      };

      buildDeploymentModule = mkOption {
        internal = true;
      };

      configJSON = mkOption {
        internal = true;
      };

    };
  };

  config = {

    replit.builtPackages = pkgs.buildEnv {
      name = "module-env";
      paths = config.packages;
    };

    replit.buildModule =
      let
        allPackages = config.replit.packages ++ config.replit.dev.packages;
        allRunners = config.replit.runners // config.replit.dev.runners;
        verifiedAllRunners = mapAttrs
          (id: runner:
            # Make sure only one of fileParam or optionFileParam is used
            assert !(runner.fileParam && runner.optionalFileParam);
            stripAttrsWithDefaultValues runner runnerOptions [ "optionalFileParam" ]
          )
          allRunners;
        allEnv = config.replit.env // config.replit.dev.env;
        allInitializers = config.replit.initializers // config.replit.dev.initializers;
        allPackagers = config.replit.packagers // config.replit.dev.packagers;
        allDebuggers = config.replit.debuggers // config.replit.dev.debuggers;
        allFormatters = config.replit.formatters // config.replit.dev.formatters;
        allLanguageServers = config.replit.languageServers // config.replit.dev.languageServers;
        moduleJSON = {
          id = config.id;
          name = config.name;
          community-version = config.community-version;
          description = config.description;
          env = envWithMergedPath allEnv (lib.makeBinPath allPackages);
          initializers = allInitializers;
          runners = verifiedAllRunners;
          packagers = allPackagers;
          debuggers = allDebuggers;
          formatters = allFormatters;
          languageServers = allLanguageServers;
        };

      in
      pkgs.writeText "replit-module-${config.id}" (builtins.toJSON moduleJSON);

    replit.buildDeploymentModule =
      let
        runners = mapAttrs
          (id: runner:
            # Make sure only one of fileParam or optionFileParam is used
            assert !(runner.fileParam && runner.optionalFileParam);
            stripAttrsWithDefaultValues runner runnerOptions [ "optionalFileParam" ]
          )
          config.replit.runners;
        moduleJSON = {
          id = config.id;
          name = config.name;
          community-version = config.community-version;
          description = config.description;
          env = envWithMergedPath config.replit.env (lib.makeBinPath config.replit.packages);
          initializers = config.replit.initializers;
          inherit runners;
          packagers = config.replit.packagers;
          debuggers = config.replit.debuggers;
          formatters = config.replit.formatters;
          languageServers = config.replit.languageServers;
        };

      in
      pkgs.writeText "replit-deployment-module-${config.id}" (builtins.toJSON moduleJSON);
  };
}
