{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pi;

  pi = pkgs.writeShellApplication {
    name = "pi";
    runtimeInputs = [
      pkgs.bash
      pkgs.coreutils
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
        ${lib.concatMapStringsSep "\n" (path: "--extension ${lib.escapeShellArg (toString path)}") (lib.attrValues cfg.extensions)}
        ${lib.concatMapStringsSep "\n" (path: "--skill ${lib.escapeShellArg (toString path)}") (lib.attrValues cfg.skills)}
        --theme ${lib.escapeShellArg (toString cfg.theme)}
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

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Skills passed to Pi.";
    };

    extensions = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Extensions passed to Pi.";
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
  };
}
