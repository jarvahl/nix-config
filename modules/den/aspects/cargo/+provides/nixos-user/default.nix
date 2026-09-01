{ den, ... }:
{
  den.aspects.cargo = {
    provides.nixos-user = { user, ... }:
      let
        passwordSecret = "users/${user.userName}/hashedPassword";
      in
      {
        hjem = { sops, user, ... }: {
          files.".ssh/config".text = ''
            Include ~/.ssh/config.d/*
          '';

          files.".ssh/config.d/github".text = ''
            Host github.com
              HostName github.com
              User git
              IdentityFile ${sops.secrets."users/${user.userName}/github/ssh-key".path}
              IdentitiesOnly yes
          '';
        };

        nixos = { config, ... }: {
          sops.secrets.${passwordSecret}.neededForUsers = true;

          sops.secrets."users/${user.userName}/github/ssh-key" = {
            owner = user.userName;
            mode = "0400";
          };

          users.users.${user.userName}.hashedPasswordFile =
            config.sops.secrets.${passwordSecret}.path;
        };

        includes = [
          den.batteries.primary-user
          (den.batteries.user-shell "zsh")
          den.aspects.development
        ];
      };
  };
}
