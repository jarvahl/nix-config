{ ... }:
{
  den.aspects.ssh.provisionHostKey =
    {
      path,
      type,
      secretName ? "ssh/${baseNameOf path}",
    }:
    {
      nixos = {
        services.openssh.hostKeys = [
          { inherit path type; }
        ];

        sops.secrets.${secretName} = {
          group = "root";
          mode = "0600";
          owner = "root";
          inherit path;
          restartUnits = [ "sshd.service" ];
        };
      };
    };
}
