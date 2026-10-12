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
          (ssh.hostKey {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          })
          podman
        ])
        ++ (with den.aspects.sops; [
          (secretsFile ./secrets.yaml)
          (keyFile "/var/lib/sops-nix/key.txt")
          (provision {
            group = "root";
            name = "ssh/ssh_host_ed25519_key";
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
          path_regex = ./secrets.yaml;
        }
      ];

      keys.${host} = "age1muvk3n4qdla548vsgqmpg2xr2tnrkv70aeykncmvttrg2dlfzyustnyawd";
    };
  }
  (
    let
      user = "nixos-user";
      userName = "nixos";
    in
    {
      den = {
        aspects."${userName}@${host}" = {
          includes = with den.aspects.sops; [
            (secretsFile ./secrets.${userName}.yaml)
            (keyFile ".config/sops/age/key.txt")
          ];

          nixos =
            { config, lib, ... }:
            let
              passwordSecret = "users/${userName}/hashedPassword";
            in
            {
              sops.secrets.${passwordSecret}.neededForUsers = true;
              users.users.${userName} = {
                hashedPasswordFile = config.sops.secrets.${passwordSecret}.path;
                initialPassword = lib.mkForce null;
              };
            };
        };

        hosts.x86_64-linux.${host}.users.${user} = {
          classes = [ "hjem" ];
          inherit userName;
        };
      };

      sops-file = {
        creation_rules = recovery [
          {
            key_groups = [
              { age = [ "${userName}@${host}" ]; }
            ];
            path_regex = ./secrets.${userName}.yaml;
          }
        ];

        keys."${userName}@${host}" = "age1d3qae5nevuu0vrt33ehjck00tyt6ym23gdjf9r5fatxaplh6yg6szgzeqx";
      };
    }
  )
]
