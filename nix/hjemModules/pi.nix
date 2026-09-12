{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pi;

  piCodingAgent = pkgs.pi-coding-agent.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      settings_manager=packages/coding-agent/src/core/settings-manager.ts
      substituteInPlace "$settings_manager" \
        --replace-fail \
          'return this.settings.quietStartup ?? false;' \
          'return this.settings.quietStartup ?? process.env.PI_QUIET_STARTUP === "1";'
    '';
  });

  pi = pkgs.writeShellApplication {
    name = "pi";
    runtimeInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.mcp-nixos
      pkgs.herdr
      pkgs.rtk
    ];
    text = ''
      config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/pi"
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/pi"

      export PI_CODING_AGENT_DIR="$config_dir"
      export PI_SKIP_VERSION_CHECK=1
      export PI_TELEMETRY=0
      export PI_QUIET_STARTUP=1

      mkdir -p "$state_dir/sessions"

      pi_args=(
        --session-dir "$state_dir/sessions"
        --tui-mode fullscreen
        ${lib.concatMapStringsSep "\n" (path: "--extension ${lib.escapeShellArg (toString path)}") (lib.attrValues cfg.extensions)}
        ${lib.concatMapStringsSep "\n" (path: "--skill ${lib.escapeShellArg (toString path)}") (lib.attrValues cfg.skills)}
        --theme ${lib.escapeShellArg (toString cfg.theme)}
      )

      exec ${piCodingAgent}/bin/pi "''${pi_args[@]}" "$@"
    '';
  };
in
{
  options.programs.pi = {
    enable = lib.mkEnableOption "Pi coding agent";

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

    theme = lib.mkOption {
      type = lib.types.path;
      default = "${pkgs.pi-themes}/pi-themes/themes";
      description = "Theme directory passed to Pi.";
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [ pi ];
  };
}
