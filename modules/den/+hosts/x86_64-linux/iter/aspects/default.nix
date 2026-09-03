{ ... }:
{
  den.aspects.iter = {
    nixos.sops.defaultSopsFile = ../secrets.yml;

    includes = [ den.aspects.zscaler ];
  };
}
