{ inputs, ... }:
let
  piCodingAgentOverlay = _final: prev: {
    pi-coding-agent = prev.pi-coding-agent.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        settings_manager=packages/coding-agent/src/core/settings-manager.ts
        substituteInPlace "$settings_manager" \
          --replace-fail \
            'return this.settings.quietStartup ?? false;' \
            'return this.settings.quietStartup ?? process.env.PI_QUIET_STARTUP === "1";'
      '';
    });
  };
in
{
  den.aspects.apex.provides.jarvahl = {
    hjem = { pkgs, ... }:
      {
        programs.mcp = {
          enable = true;

          servers = {
            nixos = {
              command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
              lifecycle = "lazy";
            };

            "n8n-mcp" = {
              type = "http";
              url = "http://localhost:5678/mcp-server/http";
              bearerToken =
                "!cat /run/secrets/users/jarvahl/n8n/mcp/token";
            };
          };
        };

        programs.pi = {
          enable = true;

          environment.PI_QUIET_STARTUP = "1";
          extraPackages = [ pkgs.rtk ];

          extensions = {
            rtk = "${pkgs.rtk.src}/hooks/pi/rtk.ts";
            caveman = "${pkgs.pi.extensions.pi-caveman}/extensions/caveman/index.ts";
            ponytail = "${pkgs.pi.extensions.pi-ponytail}/pi-extension/index.js";
            mcp-adapter = "${pkgs.pi.extensions.pi-mcp-adapter}/index.ts";
            subagent = "${pkgs.pi.extensions.pi-subagent}/extensions/index.ts";
            zentui = "${pkgs.pi.extensions.pi-zentui}/extensions/zentui";
          };

          skills = {
            caveman = "${pkgs.pi.extensions.pi-caveman}/skills/caveman";
            ponytail = "${pkgs.pi.extensions.pi-ponytail}/skills";
            mcp-adapter = "${pkgs.pi.extensions.pi-mcp-adapter}/skills";
          };
        };
      };

    nixos = { ... }:
      {
        sops.secrets."users/jarvahl/n8n/mcp/token" = {
          owner = "jarvahl";
          mode = "0400";
        };

        nixpkgs.overlays = [
          inputs.pi.overlays.default
          piCodingAgentOverlay
          inputs.mcp-nixos.overlays.default
        ];
      };
  };

  flake-file.inputs = {
    # Pi plugins
    mcp-nixos.url = "github:utensils/mcp-nixos";

    # Pi
    pi.url = "github:lukasl-dev/pi.nix";
  };
}
