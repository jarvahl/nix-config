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
                  "chronos"
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
              chronos = {
                description = "Coordinates birthdays, holidays, and relationship-oriented preparations proactively";
                identity.name = "CHRONOS";
                subagents.allowAgents = [ ];
                workspace = "~/.openclaw/workspace/chronos";
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
          browser = {
            defaultProfile = "openclaw";
            enabled = true;
            executablePath = "${pkgs.chromium}/bin/chromium";
            headless = true;
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
          skills.workshop.autonomous.mode = "off";
        };
        enable = true;
        workspace.files = {
          "artemis/AGENTS.md" = ./artemis/AGENTS.md;
          "chronos/AGENTS.md" = ./chronos/AGENTS.md;
          "chronos/birthdays/AGENTS.md" = ./chronos/birthdays/AGENTS.md;
          "chronos/holidays/AGENTS.md" = ./chronos/holidays/AGENTS.md;
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
