{ den, lib, ... }:
let
  host = "rhein";
in
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
          path_regex = ./secrets.sops.yaml;
        }
      ];

      keys.${host} = "age1muvk3n4qdla548vsgqmpg2xr2tnrkv70aeykncmvttrg2dlfzyustnyawd";
    };
  }

  {
    den.aspects.${host}.nixos = {
      sops.age.keyFile = "/var/lib/sops-outputs/key.txt";
      sops.defaultSopsFile = ./secrets.sops.yaml;
    };
  }
]
