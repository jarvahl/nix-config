{ den, inputs, ... }:
{
  den.aspects.openclaw = den.lib.callable {
    hjem = { lib, pkgs, ... }: {
      programs.openclaw = {
        config = {
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
