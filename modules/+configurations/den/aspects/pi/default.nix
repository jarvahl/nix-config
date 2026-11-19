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
      {
        imports = [ inputs.pi.homeModules.default ];

        files.".pi/agent/APPEND_SYSTEM.md".text = ''
          ## Tool-use policy

          Use `codemode` exclusively for every tool call. Do not call individual tools directly.
          Use Codemode to batch independent calls and to chain dependent calls when needed.
        '';

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
          skills =
            let
              skillFiles = ((inputs.import-tree.initFilter (_: true)).match ".*/SKILL\\.md").leaves ./skills;
            in
            map builtins.dirOf skillFiles;
          settings = {
            defaultTools = [ "+codemode" ];
            prompts = (
              (inputs.import-tree.initFilter (path: lib.hasSuffix ".md" (toString path))).leaves ./prompts
            );
          };
        };
      };
  }
  {
    den.aspects.pi.firefox.hjem =
      { self', ... }:
      {
        programs.pi.coding-agent.mcp.mcpServers.firefox = {
          command = "${self'.packages.firefox-agent-mcp}/bin/firefox-agent-mcp";
          env.FIREFOX_AGENT_BRIDGE_BROWSER = "${self'.packages.firefox-agent-bridge}/bin/browser";
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

          env = { };
        };

        programs.pi.coding-agent.mcp.mcpServers.hypruse = {
          command = lib.getExe config.programs.hypruse.package;
          env = config.programs.hypruse.env;
        };
      };
  }
]
