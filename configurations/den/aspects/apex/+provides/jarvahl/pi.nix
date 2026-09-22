{ den, inputs, ... }:
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
        programs.pi = {
          enable = true;
          package = pkgs.pi-coding-agent-patched;

          mcp.servers = {
            nixos = {
              command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
              lifecycle = "lazy";
            };

            "n8n-mcp" = {
              transport = "streamable-http";
              url = "http://localhost:5678/mcp-server/http";
              headers.Authorization =
                "!cat /run/secrets/users/jarvahl/n8n/mcp/token";
              lifecycle = "lazy";
            };
          };

          environment.PI_QUIET_STARTUP = "1";
          environment.PI_BROWSER_USE_EXECUTABLE_PATH =
            "${pkgs.google-chrome}/bin/google-chrome-stable";
          extraPackages = [
            pkgs.computer-use-linux
            pkgs.at-spi2-core
            pkgs.wtype
            pkgs.xdotool
            pkgs.ydotool
          ];

          extensions = {
            caveman = {
              source = "${pkgs.pi.extensions.pi-caveman}/extensions/caveman/index.ts";
              skill.source = "${pkgs.pi.extensions.pi-caveman}/skills/caveman";
            };
            ponytail = {
              source = "${pkgs.pi.extensions.pi-ponytail}/pi-extension/index.js";
              skill.source = "${pkgs.pi.extensions.pi-ponytail}/skills";
            };
            computer-use-linux = {
              source = "${pkgs.computer-use-linux.passthru.pi}/pi/extension/index.ts";
              skill.source = "${pkgs.computer-use-linux.passthru.pi}/skills/computer-use-linux";
            };
            context-mode = {
              source = "${pkgs.context-mode}/build/adapters/pi/extension.js";
              skill.source = "${pkgs.context-mode}/skills";
            };
            mnemosyne = {
              source = "${pkgs.pi-mnemosyne}/src/index.ts";
              skill.source = "${pkgs.pi-mnemosyne}/skills";
            };
            token-killer.source = "${pkgs.pi-token-killer}/index.ts";
            mcp-extension.source = "${pkgs.pi.extensions.pi-mcp-extension}/src/index.ts";
            pi-diff-review.source = "${pkgs.pi.extensions.pi-diff-review}/extensions/review.ts";
            pi-btw.source = "${pkgs.pi.extensions.pi-btw}/dist/index.ts";
            pi-web-search.source = "${pkgs.pi.extensions.pi-web-search}/src/index.ts";
            pi-tmux-alert.source = "${pkgs.pi.extensions.pi-tmux-alert}/index.ts";
            skill-orchestrator.source = "${pkgs.pi.extensions.pi-skill-orchestrator}/src/index.ts";
            subagent.source = "${pkgs.pi.extensions.pi-subagent}/extensions/index.ts";
            zentui.source = "${pkgs.pi.extensions.pi-zentui}/extensions/zentui";
            browser-use.source = "${pkgs.pi.extensions.pi-browser-use}/dist/index.js";
          };

          skills = {
            anthropics = "${pkgs.pi.skills.anthropics}/skills";
            emilkowalski = "${pkgs.pi.skills.emilkowalski}/skills";
            mcp-adapter = "${pkgs.pi.extensions.pi-mcp-adapter}/skills";
          };
        };
      };

    nixos = { ... }:
      {
        programs.ydotool.enable = true;
        users.users.jarvahl.extraGroups = [ "ydotool" ];

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

    includes = [
      (den.batteries.unfree [ "context-mode" ])
    ];
  };

  flake-file.inputs = {
    # Pi plugins
    mcp-nixos.url = "github:utensils/mcp-nixos";

    # Pi
    pi.url = "github:lukasl-dev/pi.nix";
  };
}
