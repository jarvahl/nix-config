{ den, lib, ... }:
let
  host = "rhein";
in
lib.mkMerge [
  (
    let
      user = "nixos";
      secretsFile = ./secrets.sops.yaml;
    in
    lib.mkMerge [
      {
        den.aspects."${user}@${host}" = {
          includes =
            (with den.aspects; [
              # accounts
              certificates
              gh
              tmux
            ])
            ++ (with den.batteries; [
              # batteries
              (user-shell "zsh")
            ]);
        };
      }
      {
        den.aspects."${user}@${host}" = {
          hjem = {
            sops.age.keyFile = ".config/sops/age/key.txt";
            sops.defaultSopsFile = secretsFile;
          };

          provides.to-hosts.nixos =
            { config, ... }:
            {
              sops.secrets."${user}/age_key" = {
                group = "users";
                mode = "0600";
                owner = user;
                path = "${config.users.users.${user}.home}/.config/sops/age/key.txt";
                sopsFile = ../secrets.sops.yaml;
              };
            };
        };
      }
      {
        den.aspects."${user}@${host}".nixos =
          { config, lib, ... }:
          {
            sops.secrets."${user}/hashed_password" = {
              mode = "0400";
              neededForUsers = true;
              sopsFile = ../secrets.sops.yaml;
            };

            users.users.${user} = {
              hashedPasswordFile = config.sops.secrets."${user}/hashed_password".path;
              initialPassword = lib.mkForce null;
            };
          };
      }
      {
        den.hosts.x86_64-linux.${host}.users.${user} = {
          classes = [ "hjem" ];
        };
      }
      {
        sops.file = {
          creation_rules = [
            {
              key_groups = [
                { age = [ "${user}@${host}" ]; }
              ];
              path_regex = secretsFile;
            }
          ];

          keys."${user}@${host}" = "age1d3qae5nevuu0vrt33ehjck00tyt6ym23gdjf9r5fatxaplh6yg6szgzeqx";
        };
      }
    ]

  )
]
