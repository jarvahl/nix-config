{
  den,
  lib,
  recovery,
  ...
}:
let
  host = "cargo";
in
lib.mkMerge [
  {
    den = {
      aspects.${host}.includes =
        (with den.aspects; [
          ssh
          podman
        ])
        ++ (with den.aspects.sops; [
          (from ./secrets-host.yaml)
          (secret {
            module = { path, ... }: {
              sops.age.keyFile = path;
            };
            name = "age/key";
            path = "/var/lib/sops-nix/key.txt";
          })
          (secret {
            group = "root";
            module = { path, ... }: {
              services.openssh.hostKeys = [
                {
                  inherit path;
                  type = "ed25519";
                }
              ];
            };
            name = "ssh/host_key";
            owner = "root";
            path = "/etc/ssh/ssh_host_ed25519_key";
            restartUnits = [ "sshd.service" ];
          })
        ]);

      hosts.x86_64-linux.${host} = {
        wsl.enable = true;
      };
    };

    sops-file = {
      creation_rules = recovery [
        {
          key_groups = [
            { age = [ host ]; }
          ];
          path_regex = ./secrets-host.yaml;
        }
      ];

      keys.${host} = "age1muvk3n4qdla548vsgqmpg2xr2tnrkv70aeykncmvttrg2dlfzyustnyawd";
    };
  }
  (
    let
      user = "nixos";
    in
    {
      den = {
        aspects."${user}@${host}" = {
          includes = with den.aspects.sops; [
            (from ./secrets-user-${user}.yaml)
            (secret {
              module = { path, ... }: {
                sops.age.keyFile = path;
              };
              name = "age/key";
              path = ".config/sops/age/key.txt";
            })
          ];
        };

        hosts.x86_64-linux.${host}.users.${user}.classes = [
          "hjem"
        ];
      };

      sops-file = {
        creation_rules = recovery [
          {
            key_groups = [
              { age = [ "${user}@${host}" ]; }
            ];
            path_regex = ./secrets-user-${user}.yaml;
          }
        ];

        keys."${user}@${host}" = "age1d3qae5nevuu0vrt33ehjck00tyt6ym23gdjf9r5fatxaplh6yg6szgzeqx";
      };
    }
  )
]
