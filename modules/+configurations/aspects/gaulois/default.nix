{ den, lib, ... }:
let
  host = "gaulois";
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
            proxy
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

      keys.${host} = "age1g54ya2lf87wg9verfd5aqk8xrptgmed7dn2v3850wjxt330jwfkskngg04";
    };
  }

  {
    den.aspects.${host}.nixos = {
      sops.age.keyFile = "/var/lib/sops-outputs/key.txt";
      sops.defaultSopsFile = ./secrets.sops.yaml;
    };
  }
]
