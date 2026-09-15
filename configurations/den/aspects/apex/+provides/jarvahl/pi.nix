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
      let
        caveman = pkgs.fetchFromGitHub {
          owner = "v2nic";
          repo = "pi-caveman";
          rev = "2480692ffabddc3d1efec8eb822e664ff7e0e5ef";
          hash = "sha256-J9Kbvp6Ln3W8QIwCIzC6E6MjeyZqCU2ucYPSUrsmJg0=";
        };

        ponytail = pkgs.fetchFromGitHub {
          owner = "DietrichGebert";
          repo = "ponytail";
          rev = "356918eba965ee1eac64bd3a7f0dd02108350de5";
          hash = "sha256-LPNMyHsri3+eeDmphEAKL1JgoRE4dLIPfZ4XZ+xu5UY=";
        };

        mcpAdapter = pkgs.buildNpmPackage {
          pname = "pi-mcp-adapter";
          version = "2.32.1";
          src = pkgs.fetchFromGitHub {
            owner = "nicobailon";
            repo = "pi-mcp-adapter";
            rev = "8243eba3421e301c88c047444f34ab7d5d57163e";
            hash = "sha256-Z+Nc7aQJFnZKYAe6yQN0CFwYuekNahAcFRg+dDBpRVU=";
          };
          npmDepsHash = "sha256-MtDyee9eaqjc8m6f1Qqt+SEVBBme5doB9lBCb5FXzDk=";
          npmInstallFlags = [ "--omit=dev" ];
          postPatch = ''
            lockfile=$(mktemp)
            ${pkgs.jq}/bin/jq \
              'del(.packages[] | select(.dev == true)) | del(.packages[""].devDependencies)' \
              package-lock.json > "$lockfile"
            mv "$lockfile" package-lock.json
            ${pkgs.jq}/bin/jq 'del(.devDependencies)' package.json > "$lockfile"
            mv "$lockfile" package.json
          '';
          dontNpmBuild = true;
          installPhase = ''
            mkdir -p $out
            cp -r . $out
          '';
        };
      in
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
            pi-plan = "${inputs.pi-plan.packages.${pkgs.system}.default}/index.ts";
            caveman = "${caveman}/extensions/caveman/index.ts";
            ponytail = "${ponytail}/pi-extension/index.js";
            mcp-adapter = "${mcpAdapter}/index.ts";
            zentui = "${pkgs.pi-zentui}/extensions/zentui";
          };

          skills = {
            caveman = "${caveman}/skills/caveman";
            ponytail = "${ponytail}/skills";
            mcp-adapter = "${mcpAdapter}/skills";
          };
        };
      };

    nixos = {
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
    pi-plan.url = "github:jarvahl/pi-plan";

    # Pi
    pi.url = "github:lukasl-dev/pi.nix";
  };
}
