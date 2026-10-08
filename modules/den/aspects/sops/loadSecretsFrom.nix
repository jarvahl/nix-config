{ ... }:
{
  den.aspects.sops.loadSecretsFrom = sopsFile: {
    nixos.sops.defaultSopsFile = sopsFile;
  };
}
