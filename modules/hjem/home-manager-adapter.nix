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

  adapter =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      fileType = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }: {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };

              executable = lib.mkOption {
                type = lib.types.nullOr lib.types.bool;
                default = null;
              };

              force = lib.mkOption {
                type = lib.types.bool;
                default = false;
              };

              source = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
              };

              target = lib.mkOption {
                type = lib.types.str;
                default = name;
              };

              text = lib.mkOption {
                type = lib.types.nullOr lib.types.lines;
                default = null;
              };
            };
          }
        )
      );

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
        config.home.file
        // prefixFiles ".cache" config.xdg.cacheFile
        // prefixFiles ".config" config.xdg.configFile
        // prefixFiles ".local/share" config.xdg.dataFile
        // prefixFiles ".local/state" config.xdg.stateFile;

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

            export HOME=${lib.escapeShellArg config.home.homeDirectory}
            export USER=${lib.escapeShellArg config.home.username}
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

      activationServices =
        lib.mapAttrs'
          (name: node: {
            name = "home-manager-adapter-${name}";
            value = activationService name node;
          })
          (
            removeAttrs config.home.activation [
              "checkLinkTargets"
              "installPackages"
              "linkGeneration"
              "reloadSystemd"
              "writeBoundary"
            ]
          );

      hasActivation = activationServices != { };
    in
    {
      options = {
        home = {
          activation = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };

          file = lib.mkOption {
            type = fileType;
            default = { };
          };

          homeDirectory = lib.mkOption {
            type = lib.types.str;
            default = config.directory;
          };

          packages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
          };

          sessionVariables = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };

          stateVersion = lib.mkOption {
            type = lib.types.str;
            default = "26.11";
          };

          username = lib.mkOption {
            type = lib.types.str;
            default = config.user;
          };
        };

        launchd.agents = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
        };

        systemd.activationTargets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };

        systemd.user = {
          paths = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };

          services = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };

          sockets = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };

          systemctlPath = lib.mkOption {
            type = lib.types.str;
            default = "${pkgs.systemd}/bin/systemctl";
          };

          targets = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };

          timers = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
        };

        xdg = {
          cacheFile = lib.mkOption {
            type = fileType;
            default = { };
          };

          cacheHome = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/.cache";
          };

          configFile = lib.mkOption {
            type = fileType;
            default = { };
          };

          configHome = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/.config";
          };

          dataFile = lib.mkOption {
            type = fileType;
            default = { };
          };

          dataHome = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/.local/share";
          };

          stateFile = lib.mkOption {
            type = fileType;
            default = { };
          };

          stateHome = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/.local/state";
          };
        };
      };

      config = {
        files = lib.mapAttrs mapFile (lib.filterAttrs (_: file: file.enable) hmFiles);
        packages = config.home.packages;

        systemd = {
          activationTargets = lib.mkIf hasActivation [ "home-manager-adapter.target" ];
          paths = lib.mapAttrs (_: mapUnit) config.systemd.user.paths;
          services = lib.mapAttrs (_: mapUnit) config.systemd.user.services // activationServices;
          sockets = lib.mapAttrs (_: mapUnit) config.systemd.user.sockets;
          targets =
            lib.mapAttrs (_: mapUnit) config.systemd.user.targets
            // lib.optionalAttrs hasActivation {
              home-manager-adapter.description = "Home Manager adapter";
            };
          timers = lib.mapAttrs (_: mapUnit) config.systemd.user.timers;
        };
      };
    };
in
{
  den.default.nixos.hjem = {
    extraModules = [ adapter ];
    specialArgs.lib = hmLib;
  };

}
