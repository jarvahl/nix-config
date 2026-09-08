{ den, ... }:
{
  den.aspects.probook = {
    nixos.sops.defaultSopsFile = ./secrets.yml;

    includes = with den.aspects; [ wsl zscaler ];
  };
}
