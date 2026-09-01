{ den, lib, ... }:
{
  den.aspects.iter = lib.mkMerge [
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
          ++ [ den.aspects.development den.aspects.zscaler ];
        };
    }

    {
      nixos.sops.defaultSopsFile = ./secrets.yml;
    }
  ];

  den.hosts.x86_64-linux.iter = {
    wsl.enable = true;
    users.nixos-user.userName = "nixos";
  };
}
