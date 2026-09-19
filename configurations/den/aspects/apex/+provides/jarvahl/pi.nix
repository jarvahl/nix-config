{ inputs, ... }:
let
  piCodingAgentOverlay = _final: prev: {
    pi-coding-agent-patched = prev.pi-coding-agent.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        (prev.writeText "pi-quiet-startup.patch" ''
          --- a/packages/coding-agent/src/core/settings-manager.ts
          +++ b/packages/coding-agent/src/core/settings-manager.ts
          @@ -956,7 +956,7 @@
          	}

          	getQuietStartup(): boolean {
          -		return this.settings.quietStartup ?? false;
          +		return this.settings.quietStartup ?? process.env.PI_QUIET_STARTUP === "1";
          	}

          	setQuietStartup(quiet: boolean): void {
          --- a/packages/coding-agent/src/modes/interactive/interactive-mode.ts
          +++ b/packages/coding-agent/src/modes/interactive/interactive-mode.ts
          @@ -1210,6 +1210,11 @@
          	 * Only shows new entries since last seen version, skips for resumed sessions.
          	 */
          	private getChangelogForDisplay(): string | undefined {
          +		if (this.settingsManager.getQuietStartup()) {
          +			this.settingsManager.setLastChangelogVersion(VERSION);
          +			return undefined;
          +		}
          +
          		// Skip changelog for resumed/continued sessions (already have messages)
          		if (this.session.state.messages.length > 0) {
          			return undefined;
        '')
      ];
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
          package = pkgs.pi-coding-agent-patched;

          environment.PI_QUIET_STARTUP = "1";
          extraPackages = [ pkgs.rtk ];

          extensions = {
            rtk = "${pkgs.rtk.src}/hooks/pi/rtk.ts";
            caveman = "${pkgs.pi.extensions.pi-caveman}/extensions/caveman/index.ts";
            ponytail = "${pkgs.pi.extensions.pi-ponytail}/pi-extension/index.js";
            mcp-adapter = "${pkgs.pi.extensions.pi-mcp-adapter}/index.ts";
            skill-orchestrator = "${pkgs.pi.extensions.pi-skill-orchestrator}/src/index.ts";
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
