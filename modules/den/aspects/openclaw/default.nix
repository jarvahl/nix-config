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
                allowAgents = [ "career" ];
                maxSpawnDepth = 2;
              };
            };
            entries = {
              assistant = {
                description = "Personal assistant";
                identity.name = "Assistant";
                workspace = "~/.openclaw/workspace";
              };
              career = {
                description = "Proactively manages the user's long-term career direction";
                identity.name = "Career";
                subagents.allowAgents = [ "recruiter" ];
                workspace = "~/.openclaw/workspace/career";
              };
              recruiter = {
                description = "Finds opportunities and tracks companies, applications, contacts, and follow-ups";
                identity.name = "Recruiter";
                model = "openai/gpt-5.6-sol";
                subagents.allowAgents = [ ];
                workspace = "~/.openclaw/workspace/recruiter";
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
          "career/AGENTS.md" = ./career/AGENTS.md;
          "recruiter/AGENTS.md" = ./recruiter/AGENTS.md;
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
