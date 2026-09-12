{ inputs, ... }:
{
  den.aspects.apex.provides.jarvahl = {
    hjem = { pkgs, sops, ... }: {
      programs.pi = {
        enable = true;

        extensions = {
          rtk = "${pkgs.rtk.src}/hooks/pi/rtk.ts";
          plan-build = "${pkgs.pi-plan-build}/index.ts";
          caveman = "${pkgs.pi-caveman}/extensions/caveman/index.ts";
          ponytail = "${pkgs.ponytail}/pi-extension/index.js";
          mcp-adapter = "${pkgs.pi-mcp-adapter}/index.ts";
        };

        skills = {
          caveman = "${pkgs.pi-caveman}/skills/caveman";
          ponytail = "${pkgs.ponytail}/skills";
          herdr = "${pkgs.herdr.src}/skills/herdr";
          mcp-adapter = "${pkgs.pi-mcp-adapter}/skills";
        };
      };

      files.".config/mcp/mcp.json".source = sops.templates."pi-mcp.json".path;
    };

    nixos = { config, ... }:
      {
        sops.secrets."users/jarvahl/n8n/mcp/token" = { };

        sops.templates."pi-mcp.json" = {
          owner = "jarvahl";
          mode = "0400";
          content = builtins.toJSON {
            mcpServers = {
              nixos = {
                command = "mcp-nixos";
                lifecycle = "lazy";
              };
              "n8n-mcp" = {
                type = "http";
                url = "http://localhost:5678/mcp-server/http";
                headers.Authorization = "Bearer ${config.sops.placeholder."users/jarvahl/n8n/mcp/token"}";
              };
            };
          };
        };

        nixpkgs.overlays = [
          inputs.pi.overlays.default
          inputs.mcp-nixos.overlays.default
        ];
      };
  };

  flake-file.inputs = {
    mcp-nixos.url = "github:utensils/mcp-nixos";
    pi.url = "github:lukasl-dev/pi.nix";
  };
}
