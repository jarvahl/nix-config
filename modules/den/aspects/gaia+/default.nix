{
  den,
  lib,
  recovery,
  ...
}:
let
  host = "gaia";
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

      keys.${host} = "age1g54ya2lf87wg9verfd5aqk8xrptgmed7dn2v3850wjxt330jwfkskngg04";
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

        keys."${userName}@${host}" = "age183kk96xwp5c4w0qznxklmuqu0rmyt74chxr6snmwp8qeuts2zfgsygp6dg";
      };
    }
  )
]
