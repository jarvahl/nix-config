{ inputs, ... }:
{
  den.aspects.apex.provides.jarvahl = {
    hjem = { pkgs, ... }:
      let
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

              # RTK
              --extension "${pkgs.rtk.src}/hooks/pi/rtk.ts"

              # Zentui
              --extension "${pkgs.pi-zentui}/extensions/zentui"

              # Caveman
              --extension "${pkgs.pi-caveman}/extensions/caveman/index.ts"
              --skill "${pkgs.pi-caveman}/skills/caveman"

              # Ponytail
              --extension "${pkgs.ponytail}/pi-extension/index.js"
              --skill "${pkgs.ponytail}/skills"

              # MCP adapter
              --extension "${pkgs.pi-mcp-adapter}/index.ts"
              --skill "${pkgs.pi-mcp-adapter}/skills"

              # Themes
              --theme "${pkgs.pi-themes}/pi-themes/themes"
            )

            exec ${piCodingAgent}/bin/pi "''${pi_args[@]}" "$@"
          '';
        };
      in
      {
        packages = [ pi ];

        files.".config/mcp/mcp.json".text = builtins.toJSON {
          mcpServers.nixos = {
            command = "mcp-nixos";
            lifecycle = "lazy";
          };
        };

        files.".config/pi/zentui.json".text = builtins.toJSON {
          components = {
            editor = {
              enabled = true;
              style = "opencode";
            };
            userMessages = {
              enabled = true;
              style = "compact";
            };
            thinkingSteps = {
              enabled = false;
              mode = "tree";
            };
            workingLine.enabled = false;
            footer.style = "starship";
          };
          icons.mode = "auto";
        };
      };

    nixos.nixpkgs.overlays = [
      inputs.pi.overlays.default
      inputs.mcp-nixos.overlays.default
    ];
  };

  flake-file.inputs.mcp-nixos.url = "github:utensils/mcp-nixos";
}
