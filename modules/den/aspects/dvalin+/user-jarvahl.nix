{ den, recovery, ... }:
let
  host = "dvalin";
  user = "jarvahl";
in
{
  den = {
    aspects."${user}@${host}" = {
      includes =
        (with den.aspects; [
          console
          development
          gh
          linger
        ])
        ++ (with den.aspects.sops; [

        ]);

      provides.to-hosts =
        with den.aspects.sops;
        secret
          {
            mode = "0400";
            name = "users/${user}/hashed_password";
          }
          {
            nixos = { lib, path, ... }: {
              sops.secrets."users/${user}/hashed_password".neededForUsers = true;
              users.users.${user} = {
                hashedPasswordFile = path;
                initialPassword = lib.mkForce null;
                openssh.authorizedKeys.keys = [
                  (lib.trim (builtins.readFile ../zero+/jarvahl.pub))
                ];
              };
            };
          };
    };

    hosts.x86_64-linux.${host}.users.${user} = {
      classes = [ "hjem" ];
      secrets.file = ./user-${user}.sops.yaml;
    };
  };

  sops.file = {
    creation_rules = recovery [
      {
        key_groups = [
          { age = [ "${user}@${host}" ]; }
        ];
        path_regex = ./user-${user}.sops.yaml;
      }
    ];

    keys."${user}@${host}" = "age15ny8fkpgznutmkze50rcvceq400r6nq68n2vpdsq3muuq6vcwqmqlspkng";
  };
}
