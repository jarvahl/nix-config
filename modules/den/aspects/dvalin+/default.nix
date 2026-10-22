{
  lib,
  ...
}:
let
  host = "dvalin";
in
lib.mkMerge [
  {
    den = {
      aspects.${host} = {
        includes = [ ];
        nixos = { };
      };

      hosts.x86_64-linux.${host} = { };
    };
  }
  (
    let
      user = "jarvahl";
    in
    {
      den = {
        aspects."${user}@${host}" = {
          includes = [ ];
        };

        hosts.x86_64-linux.${host}.users.${user}.classes = [
          "hjem"
        ];
      };
    }
  )
]
