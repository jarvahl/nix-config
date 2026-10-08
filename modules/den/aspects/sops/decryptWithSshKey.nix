{ lib, ... }:
{
  den.aspects.sops.decryptWithSshKey = path: {
    nixos.sops.age = {
      keyFile = lib.mkForce null;
      sshKeyPaths = [ path ];
    };
  };
}
