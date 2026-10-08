{ lib, ... }:
{
  den.aspects.sops.useAsIdentity = path: {
    nixos.sops.age = {
      keyFile = lib.mkForce null;
      sshKeyPaths = [ path ];
    };
  };
}
