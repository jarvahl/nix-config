{
  den,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.den.flakeModule ];
}
// lib.mkMerge [
  {
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
        # system version
        nixos.system.stateVersion = lib.mkDefault "25.11";
      }
    ];

    flake-file.inputs.den.url = "github:denful/den";

  }
  {
    agent-files.skills.den = {
      description = "Use when editing Den aspects, host includes, namespaces, or callable aspects in modules/den/**; not for unrelated NixOS configuration.";
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
  }
]
