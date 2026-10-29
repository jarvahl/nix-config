{ checkedPath, lib, ... }:
lib.mkMerge [
  {
    flake-file.inputs.home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };
  }
  {
    agent-files.skills.home-manager = {
      description = "Use when configuring Home Manager modules through Hjem or registering external homeModules; not for standalone Home Manager setups.";
      instructions = { references, ... }: ''
        # Home Manager modules in Hjem

        This repository includes an adapter that allows Home Manager modules to be used by Hjem.

        To integrate an external Home Manager module:

        1. Add its flake input.
        2. Register its `homeModules.default` in `den.default.nixos.hjem.extraModules`.
        3. Configure its native Home Manager options inside the relevant `hjem` aspect.

        Use `${checkedPath ./den/aspects/nvim/default.nix}` as the reference; upstream export names may differ.

        ## Routing

        | Task | Read |
        | --- | --- |
        | Registering or configuring an external module | Use the steps above |
        | Bridging missing Home Manager options to Hjem Rum | `${references.compatibility}` |
      '';
      references.compatibility = {
        description = "Home Manager compatibility in Hjem";
        text = ''
          # Home Manager compatibility in Hjem

          When an external module reads a Home Manager option implemented by Hjem Rum,
          register an alias globally in `den.default.nixos.hjem.extraModules`:

          ```nix
          den.default.nixos.hjem.extraModules = [
            ({ lib, ... }: {
              imports = [
                (lib.mkAliasOptionModule
                  [ "programs" "git" "enable" ]
                  [ "rum" "programs" "git" "enable" ]
                )
              ];
            })
          ];
          ```

          Keep this adapter next to the program's aspect, not in each consuming application.
          The alias is available globally; the program's aspect decides whether to enable it.
          Do not add dummy options with fixed defaults when a real backend option exists.
          Alias individual options with compatible types, not an entire option namespace.

          For adapters that also merge configuration, preserve ordering and package selection.
          See `${checkedPath ./den/aspects/zsh.nix}`: `lib.mkBefore` places bundle initialization
          before the aliased `initContent`; package wiring remains conditional on enablement.
          Keep host/user side effects, such as selecting a login shell, in explicit aspects.

          Verify both an enabled and a disabled consumer, and evaluate configuration ordering
          when the adapter merges initialization text. Run `nix flake check --no-build`.
        '';
      };
    };
  }
]
