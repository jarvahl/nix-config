{ lib, ... }:
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

  den.aspects.ssh.provisionUserKey =
    {
      path,
      secretName ? "ssh/${baseNameOf path}",
    }:
    {
      homeManager =
        { config, ... }:
        {
          sops.secrets.${secretName} = {
            mode = "0600";
            path =
              if lib.hasPrefix "/" path then
                path
              else
                "${config.home.homeDirectory}/${lib.removePrefix "./" path}";
          };
        };
    };
}
