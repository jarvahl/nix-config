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
                          "${pi-memory}/pi-memory/index.ts"
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
                      skills = resolve skills;
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

  agent-files.skills.pi = {
    description = "Use when configuring Pi or adding Pi extensions; not for unrelated coding-agent configuration.";
    instructions =
      { references, ... }:
      ''
        # Pi

        Use this skill for Pi configuration and extensions.

        | Task | Read |\
        | --- | --- |\
        | Adding or updating an extension | `${references.extensions}` |\
      '';
    references.extensions = {
      description = "Pi extensions";
      text = ''
        # Pi extensions

        ## Workflow

        1. Prefer the upstream Git repository over an npm tarball.
        2. Inspect `package.json` to confirm the version and extension entry point.
        3. Pin an immutable commit with `fetchFromGitHub` and record its hash.
        4. Package only the extension files needed at runtime with a small derivation.
           Install the entrypoint as `$out/<pname>/index.ts`; Pi uses this path to display the extension name.
        5. Add the resulting extension path to `programs.pi.coding-agent.extensions`.
        6. Run `nix flake check --no-build` and build the affected derivation when possible.

        Keep extension recipes self-contained under `_pkgs/<package>/package.nix`;
        use plain `stdenvNoCC.mkDerivation` for source-only extensions.

        Use `fetchFromGitHub` for source-only extensions. Use `buildNpmPackage` only when
        runtime dependencies are required, and first verify that the lockfile contains
        complete `resolved` URLs and `integrity` hashes.
      '';
    };
  };
}
