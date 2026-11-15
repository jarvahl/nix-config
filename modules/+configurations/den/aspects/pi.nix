{ inputs, ... }:

{
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

  den.aspects.pi.hjem =
    { self', ... }:
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
          "${pi-memory}/pi-memory/dist/extensions/memory/index.js"
          "${pi-memory}/pi-memory/dist/extensions/skill-evolution/index.js"
          "${pi-ponytail}/pi-ponytail/index.js"
          "${pi-prompt-timer}/pi-prompt-timer/index.ts"
          "${pi-self-compact}/pi-self-compact/index.ts"
          "${pi-web-access}/pi-web-access/index.ts"
          "${pi-session}/pi-session/index.ts"
        ];
        skills = with self'.packages; [ "${pi-memory}/pi-memory/skills" ];
      };
    };
}
