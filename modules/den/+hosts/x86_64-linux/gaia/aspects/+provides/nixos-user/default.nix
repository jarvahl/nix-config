{ den
, lib
, ...
}:
{
  den.aspects.gaia = lib.mkMerge [
    {
      provides.nixos-user =
        { user, ... }:
        let
          passwordSecret = "users/${user.userName}/hashedPassword";
        in
        {
          nixos =
            { config, ... }:
            {
              sops.secrets.${passwordSecret}.neededForUsers = true;

              users.users.${user.userName}.hashedPasswordFile =
                config.sops.secrets.${passwordSecret}.path;
            };

          includes = [
            den.batteries.primary-user
            (den.batteries.user-shell "zsh")
          ]
          ++ [ den.aspects.development ];
        };
    }

    {
      provides.nixos-user = {
        hjem = { pkgs, ... }: {
          packages = with pkgs; [ glab openshift ];

          rum.programs.git.settings.include.path = "/etc/gitconfig.d/proxy.conf";
        };
      };
    }
  ];
}
