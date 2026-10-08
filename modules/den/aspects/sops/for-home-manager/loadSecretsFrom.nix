{ lib, ... }:
{
  den.aspects.sops.for-home-manager.loadSecretsFrom =
    {
      file,
      sshKeyPath ? null,
    }:
    {
      homeManager.sops = {
        defaultSopsFile = file;
      }
      // lib.optionalAttrs (sshKeyPath != null) {
        age.sshKeyPaths = [ sshKeyPath ];
      };
    };
}
