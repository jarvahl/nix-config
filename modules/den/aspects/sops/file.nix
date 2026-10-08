{ ... }:
{
  den.aspects.sops.file = sopsFile: {
    nixos.sops.defaultSopsFile = sopsFile;
  };
}
