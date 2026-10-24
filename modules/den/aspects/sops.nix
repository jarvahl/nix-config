{ den, lib, ... }:
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
      group ? null,
      includes ? [ ],
      mode ? "0600",
      name,
      owner ? null,
      path,
      restartUnits ? [ ],
    }:
    { config, ... }:
    lib.mkMerge (
      [
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
      ]
      ++ includes
    );

  userSecret =
    {
      includes ? [ ],
      mode ? "0600",
      name,
      path,
      ...
    }:
    { config, ... }:
    let
      secretPath = homePath path { inherit config; };
    in
    lib.mkMerge (
      [
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
      ]
      ++ includes
    );

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
with den.lib;
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
      params: aspect:
      callable {
        includes = [
          (
            {
              user ? null,
              ...
            }:
            if user != null then { hjem = userSecret params; } else { nixos = hostSecret params; }
          )
          aspect
        ];
      };

    keyFile =
      path:
      let
        userHostSecret =
          { config, user, ... }:
          let
            userName = user.name;
          in
          hostSecret {
            group = "users";
            mode = "0600";
            name = "users/${userName}/age_key";
            owner = userName;
            path = homePath path { config.home.homeDirectory = config.users.users.${userName}.home; };
          } { inherit config; };
      in
      contextual {
        hjem = {
          hjem =
            { config, ... }:
            {
              sops.age.keyFile = homePath path { inherit config; };
            };
          provides.to-hosts.nixos = userHostSecret;
        };
        homeManager = {
          homeManager =
            { config, ... }:
            {
              sops.age.keyFile = homePath path { inherit config; };
            };
          provides.to-hosts.nixos = userHostSecret;
        };
        nixos.nixos.sops.age = {
          keyFile = path;
          sshKeyPaths = lib.mkForce [ ];
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

          users.mutableUsers = false;

          users.users.${userName} = {
            hashedPasswordFile = config.sops.secrets.${secretName}.path;
            initialPassword = lib.mkForce null;
          };
        };
    };
  };
}
