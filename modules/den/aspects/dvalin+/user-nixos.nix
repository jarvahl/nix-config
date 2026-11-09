{ recovery, ... }:
let
  host = "dvalin";
in
{
  den.hosts.x86_64-linux.${host}.users.nixos = {
    classes = [ "hjem" ];
    secrets.file = ./user-nixos.sops.yaml;
  };

  sopsFile = {
    creation_rules = recovery [
      {
        key_groups = [
          { age = [ "nixos@${host}" ]; }
        ];
        path_regex = ./user-nixos.sops.yaml;
      }
    ];

    keys."nixos@${host}" = "age1uj0ultfy0sxxty4jrczl7ajwwg42tefqqpzjedl246eghy7yjdjqfp6ysz";
  };
}
