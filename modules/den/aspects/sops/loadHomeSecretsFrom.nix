{ ... }:
{
  den.aspects.sops.loadHomeSecretsFrom = sopsFile: {
    homeManager.sops.defaultSopsFile = sopsFile;
  };
}
