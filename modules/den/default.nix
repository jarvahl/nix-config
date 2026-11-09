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
        ];
      }
      {
        nixos.users.mutableUsers = false;
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
      instructions = ''
        # Den

        Use this skill before editing `modules/den/**`.

        Keep Den aspect definitions under `modules/den/aspects/` and read the
        surrounding modules before changing host/user includes or callable aspects.
      '';
    };
  }
]
