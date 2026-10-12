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
  den.aspects.sops = {
    keyFile =
      path:
      contextual {
        hjem.hjem =
          { config, ... }:
          let
            keyPath = homePath path { inherit config; };
          in
          {
            sops.age.keyFile = keyPath;
            sops.secrets.ageKey.path = keyPath;
          };
        nixos.nixos.sops = {
          age.keyFile = path;
          secrets.ageKey.path = path;
        };
      };

    provision =
      {
        name,
        path,
        mode ? "0600",
        owner ? null,
        group ? null,
        restartUnits ? [ ],
      }:
      contextual {
        hjem.hjem = { config, ... }: {
          sops.secrets.${name} = {
            inherit mode;
            path = homePath path { inherit config; };
          };
        };

        nixos.nixos.sops.secrets.${name} = {
          inherit mode path restartUnits;
        }
        // lib.optionalAttrs (owner != null) { inherit owner; }
        // lib.optionalAttrs (group != null) { inherit group; };
      };

    secretsFile =
      file:
      contextual {
        hjem.hjem.sops.defaultSopsFile = file;
        nixos.nixos.sops.defaultSopsFile = file;
      };
  };
}
