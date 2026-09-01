{ den, ... }:
{
  den.aspects.cargo = {
    nixos.sops.defaultSopsFile = ./secrets.yml;

    includes = with den.aspects; [ wsl zscaler ];
  };
}
