{ ... }:
{
  den.aspects.ssh.hostKey =
    {
      path,
      type,
    }:
    {
      nixos.services.openssh.hostKeys = [ { inherit path type; } ];
    };
}
