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
        (with den.aspects.sops; [
          (from ./secrets-host.yaml)
          (keyFile "/var/lib/sops-nix/key.txt")
          (secret rec {
            group = "root";
            includes = [
              {
                services.openssh.hostKeys = [
                  {
                    inherit path;
                    type = "ed25519";
                  }
                ];
              }
            ];
            name = "ssh/host_key";
            owner = "root";
            path = "/etc/ssh/ssh_host_ed25519_key";
            restartUnits = [ "sshd.service" ];
          })
        ])
        ++ (with den.aspects; [
          comma
          fonts
          podman
          ssh
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
          includes =
            (with den.aspects.sops; [
              (from ./secrets-user-${user}.yaml)
              (keyFile ".config/sops/age/key.txt")
            ])
            ++ (with den.aspects; [
              bat
              eza
              fzf
              git
              nvim
              worktrunk
              zsh

              # accounts
              github
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

        keys."${user}@${host}" = "age1d3qae5nevuu0vrt33ehjck00tyt6ym23gdjf9r5fatxaplh6yg6szgzeqx";
      };
    }
  )
]
