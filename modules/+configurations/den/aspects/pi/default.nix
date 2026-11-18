{ inputs, lib, ... }:

lib.mkMerge [
  {
    flake-file.inputs.hypruse = {
      url = "github:IlyasKhallouki/hypruse";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-file.inputs.pi = {
      url = "github:lukasl-dev/pi.nix";
      inputs = {
        bun2nix.inputs.treefmt-nix.follows = "treefmt-nix";
        bun2nix-x86_64-darwin.inputs = {
          nixpkgs.follows = "nixpkgs";
          treefmt-nix.follows = "treefmt-nix";
        };
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
  }
  {
    den.aspects.pi.hjem =
      { self', ... }:
      let
        promptNames = lib.filter (name: lib.hasSuffix ".md" name) (
          builtins.attrNames (builtins.readDir ./prompts)
        );

        promptFiles = map (name: ./prompts + "/${name}") promptNames;
      in
      {
        imports = [ inputs.pi.homeModules.default ];

        programs.pi.coding-agent = {
          enable = true;
          environment = {
            PI_SKIP_VERSION_CHECK.value = "1";
            PI_TELEMETRY.value = "0";
          };
          extensions = with self'.packages; [
            "${pi-core-skill-tool}/pi-core-skill-tool/index.ts"
            "${pi-diff-review}/pi-diff-review/index.ts"
            "${pi-memory}/pi-memory/index.ts"
            "${pi-ponytail}/pi-ponytail/index.js"
            "${pi-permission-modes}/pi-permission-modes/index.ts"
            "${pi-prompt-timer}/pi-prompt-timer/index.ts"
            "${pi-self-compact}/pi-self-compact/index.ts"
            "${pi-web-access}/pi-web-access/index.ts"
            "${pi-session}/pi-session/index.ts"
          ];
          settings = {
            defaultTools = [ "+codemode" ];
            prompts = promptFiles;
          };
        };
      };
  }
  {
    den.aspects.pi.firefox.hjem =
      { self', ... }:
      {
        programs.pi.coding-agent = {
          environment.FIREFOX_AGENT_BRIDGE_BROWSER.value = "${self'.packages.firefox-agent-bridge}/bin/browser";
          extensions = with self'.packages; [
            "${pi-firefox-bridge}/pi-firefox-bridge/index.ts"
          ];
        };
      };
  }
  {
    den.aspects.pi.herdr.hjem =
      { config, pkgs, ... }:
      let
        herdrSkill =
          pkgs.runCommand "herdr-skill" { nativeBuildInputs = [ config.programs.herdr.package ]; }
            ''
              mkdir -p "$out/herdr"
              herdr --skill > "$out/herdr/SKILL.md"
            '';
      in
      {
        programs.pi.coding-agent.skills = [ "${herdrSkill}/herdr" ];
      };
  }
  {
    den.aspects.pi.hyperland.hjem =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [
          inputs.hypruse.homeModules.default
        ];

        programs.hypruse = {
          enable = true;
          package = pkgs.hypruse;

          env = {
            HYPRUSE_BACKGROUND = "1";
          };
        };

        programs.pi.coding-agent.mcp.mcpServers.hypruse = {
          command = lib.getExe config.programs.hypruse.package;
          env = config.programs.hypruse.env;
        };
      };
  }
]
