{
  den,
  lib,
  ...
}:
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
}
