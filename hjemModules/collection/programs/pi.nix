{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pi;

  extensionPaths = map (extension: toString extension.source) (lib.attrValues cfg.extensions);

  extensionSkills = lib.mapAttrs'
    (name: extension:
      lib.nameValuePair name extension.skill.source
    )
    (lib.filterAttrs (_: extension: extension.skill != null) cfg.extensions);

  skillPaths = map toString (lib.attrValues (extensionSkills // cfg.skills));

  settings = cfg.settings // {
    extensions = (cfg.settings.extensions or [ ]) ++ extensionPaths;
    skills = (cfg.settings.skills or [ ]) ++ skillPaths;
  };

  pi = pkgs.writeShellApplication {
    name = "pi";
    runtimeInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.tmux
    ] ++ cfg.extraPackages;
    text = ''
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/pi"

      export PI_SKIP_VERSION_CHECK=1
      export PI_TELEMETRY=0
      ${lib.concatMapStringsSep "\n" (name: "export ${name}=${lib.escapeShellArg cfg.environment.${name}}") (lib.attrNames cfg.environment)}

      mkdir -p "$state_dir/sessions"

      pi_args=(
        --session-dir "$state_dir/sessions"
        --tui-mode fullscreen
      )

      exec ${cfg.package}/bin/pi "''${pi_args[@]}" "$@"
    '';
  };
in
{
  options.programs.pi = {
    enable = lib.mkEnableOption "Pi coding agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pi-coding-agent;
      description = "Pi coding agent package to use.";
    };

    mcp.servers = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "MCP servers configured for Pi extensions.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Pi agent settings.json contents.";
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Skills passed to Pi.";
    };

    extensions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          source = lib.mkOption {
            type = lib.types.path;
            description = "Extension source passed to Pi.";
          };

          skill = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule {
              options.source = lib.mkOption {
                type = lib.types.path;
                description = "Skill source provided by this extension.";
              };
            });
            default = null;
            description = "Optional skill provided by this extension.";
          };
        };
      });
      default = { };
      description = "Extensions and their optional skills.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Environment variables passed to Pi.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages available to Pi extensions and skills.";
    };

    theme = lib.mkOption {
      type = lib.types.path;
      default = "${pkgs.pi.themes}/pi-themes/themes";
      description = "Theme directory passed to Pi.";
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [ pi ];

    files = {
      ".pi/agent/mcp.json".text = builtins.toJSON {
        mcpServers = cfg.mcp.servers;
      };

      ".pi/agent/settings.json".text = builtins.toJSON settings;
      ".pi/agent/themes".source = cfg.theme;
    };
  };
}
