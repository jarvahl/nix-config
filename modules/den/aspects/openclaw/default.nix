{ den, inputs, ... }:
{
  den.aspects.openclaw = den.lib.callable {
    hjem = { lib, pkgs, ... }: {
      files = {
        ".openclaw/workspace/artemis/AGENTS.md" = {
          source = ./artemis/AGENTS.md;
          type = "copy";
        };
        ".openclaw/workspace/artemis/IDENTITY.md" = {
          source = ./artemis/IDENTITY.md;
          type = "copy";
        };
        ".openclaw/workspace/artemis/SOUL.md" = {
          source = ./artemis/SOUL.md;
          type = "copy";
        };
        ".openclaw/workspace/artemis/USER.md" = {
          source = ./artemis/USER.md;
          type = "copy";
        };
        ".openclaw/workspace/hermes/AGENTS.md" = {
          source = ./hermes/AGENTS.md;
          type = "copy";
        };
        ".openclaw/workspace/hermes/IDENTITY.md" = {
          source = ./hermes/IDENTITY.md;
          type = "copy";
        };
        ".openclaw/workspace/hermes/SOUL.md" = {
          source = ./hermes/SOUL.md;
          type = "copy";
        };
        ".openclaw/workspace/hermes/TOOLS.md" = {
          source = ./hermes/TOOLS.md;
          type = "copy";
        };
        ".openclaw/workspace/hermes/USER.md" = {
          source = ./hermes/USER.md;
          type = "copy";
        };
        ".openclaw/workspace/hestia/AGENTS.md" = {
          source = ./hestia/AGENTS.md;
          type = "copy";
        };
        ".openclaw/workspace/hestia/IDENTITY.md" = {
          source = ./hestia/IDENTITY.md;
          type = "copy";
        };
        ".openclaw/workspace/hestia/SOUL.md" = {
          source = ./hestia/SOUL.md;
          type = "copy";
        };
        ".openclaw/workspace/hestia/USER.md" = {
          source = ./hestia/USER.md;
          type = "copy";
        };
        ".openclaw/workspace/metis/AGENTS.md" = {
          source = ./metis/AGENTS.md;
          type = "copy";
        };
        ".openclaw/workspace/metis/IDENTITY.md" = {
          source = ./metis/IDENTITY.md;
          type = "copy";
        };
        ".openclaw/workspace/metis/SOUL.md" = {
          source = ./metis/SOUL.md;
          type = "copy";
        };
        ".openclaw/workspace/metis/USER.md" = {
          source = ./metis/USER.md;
          type = "copy";
        };
      };
      programs.openclaw = {
        config = {
          agents = {
            defaults = {
              model = "openai/gpt-5.6-luna";
              subagents = {
                allowAgents = [
                  "hestia"
                  "hermes"
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
              gaia = {
                description = "Personal assistant";
                identity.name = "GAIA";
                workspace = "~/.openclaw/workspace";
              };
              hermes = {
                description = "Triages email, prepares drafts, tracks follow-ups, and creates actionable tasks";
                identity.name = "HERMES";
                subagents.allowAgents = [ ];
                tools.agentToAgent.send = [ "gaia" ];
                workspace = "~/.openclaw/workspace/hermes";
              };
              hestia = {
                description = "Coordinates birthdays, holidays, and relationship-oriented preparations proactively";
                identity.name = "HESTIA";
                subagents.allowAgents = [ ];
                workspace = "~/.openclaw/workspace/hestia";
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

      };

      systemd.services.openclaw-gateway = {
        after = [ "openclaw-xvfb.service" ];
        environment.DISPLAY = ":99";
        requires = [ "openclaw-xvfb.service" ];
        serviceConfig = {
          StandardError = lib.mkForce "journal";
          StandardOutput = lib.mkForce "journal";
        };
        wantedBy = [ "default.target" ];
      };

      systemd.services.openclaw-xvfb = {
        serviceConfig = {
          ExecStart = "${pkgs.xorg-server}/bin/Xvfb :99 -screen 0 1920x1080x24 -ac -nolisten tcp";
          Restart = "on-failure";
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
