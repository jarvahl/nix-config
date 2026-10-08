{ ... }:
{
  den.aspects.sops.decryptHomeWithSshKey = path: {
    homeManager.sops.age.sshKeyPaths = [ path ];
  };
}
