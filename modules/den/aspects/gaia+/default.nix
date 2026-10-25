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
          # secrets
          (secret
            {
              group = "root";
              name = "ssh/host_key";
              owner = "root";
              path = "/etc/ssh/ssh_host_ed25519_key";
              restartUnits = [ "sshd.service" ];
            }
            {
              nixos = { config, ... }: {
                services.openssh.hostKeys = [
                  {
                    path = config.sops.secrets."ssh/host_key".path;
                    type = "ed25519";
                  }
                ];
              };
            }
          )
        ])
        ++ (with den.aspects; [
          # certificates
          (certificates {
            nixos = { pkgs, ... }: {
              security.pki.certificateFiles = [
                "${pkgs.zscaler-cacert}/etc/ssl/certs/zscaler-ca.crt"
              ];
            };
          })
        ])
        ++ (with den.aspects; [
          # system
          comma
          fonts
          podman
          ssh
        ]);

      hosts.x86_64-linux.${host} = {
        secrets.file = ./host.sops.yaml;
        wsl.enable = true;
      };
    };

    sopsFile = {
      creation_rules = recovery [
        {
          key_groups = [
            { age = [ host ]; }
          ];
          path_regex = ./host.sops.yaml;
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
            (with den.aspects; [
              # console
              bat
              eza
              fzf
              git
              nvim
              worktrunk
              zsh

              # accounts
              github
              gitlab
            ])
            ++ (with den.batteries; [
              # batteries
              (user-shell "zsh")
            ]);
        };

        hosts.x86_64-linux.${host}.users.${user} = {
          classes = [ "hjem" ];
          secrets.file = ./user-${user}.sops.yaml;
        };
      };

      sopsFile = {
        creation_rules = recovery [
          {
            key_groups = [
              { age = [ "${user}@${host}" ]; }
            ];
            path_regex = ./user-${user}.sops.yaml;
          }
        ];

        keys."${user}@${host}" = "age183kk96xwp5c4w0qznxklmuqu0rmyt74chxr6snmwp8qeuts2zfgsygp6dg";
      };
    }
  )
]
