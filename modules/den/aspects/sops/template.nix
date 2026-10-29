{ lib, ... }:
{
  den.aspects.sops.template =
    { name, content, ... }@params:
    consumers:
    lib.mapAttrs (
      _class: consumer:
      let
        module = lib.toFunction consumer;
      in
      lib.setFunctionArgs
        (args: {
          imports = [
            (module (args // { inherit (args.config.sops.templates.${name}) path; }))
          ];
          sops.templates.${name} =
            builtins.removeAttrs params [
              "name"
              "content"
            ]
            // {
              content = if builtins.isFunction content then content args.config.sops.placeholder else content;
            };
        })
        (
          (builtins.removeAttrs (lib.functionArgs module) [ "path" ])
          // {
            config = false;
          }
        )
    ) consumers;
}
