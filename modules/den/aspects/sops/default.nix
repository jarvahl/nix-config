{ lib, ... }:
let
  homePath =
    path:
    { config, ... }:
    if lib.hasPrefix "/" (toString path) then
      path
    else
      "${config.directory}/${lib.removePrefix "./" (toString path)}";

  inUserContext = ctx: ctx ? user || ctx ? home;
  contextual =
    backend: ctx:
    if inUserContext ctx || (ctx.class or null) == "hjem" then backend.hjem else backend.nixos;
in
{
  den.aspects.sops = rec {
    from =
      file:
      contextual {
        hjem.hjem.sops.defaultSopsFile = file;
        nixos.nixos.sops.defaultSopsFile = file;
      };

    secret =
      {
        group ? null,
        mode ? "0600",
        module ? null,
        name,
        owner ? null,
        path,
        restartUnits ? [ ],
      }:
      contextual {
        hjem.hjem =
          { config, ... }:
          let
            secretPath = homePath path { inherit config; };
          in
          lib.mkMerge [
            {
              assertions = [
                {
                  assertion = config.sops.defaultSopsFile != null;
                  message = "sops.secret ${name}: missing `(from ./secrets.yaml)`";
                }
              ];

              sops.secrets.${name} = {
                inherit mode;
                path = secretPath;
              };
            }
            (lib.optionalAttrs (module != null) (module {
              inherit name;
              path = secretPath;
            }))
          ];

        nixos.nixos =
          { config, ... }:
          lib.mkMerge [
            {
              assertions = [
                {
                  assertion = config.sops.defaultSopsFile != null;
                  message = "sops.secret ${name}: missing `(from ./secrets.yaml)`";
                }
              ];

              sops.secrets.${name} = {
                inherit mode path restartUnits;
              }
              // lib.optionalAttrs (owner != null) { inherit owner; }
              // lib.optionalAttrs (group != null) { inherit group; };
            }
            (lib.optionalAttrs (module != null) (module {
              inherit name path;
            }))
          ];
      };

    keyFile =
      path:
      secret {
        module = { path, ... }: {
          sops.age.keyFile = path;
        };
        name = "age/key";
        inherit path;
      };
    provision = secret;
    secretsFile = from;

    hashedPassword = {
      nixos =
        {
          config,
          lib,
          user,
          ...
        }:
        let
          userName = user.userName;
          secretName = "users/${userName}/hashed_password";
        in
        {
          assertions = [
            {
              assertion = config.sops.defaultSopsFile != null;
              message = "sops.hashedPassword ${userName}: missing `(from ./secrets.yaml)`";
            }
          ];

          sops.secrets.${secretName}.neededForUsers = true;

          users.users.${userName} = {
            hashedPasswordFile = config.sops.secrets.${secretName}.path;
            initialPassword = lib.mkForce null;
          };
        };
    };
  };
}
