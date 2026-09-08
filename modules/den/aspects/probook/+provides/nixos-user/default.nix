{ den, ... }:
{
  den.aspects.probook = {
    provides.nixos-user = { user, ... }:
      let
        passwordSecret = "users/${user.userName}/hashedPassword";
      in
      {
        nixos = { config, ... }: {
          sops.secrets.${passwordSecret}.neededForUsers = true;

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
