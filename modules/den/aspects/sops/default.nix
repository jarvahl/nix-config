{ lib, ... }:
let
  homePath =
    path:
    { config, ... }:
    if lib.hasPrefix "/" (toString path) then
      path
    else
      "${config.home.homeDirectory}/${lib.removePrefix "./" (toString path)}";

  hostSecret =
    {
      aspect ? { },
      group ? null,
      mode ? "0600",
      name,
      owner ? null,
      path,
      restartUnits ? [ ],
    }:
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
      aspect
    ];

  userSecret =
    {
      aspect ? { },
      mode ? "0600",
      name,
      path,
      ...
    }:
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
      aspect
    ];

  inUserContext =
    ctx:
    ctx ? user || ctx ? home || (ctx.class or null) == "homeManager" || (ctx.class or null) == "hjem";
  contextual =
    backend: ctx:
    if inUserContext ctx then
      if (ctx.class or null) == "homeManager" then backend.homeManager else backend.hjem
    else
      backend.nixos;
in
{
  den.aspects.sops = rec {
    from =
      file:
      contextual {
        hjem.hjem.sops.defaultSopsFile = file;
        homeManager.homeManager.sops.defaultSopsFile = file;
        nixos.nixos.sops.defaultSopsFile = file;
      };

    secret =
      args:
      contextual {
        hjem.hjem = userSecret args;
        homeManager.homeManager = userSecret args;
        nixos.nixos = hostSecret args;
      };

    keyFile =
      path:
      contextual {
        hjem.hjem =
          { config, ... }:
          let
            secretPath = homePath path { inherit config; };
          in
          lib.mkMerge [
            (userSecret {
              name = "age/key";
              inherit path;
            } { inherit config; })
            { sops.age.keyFile = secretPath; }
          ];
        homeManager.homeManager =
          { config, ... }:
          let
            secretPath = homePath path { inherit config; };
          in
          lib.mkMerge [
            (userSecret {
              name = "age/key";
              inherit path;
            } { inherit config; })
            { sops.age.keyFile = secretPath; }
          ];
        nixos.nixos = hostSecret {
          aspect.sops.age.keyFile = path;
          name = "age/key";
          inherit path;
        };
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
