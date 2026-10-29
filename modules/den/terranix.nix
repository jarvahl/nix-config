{
  config,
  den,
  lib,
  ...
}:
{
  den.classes.terranix.description = "Terranix configuration";

  den.policies.host-to-terranix =
    { __entityKind, host, ... }:
    lib.optional (__entityKind == "host") (
      den.lib.policy.instantiate {
        class = "terranix";
        instantiate = { modules, ... }: modules;
        intoAttr = [
          "terranixModules"
          host.name
        ];
        name = "${host.name}-terranix";
      }
    );

  den.schema.host.includes = [ den.policies.host-to-terranix ];

  perSystem.terranix.terranixConfigurations.terranix.modules = lib.concatLists (
    builtins.attrValues (config.flake.terranixModules or { })
  );
}
