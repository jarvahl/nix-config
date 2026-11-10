{ den, recovery, ... }:
let
  host = "cargo";
  user = "jarvahl";
in
{
  den = {
    aspects."${user}@${host}" = {
      includes =
        (with den.aspects; [
          clipboard
          console
          development
          gh
        ])
        ++ (with den.batteries; [
          (user-shell "zsh")
        ]);
      nixos = { lib, ... }: {
        users.users.${user}.openssh.authorizedKeys.keys = [
          (lib.trim (builtins.readFile ../zero+/jarvahl.pub))
        ];
      };
      provides.to-hosts =
        with den.aspects.sops;
        secret
          {
            mode = "0400";
            name = "users/${user}/hashed_password";
          }
          {
            nixos = { lib, path, ... }: {
              sops.secrets."users/${user}/hashed_password".neededForUsers = true;
              users.users.${user} = {
                hashedPasswordFile = path;
                initialPassword = lib.mkForce null;
              };
            };
          };
    };

    hosts.x86_64-linux.${host}.users.${user} = {
      classes = [ "hjem" ];
      secrets.file = ./user-${user}.sops.yaml;
    };
  };

  sops.file = {
    creation_rules = recovery [
      {
        key_groups = [
          { age = [ "${user}@${host}" ]; }
        ];
        path_regex = ./user-${user}.sops.yaml;
      }
    ];

    keys."${user}@${host}" = "age13wj39r09ax4j0ekzhqx9h7ha0e2k20j45262ydcsx2az0qatlcesxp6230";
  };
}
