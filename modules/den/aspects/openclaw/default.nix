{ den, inputs, ... }:
{
  den.aspects.openclaw = den.lib.callable {
    hjem = { lib, pkgs, ... }: {
      programs.openclaw = {
        config = {
          agents = {
            defaults = {
              model = "openai/gpt-5.6-luna";
              subagents = {
                allowAgents = [
                  "hestia"
                  "metis"
                ];
                maxSpawnDepth = 2;
              };
            };
            entries = {
              artemis = {
                description = "Finds opportunities and tracks companies, applications, contacts, and follow-ups";
                identity.name = "ARTEMIS";
                model = "openai/gpt-5.6-sol";
                subagents.allowAgents = [ ];
                workspace = "~/.openclaw/workspace/artemis";
              };
              hestia = {
                description = "Coordinates birthdays, holidays, and relationship-oriented preparations proactively";
                identity.name = "HESTIA";
                subagents.allowAgents = [ ];
                workspace = "~/.openclaw/workspace/hestia";
              };
              gaia = {
                description = "Personal assistant";
                identity.name = "GAIA";
                workspace = "~/.openclaw/workspace";
              };
              metis = {
                description = "Proactively manages the user's long-term career direction";
                identity.name = "METIS";
                subagents.allowAgents = [ "artemis" ];
                workspace = "~/.openclaw/workspace/metis";
              };
            };
            ownership = "explicit";
          };
          bindings = [
            {
              agentId = "gaia";
              match = {
                accountId = "default";
                channel = "telegram";
              };
            }
          ];
          browser = {
            defaultProfile = "openclaw";
            enabled = true;
            executablePath = "${pkgs.chromium}/bin/chromium";
            headless = false;
          };
          gateway = {
            auth = {
              mode = "token";
              token = {
                id = "OPENCLAW_GATEWAY_TOKEN";
                provider = "default";
                source = "env";
              };
            };
            bind = "loopback";
            mode = "local";
          };
          plugins.entries.workboard.enabled = true;
          skills.workshop.autonomous.mode = "off";
        };
        enable = true;
        workspace.bootstrapFiles = {
          agents = ./gaia/AGENTS.md;
          identity = ./gaia/IDENTITY.md;
          soul = ./gaia/SOUL.md;
          tools = ./gaia/TOOLS.md;
          user = ./gaia/USER.md;
        };
        workspace.files = {
          "artemis/AGENTS.md" = ./artemis/AGENTS.md;
          "hestia/AGENTS.md" = ./hestia/AGENTS.md;
          "hestia/birthdays/AGENTS.md" = ./hestia/birthdays/AGENTS.md;
          "hestia/holidays/AGENTS.md" = ./hestia/holidays/AGENTS.md;
          "metis/AGENTS.md" = ./metis/AGENTS.md;
        };
      };

      systemd.services.openclaw-gateway = {
        serviceConfig = {
          StandardError = lib.mkForce "journal";
          StandardOutput = lib.mkForce "journal";
        };
        wantedBy = [ "default.target" ];
      };
    };

    nixos.nixpkgs.overlays = [ inputs.nix-openclaw.overlays.default ];
  };

  den.default.nixos.hjem.extraModules = [
    inputs.nix-openclaw.homeManagerModules.openclaw
  ];

  flake-file.inputs.nix-openclaw = {
    inputs.home-manager.follows = "home-manager";
    inputs.nix-openclaw-tools.inputs.nixpkgs.follows = "nixpkgs";
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:openclaw/nix-openclaw";
  };
}
