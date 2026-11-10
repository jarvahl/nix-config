{ den, ... }:
let
  host = "cargo";
  user = "nixos";
in
{
  den = {
    aspects."${user}@${host}" = {
      includes =
        (with den.aspects; [
          # tools
          clipboard
          console
          development

          # accounts
          gh
        ])
        ++ (with den.batteries; [
          # batteries
          (user-shell "zsh")
        ]);
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
    creation_rules = [
      {
        key_groups = [
          { age = [ "${user}@${host}" ]; }
        ];
        path_regex = ./user-${user}.sops.yaml;
      }
    ];

    keys."${user}@${host}" = "age1d3qae5nevuu0vrt33ehjck00tyt6ym23gdjf9r5fatxaplh6yg6szgzeqx";
  };
}
