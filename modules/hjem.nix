{ inputs, lib, ... }:
lib.mkMerge [
  {
    den.default.nixos = {
      hjem.extraModules = [ inputs.hjem-rum.hjemModules.default ];
      imports = [ inputs.hjem-hm-modules.nixosModules.default ];
    };

    flake-file.inputs = {
      hjem = {
        inputs.nixpkgs.follows = "nixpkgs";
        url = "github:feel-co/hjem";
      };
      hjem-hm-modules = {
        inputs = {
          hjem.follows = "hjem";
          nixpkgs.follows = "nixpkgs";
        };
        url = "github:jarvahl/hjem-hm-modules";
      };
      hjem-rum.url = "github:snugnug/hjem-rum";
    };
  }
  {
    agent-files.skills.home-manager = {
      description = "Use when configuring Home Manager modules through Hjem or registering external homeModules; not for standalone Home Manager setups.";
      instructions = ''
        # Home Manager modules in Hjem

        This repository includes an adapter that allows Home Manager modules to be used by Hjem.

        To integrate an external Home Manager module:

        1. Add its flake input.
        2. Register its `homeModules.default` in `den.default.nixos.hjem.extraModules`.
        3. Configure its native Home Manager options inside the relevant `hjem` aspect.

        Use `modules/den/aspects/nvim.nix` as the reference; upstream export names may differ.

        ## Compatibility options

        When an external module reads a Home Manager option implemented by Hjem Rum,
        register `lib.mkAliasOptionModule` in `den.default.nixos.hjem.extraModules`.
        Keep this adapter next to the program's aspect, not in each consuming application.
        The alias is available globally; the program's aspect decides whether to enable it.
        Do not add dummy options with fixed defaults when a real backend option exists.

        See `modules/den/aspects/git.nix` for an enable alias and
        `modules/den/aspects/zsh.nix` for configuration merging with `lib.mkBefore`.
        Keep host/user side effects, such as selecting a login shell, in explicit aspects.
      '';
    };
  }
]
