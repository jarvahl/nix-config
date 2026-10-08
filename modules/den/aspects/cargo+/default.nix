{ den, ... }:
let
  host = "cargo";
in
{
  den = {
    aspects.${host}.includes = with den.aspects; [
      (sops.loadSecretsFrom ./secrets.yaml)
      (sops.decryptWithSshKey "/etc/ssh/ssh_host_ed25519_key")
      ssh
      (ssh.provisionHostKey {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      })
      podman
    ];

    hosts.x86_64-linux.${host} = {
      users.nixos-user = {
        classes = [ "hjem" ];
        userName = "nixos";
      };
      wsl.enable = true;
    };
  };

  "sops-file" = {
    creation_rules = [
      {
        key_groups = [
          { age = [ host ]; }
        ];
        path_regex = ./secrets.yaml;
      }
    ];

    keys.${host} = "age1y8xgchal8k9gu2hgl4jde53ap0rxj4p3kfs3a0xt2c5cmx3ztexs96dm04";
  };
}
