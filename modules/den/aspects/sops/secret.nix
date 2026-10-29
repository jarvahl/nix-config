{ lib, ... }:
let
  definition = config: name: settings: {
    assertions = [
      {
        assertion = config.sops.defaultSopsFile != null;
        message = "sops.secret ${name}: missing secrets.file on the host or user entity";
      }
    ];
    sops.secrets.${name} = settings;
  };

  hostSecret =
    {
      group ? null,
      includes ? [ ],
      mode ? "0600",
      name,
      owner ? null,
      path ? null,
      restartUnits ? [ ],
    }:
    { config, ... }:
    lib.mkMerge (
      [
        (definition config name (
          {
            inherit mode;
          }
          // lib.optionalAttrs (restartUnits != null) { inherit restartUnits; }
          // lib.optionalAttrs (group != null) { inherit group; }
          // lib.optionalAttrs (owner != null) { inherit owner; }
          // lib.optionalAttrs (path != null) { inherit path; }
        ))
      ]
      ++ includes
    );

  userSecret =
    {
      includes ? [ ],
      mode ? "0600",
      name,
      path ? null,
      ...
    }:
    { config, ... }:
    lib.mkMerge (
      [
        (definition config name (
          {
            inherit mode;
          }
          // lib.optionalAttrs (path != null) {
            path =
              if lib.hasPrefix "/" (toString path) then
                path
              else
                "${config.home.homeDirectory}/${lib.removePrefix "./" (toString path)}";
          }
        ))
      ]
      ++ includes
    );
in
{
  den.aspects.sops.secret =
    params: consumers:
    lib.mapAttrs (
      class: consumer:
      let
        module = lib.toFunction consumer;
      in
      lib.setFunctionArgs
        (args: {
          imports = [
            (if class == "nixos" then hostSecret params else userSecret params)
            (module (
              args
              // {
                inherit (args.config.sops.secrets.${params.name}) path;
                placeholder = args.config.sops.placeholder.${params.name};
              }
            ))
          ];
        })
        (
          (builtins.removeAttrs (lib.functionArgs module) [
            "path"
            "placeholder"
          ])
          // {
            config = false;
          }
        )
    ) consumers;
}
