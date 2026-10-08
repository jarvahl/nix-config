{ lib, ... }:
{
  den.aspects.sops.for-nixos.loadSecretsFrom =
    {
      file,
      sshKeyPath ? null,
    }:
    {
      nixos.sops = {
        defaultSopsFile = file;
      }
      // lib.optionalAttrs (sshKeyPath != null) {
        age = {
          keyFile = lib.mkForce null;
          sshKeyPaths = [ sshKeyPath ];
        };
      };
    };
}
