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
        (with den.aspects.sops; [
          (from ./secrets-host.yaml)
          (keyFile "/var/lib/sops-nix/key.txt")
          (secret (
            let
              path = "/etc/ssh/ssh_host_ed25519_key";
            in
            {
              aspect.services.openssh.hostKeys = [
                {
                  inherit path;
                  type = "ed25519";
                }
              ];
              group = "root";
              name = "ssh/host_key";
              owner = "root";
              inherit path;
              restartUnits = [ "sshd.service" ];
            }
          ))
        ])
        ++ (with den.aspects; [
          (certificates {
            includes = { ... }: [
              {
                nixos = { pkgs, ... }: {
                  security.pki.certificateFiles = [
                    "${pkgs.zscaler-cacert}/etc/ssl/certs/zscaler-ca.crt"
                  ];
                };
              }
            ];
          })
        ])
        ++ (with den.aspects; [
          comma
          fonts
          podman
          ssh
        ]);

      hosts.x86_64-linux.${host} = {
        wsl.enable = true;
      };
    };

    sopsFile = {
      creation_rules = recovery [
        {
          key_groups = [
            { age = [ host ]; }
          ];
          path_regex = ./secrets-host.yaml;
        }
      ];

      keys.${host} = "age1g54ya2lf87wg9verfd5aqk8xrptgmed7dn2v3850wjxt330jwfkskngg04";
    };
  }
  (
    let
      user = "nixos";
    in
    {
      den = {
        aspects."${user}@${host}" = {
          includes =
            (with den.aspects.sops; [
              (from ./secrets-user-${user}.yaml)
              (keyFile ".config/sops/age/key.txt")
            ])
            ++ (with den.aspects; [
              bat
              eza
              fzf
              nvim
              worktrunk
              zsh

              # accounts
              github
              gitlab
            ])
            ++ (with den.batteries; [
              (user-shell "zsh")
            ]);
        };

        hosts.x86_64-linux.${host}.users.${user}.classes = [
          "hjem"
        ];
      };

      sopsFile = {
        creation_rules = recovery [
          {
            key_groups = [
              { age = [ "${user}@${host}" ]; }
            ];
            path_regex = ./secrets-user-${user}.yaml;
          }
        ];

        keys."${user}@${host}" = "age183kk96xwp5c4w0qznxklmuqu0rmyt74chxr6snmwp8qeuts2zfgsygp6dg";
      };
    }
  )
]
