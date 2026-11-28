{ den, lib, ... }:
let
  host = "asgard";
in
lib.mkMerge [
  (
    let
      user = "jarvahl";
      secretsFile = ./secrets.sops.yaml;
    in
    lib.mkMerge [
      {
        den.aspects."${user}@${host}" = {
          hjem.files.".ssh/config.d/bifrost".text = ''
            Host bifrost
              HostName bifrost.tailbf412b.ts.net
              User jarvahl
              IdentityFile ~/.ssh/id_ed25519
              IdentitiesOnly yes
          '';

          includes =
            (with den.aspects; [
              # ui
              foot
              heeler
              linger
            ])
            ++ (with den.aspects; [
              # tools
              clipboard
              console
              development
              firefox
              herdr
              hyperland
              hypridle
              pi
              quickshell
              swaybg
            ])
            ++ (with den.aspects; [
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

          keys."${user}@${host}" = "age1gfhnnsfzf839uvyr3nf6r3cl85zk4hvewkjpfpncxe8y7dxraeeqyr4y82";
        };
      }
    ]

  )
]
