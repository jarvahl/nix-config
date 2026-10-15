{
  den,
  inputs,
  lib,
  ...
}:
{
  agent-files.skills.den = {
    description = "Routing guide for this repo's Den usage. Use when editing modules/den/**, especially Den aspects, host includes, callable aspects, or import-tree merged aspect namespaces.";
    instructions = { references, ... }: ''
      # Den

      Use this skill before editing `modules/den/**`.

      ## Routing

      | Task | Read |
      | --- | --- |
      | Editing or creating Den aspects | `${references.aspects}` |
      | Working with callable aspects / parametric aspect args | `${references.callable-aspects}` |
      | Selecting child aspects from a parent namespace | `${references.callable-aspects}` |
      | Deciding whether something should be standalone or a child aspect | `${references.aspects}`, then `${references.callable-aspects}` |
      | Unsure | Start with `${references.aspects}` |

      Keep this file light. Detailed rules live in `references/`.
    '';
  };

  den.default = lib.mkMerge [
    {
      # batteries
      includes = with den.batteries; [
        define-user
        hostname
        inputs'
        primary-user
        self'
      ];
    }
    {
      # default aspects
      includes = with den.aspects; [
        nix
        sudo
        sops.hashedPassword
      ];
    }
    {
      # core
      nixos = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
          jq
          python3
          wget
        ];
      };
    }
    {
      # comma
      nixos.imports = [
        inputs.nix-index-database.nixosModules.nix-index
      ];
    }
    {
      # nvim
      nixos.hjem.extraModules = [
        inputs.nvf.homeManagerModules.default
      ];
    }
    {
      # pi
      nixos.nixpkgs.overlays = [
        inputs.pi.overlays.default
      ];
    }
    {
      # zsh
      nixos.hjem.extraModules = [
        inputs.zsh-nix.homeManagerModules.default
      ];
    }
    {
      # system version
      nixos.system.stateVersion = lib.mkDefault "25.11";
    }
  ];

  flake-file.inputs.den.url = "github:denful/den";

  imports = [
    inputs.den.flakeModule
  ];
}
