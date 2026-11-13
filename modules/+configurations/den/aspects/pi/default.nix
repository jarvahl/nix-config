{ inputs, lib, ... }:

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

  den.aspects.pi =
    {
      name ? "pi",
      extensions ? [ ],
      skills ? [ ],
      rules ? null,
      settings ? { },
      environment ? null,
    }:
    {
      hjem =
        {
          config,
          pkgs,
          self',
          ...
        }:
        let
          resolve = value: if lib.isFunction value then value { inherit config pkgs self'; } else value;
          configuredPi = pkgs.symlinkJoin {
            name = name;
            paths = [
              (inputs.pi.lib.mkCodingAgent {
                inherit pkgs;
                modules = [
                  {
                    pi.coding-agent = {
                      extensions =
                        with self'.packages;
                        [
                          "${pi-core-skill-tool}/pi-core-skill-tool/index.ts"
                          "${pi-memory}/pi-memory/dist/extensions/memory/index.js"
                          "${pi-memory}/pi-memory/dist/extensions/skill-evolution/index.js"
                          "${pi-self-compact}/pi-self-compact/index.ts"
                          "${pi-web-access}/pi-web-access/index.ts"
                          "${pi-session}/pi-session/index.ts"
                        ]
                        ++ resolve extensions;
                      environment = {
                        PI_SKIP_VERSION_CHECK.value = "1";
                        PI_TELEMETRY.value = "0";
                      }
                      // (if environment == null then { } else resolve environment);
                      rules = resolve rules;
                      settings = resolve settings;
                      skills = with self'.packages; [ "${pi-memory}/pi-memory/skills" ] ++ resolve skills;
                    };
                  }
                ];
              }).package
            ];
          };
        in
        {
          packages = [ configuredPi ];
        };
    };

}
