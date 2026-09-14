{ ... }:
{
  den.aspects.cargo.provides.nixos-user = { user, ... }:
    let passwordSecret = "users/${user.userName}/hashedPassword";
    in {
      nixos = { config, ... }: {
        sops.secrets.${passwordSecret}.neededForUsers = true;
        sops.secrets."users/${user.userName}/github/ssh-key" = {
          owner = user.userName;
          mode = "0400";
        };
        users.users.${user.userName}.hashedPasswordFile =
          config.sops.secrets.${passwordSecret}.path;
      };
    };
}
