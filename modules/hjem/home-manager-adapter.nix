{ lib, ... }:
let
  hmDag = rec {
    empty = { };
    isEntry = entry: entry ? data && entry ? after && entry ? before;
    entryBetween = before: after: data: { inherit after before data; };
    entryAnywhere = entryBetween [ ] [ ];
    entryAfter = entryBetween [ ];
    entryBefore = before: entryBetween before [ ];
  };

  hmLib = lib.extend (_: _: { hm.dag = hmDag; });

  compatOptionsModule =
    { config, lib, ... }:
    let
      types = lib.types;
      mkOpt = type: default: lib.mkOption { inherit type default; };
      anythingAttrs = types.attrsOf types.anything;
      emptyAnythingAttrs = mkOpt anythingAttrs { };

      fileType = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkOpt types.bool true;
              executable = mkOpt (types.nullOr types.bool) null;
              force = mkOpt types.bool false;
              source = mkOpt (types.nullOr types.path) null;
              target = mkOpt types.str name;
              text = mkOpt (types.nullOr types.lines) null;
            };
          }
        )
      );
    in
    {
      options = {
        assertions = mkOpt (types.listOf types.unspecified) [ ];
        warnings = mkOpt (types.listOf types.str) [ ];

        home = {
          activation = emptyAnythingAttrs;
          file = mkOpt fileType { };
          homeDirectory = mkOpt types.str null;
          packages = mkOpt (types.listOf types.package) [ ];
          sessionVariables = emptyAnythingAttrs;
          stateVersion = mkOpt types.str "26.11";
          username = mkOpt types.str null;
        };

        launchd.agents = emptyAnythingAttrs;

        systemd.user =
          lib.genAttrs [
            "paths"
            "services"
            "sockets"
            "targets"
            "timers"
          ] (_: emptyAnythingAttrs)
          // {
            systemctlPath = mkOpt types.str null;
          };

        xdg = {
          cacheFile = mkOpt fileType { };
          cacheHome = mkOpt types.str "${config.home.homeDirectory}/.cache";
          configFile = mkOpt fileType { };
          configHome = mkOpt types.str "${config.home.homeDirectory}/.config";
          dataFile = mkOpt fileType { };
          dataHome = mkOpt types.str "${config.home.homeDirectory}/.local/share";
          stateFile = mkOpt fileType { };
          stateHome = mkOpt types.str "${config.home.homeDirectory}/.local/state";
        };
      };
    };

  mapHomeManagerToHjem =
    {
      hmConfig,
      pkgs,
    }:
    let
      prefixFiles =
        prefix:
        lib.mapAttrs' (
          name: file: {
            name = "${prefix}/${file.target or name}";
            value = file // {
              target = "${prefix}/${file.target or name}";
            };
          }
        );

      hmFiles =
        hmConfig.home.file
        // prefixFiles ".cache" hmConfig.xdg.cacheFile
        // prefixFiles ".config" hmConfig.xdg.configFile
        // prefixFiles ".local/share" hmConfig.xdg.dataFile
        // prefixFiles ".local/state" hmConfig.xdg.stateFile;

      fileSource =
        name: file:
        if file.source != null then
          file.source
        else
          pkgs.writeTextFile {
            name = "home-manager-${lib.replaceStrings [ "/" ] [ "-" ] name}";
            text = file.text or "";
            executable = file.executable == true;
          };

      mapFile = name: file: {
        source = fileSource name file;
        clobber = file.force or false;
      };

      mapUnit =
        unit:
        let
          Unit = unit.Unit or { };
          Install = unit.Install or { };
        in
        {
          description = Unit.Description or null;
          requiredBy = Install.RequiredBy or [ ];
          unitConfig = removeAttrs Unit [ "Description" ];
          wantedBy = Install.WantedBy or [ ];
        }
        // lib.optionalAttrs (unit ? Path) { pathConfig = unit.Path; }
        // lib.optionalAttrs (unit ? Service) { serviceConfig = unit.Service; }
        // lib.optionalAttrs (unit ? Socket) { socketConfig = unit.Socket; }
        // lib.optionalAttrs (unit ? Timer) { timerConfig = unit.Timer; };

      activationNodeScript = node: if builtins.isAttrs node then node.data or node.text or "" else node;

      activationService = name: node: {
        description = "Home Manager adapter unit ${name}";
        wantedBy = [ "home-manager-adapter.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "home-manager-adapter-${name}" ''
            set -euo pipefail

            export HOME=${lib.escapeShellArg hmConfig.home.homeDirectory}
            export USER=${lib.escapeShellArg hmConfig.home.username}
            cd "$HOME"

            hmDriverVersion=1
            VERBOSE_ARG=""
            run() { "$@"; }
            verboseEcho() { echo "$@"; }
            warnEcho() { echo "warning: $*" >&2; }
            errorEcho() { echo "error: $*" >&2; }
            _i() { printf "$@"; printf '\n'; }
            _iNote() { printf "$@"; printf '\n'; }
            _iError() { printf "$@" >&2; printf '\n' >&2; }

            ${activationNodeScript node}
          '';
        };
      };

      skippedActivationNodes = [
        "checkLinkTargets"
        "installPackages"
        "linkGeneration"
        "reloadSystemd"
        "writeBoundary"
      ];

      activationServices = lib.mapAttrs' (name: node: {
        name = "home-manager-adapter-${name}";
        value = activationService name node;
      }) (removeAttrs hmConfig.home.activation skippedActivationNodes);

      hasActivation = activationServices != { };
      mappedSystemdUnits = lib.genAttrs [
        "paths"
        "services"
        "sockets"
        "timers"
      ] (kind: lib.mapAttrs (_: mapUnit) hmConfig.systemd.user.${kind});
    in
    {
      files = lib.mapAttrs mapFile (lib.filterAttrs (_: file: file.enable) hmFiles);
      packages = hmConfig.home.packages;

      systemd = mappedSystemdUnits // {
        services = mappedSystemdUnits.services // activationServices;
        targets =
          lib.mapAttrs (_: mapUnit) hmConfig.systemd.user.targets
          // lib.optionalAttrs hasActivation {
            home-manager-adapter.description = "Home Manager adapter";
          };
      };
    };

  wrap-home-manager-module =
    hmModule:
    { config, pkgs, ... }@args:
    let
      compatOptionNames = [
        "_module"
        "assertions"
        "home"
        "launchd"
        "systemd"
        "warnings"
        "xdg"
      ];

      specialArgs = removeAttrs args [
        "config"
        "lib"
        "options"
      ];

      defaults = {
        home.homeDirectory = lib.mkDefault config.directory;
        home.username = lib.mkDefault config.user;
        systemd.user.systemctlPath = lib.mkDefault "${pkgs.systemd}/bin/systemctl";
      };

      hmOptions = hmLib.evalModules {
        modules = [
          compatOptionsModule
          hmModule
          defaults
        ];

        inherit specialArgs;
      };

      passthroughOptions = removeAttrs hmOptions.options compatOptionNames;

      hm = hmLib.evalModules {
        modules = [
          compatOptionsModule
          hmModule
          defaults
          { config = lib.getAttrs (builtins.attrNames passthroughOptions) config; }
        ];

        inherit specialArgs;
      };
    in
    {
      options = passthroughOptions;
      config = mapHomeManagerToHjem {
        inherit pkgs;
        hmConfig = hm.config;
      };
    };
in
{
  den.default.nixos.hjem.specialArgs = {
    inherit wrap-home-manager-module;
  };
}
