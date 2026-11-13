let
  host = "cargo";
in
{ den, lib, ... }:

lib.mkMerge [
  {
    den = {
      aspects.${host} = {
        includes =
          (with den.aspects; [
            # certificates
            certificates
            zscaler
          ])
          ++ (with den.aspects; [
            # system
            comma
            fonts
            podman
            ssh
          ]);
        nixos = { lib, ... }: {
          wsl.defaultUser = lib.mkForce "nixos";
        };
      };

      hosts.x86_64-linux.${host} = {
        wsl.defaultUser = lib.mkForce "nixos";
        wsl.enable = true;
      };
    };

    sops.file = {
      creation_rules = [
        {
          key_groups = [
            { age = [ host ]; }
          ];
          path_regex = ./host.sops.yaml;
        }
      ];

      keys.${host} = "age1muvk3n4qdla548vsgqmpg2xr2tnrkv70aeykncmvttrg2dlfzyustnyawd";
    };
  }

  {
    den.aspects.${host}.sops.nixos = {
      sops.age.keyFile = "/var/lib/sops-outputs/key.txt";
      sops.defaultSopsFile = ./host.sops.yaml;
    };
  }
  (
    let
      user = "jarvahl";
      secretsFile = ./user-${user}.sops.yaml;
    in
    lib.mkMerge [
      {
        den.aspects."${user}@${host}" = {
          includes =
            (with den.aspects; [
              certificates
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
        };
      }
      {
        den.aspects."${user}@${host}".sops = {
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
                sopsFile = ./host.sops.yaml;
              };
            };
        };
      }
      {
        den.aspects."${user}@${host}".sops.nixos =
          { config, lib, ... }:
          {
            sops.secrets."${user}/hashed_password" = {
              mode = "0400";
              neededForUsers = true;
              sopsFile = ./host.sops.yaml;
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

          keys."${user}@${host}" = "age13wj39r09ax4j0ekzhqx9h7ha0e2k20j45262ydcsx2az0qatlcesxp6230";
        };
      }
    ]
  )

  (
    let
      user = "nixos";
      secretsFile = ./user-${user}.sops.yaml;
    in
    lib.mkMerge [
      {
        den.aspects."${user}@${host}" = {
          includes =
            (with den.aspects; [
              # accounts
              certificates
              gh
            ])
            ++ (with den.batteries; [
              # batteries
              (user-shell "zsh")
            ]);
        };
      }
      {
        den.aspects."${user}@${host}".sops = {
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
                sopsFile = ./host.sops.yaml;
              };
            };
        };
      }
      {
        den.aspects."${user}@${host}".sops.nixos =
          { config, lib, ... }:
          {
            sops.secrets."${user}/hashed_password" = {
              mode = "0400";
              neededForUsers = true;
              sopsFile = ./host.sops.yaml;
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
