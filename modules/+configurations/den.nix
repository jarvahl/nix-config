{
  config,
  den,
  inputs,
  lib,
  ...
}:
{
  den.default = lib.mkMerge [
    {
      nixos = with config.flakelight.outputs; {
        imports = lib.attrValues nixosModules;
        nixpkgs.overlays = [ overlays.default ];
      };
    }
    {
      # batteries
      includes = with den.batteries; [
        define-user
        hjem
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
        sops
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

  imports = [
    inputs.den.flakeModule
  ];
}
