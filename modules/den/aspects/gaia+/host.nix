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
      aspects.${host} = {
        includes =
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
                nixos = { path, ... }: {
                  services.openssh.hostKeys = [
                    {
                      inherit path;
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
        nixos = { lib, ... }: {
          wsl.defaultUser = lib.mkForce "nixos";
        };
      };

      hosts.x86_64-linux.${host} = {
        secrets.file = ./host.sops.yaml;
        wsl.defaultUser = lib.mkForce "nixos";
        wsl.enable = true;
      };
    };

    sops.file = {
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
]
