{ ... }:
{
  den.aspects.apex.provides.jarvahl = {
    nixos = { config, ... }:
      let passwordSecret = "users/jarvahl/hashedPassword";
      in {
        sops.secrets.${passwordSecret}.neededForUsers = true;
        sops.secrets."users/jarvahl/github/ssh-key" = {
          owner = "jarvahl";
          mode = "0400";
        };
        users.users.jarvahl.hashedPasswordFile = config.sops.secrets.${passwordSecret}.path;
        services.openssh.settings.AllowUsers = [ "jarvahl" ];
      };

    hjem = { sops, ... }: {
      files.".ssh/config.d/github".text = ''
        Host github.com
          HostName github.com
          User git
          IdentityFile ${sops.secrets."users/jarvahl/github/ssh-key".path}
          IdentitiesOnly yes
      '';
    };
  };
}
