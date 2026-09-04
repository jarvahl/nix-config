{ den, ... }:
{
  den.aspects.probook = {
    nixos.sops.defaultSopsFile = ../secrets.yml;

    includes = [ den.aspects.zscaler ];
  };
}
