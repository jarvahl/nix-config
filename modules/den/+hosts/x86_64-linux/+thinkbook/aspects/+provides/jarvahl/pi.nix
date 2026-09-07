{ inputs, ... }:
{
  den.aspects.thinkbook.provides.jarvahl = {
    hjem = { pkgs, ... }:
      let
        piCaveman = pkgs.fetchFromGitHub {
          owner = "v2nic";
          repo = "pi-caveman";
          rev = "2480692ffabddc3d1efec8eb822e664ff7e0e5ef";
          hash = "sha256-J9Kbvp6Ln3W8QIwCIzC6E6MjeyZqCU2ucYPSUrsmJg0=";
        };

        piThemes = pkgs.fetchFromGitHub {
          owner = "bacnh85";
          repo = "pi-extensions";
          rev = "0b8ad8a18076c5e76d831358987a3362cd49a155";
          hash = "sha256-vaJ+8PGWY6w7+IX4OyGxfOPbNNGj+WkdUEm2JJ2hMt8=";
        };

        ponytail = pkgs.fetchFromGitHub {
          owner = "DietrichGebert";
          repo = "ponytail";
          rev = "356918eba965ee1eac64bd3a7f0dd02108350de5";
          hash = "sha256-LPNMyHsri3+eeDmphEAKL1JgoRE4dLIPfZ4XZ+xu5UY=";
        };

        piZentui = pkgs.fetchFromGitHub {
          owner = "lmilojevicc";
          repo = "pi-zentui";
          rev = "49dc724ce3f801dd243bb9dd420f3d3b90c3f13b";
          hash = "sha256-tu+m1UIBg09+RiqKBRxokJQy4g00Sckq/NmfVrMDxZE=";
        };

        piMcpAdapter = pkgs.buildNpmPackage {
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

        pi = pkgs.writeShellApplication {
          name = "pi";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.rtk
          ];
          text = ''
            config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/pi"
            state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/pi"

            export PI_CODING_AGENT_DIR="$config_dir"
            export PI_SKIP_VERSION_CHECK=1
            export PI_TELEMETRY=0

            mkdir -p "$state_dir/sessions"

            pi_args=(
              --session-dir "$state_dir/sessions"
              --tui-mode fullscreen

              # RTK
              --extension "${pkgs.rtk.src}/hooks/pi/rtk.ts"

              # Zentui
              --extension "${piZentui}/extensions/zentui"

              # Caveman
              --extension "${piCaveman}/extensions/caveman/index.ts"
              --skill "${piCaveman}/skills/caveman"

              # Ponytail
              --extension "${ponytail}/pi-extension/index.js"
              --skill "${ponytail}/skills"

              # MCP adapter
              --extension "${piMcpAdapter}/index.ts"
              --skill "${piMcpAdapter}/skills"

              # Themes
              --theme "${piThemes}/pi-themes/themes"
            )

            exec ${pkgs.pi-coding-agent}/bin/pi "''${pi_args[@]}" "$@"
          '';
        };
      in
      {
        packages = [ pi ];

        files.".config/pi/zentui.json".text = builtins.toJSON {
          components = {
            editor = {
              enabled = true;
              style = "opencode";
            };
            userMessages = {
              enabled = true;
              style = "compact";
            };
            thinkingSteps = {
              enabled = false;
              mode = "tree";
            };
            workingLine.enabled = false;
            footer.style = "starship";
          };
          icons.mode = "auto";
        };
      };

    nixos.nixpkgs.overlays = [ inputs.pi.overlays.default ];
  };
}
