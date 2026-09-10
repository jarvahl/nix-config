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
          ]
          ++ [ den.aspects.development ];
        };
    }

    {
      provides.nixos-user = {
        hjem = { pkgs, sops, user, ... }: {
          files.".ssh/config".text = ''
            Include ~/.ssh/config.d/*
          '';

          files.".ssh/config.d/github".text = ''
            Host github.com
              HostName github.com
              User git
              IdentityFile ${sops.secrets."users/${user.userName}/github/ssh-key".path}
              IdentitiesOnly yes
              ProxyCommand sh -c '. ${sops.templates."proxy-environment".path}; proxy="''${http_proxy#*://}"; exec ${pkgs.netcat}/bin/nc -X connect -x "$proxy" "$1" "$2"' _ %h %p
          '';

          packages = with pkgs; [ glab openshift ];

          rum.programs.git.settings.include.path = "/etc/gitconfig.d/proxy.conf";
        };
      };
    }
  ];
}
