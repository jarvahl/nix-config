{ den, lib, ... }:
let
  inherit (builtins) hasAttr;
  inherit (den.lib) policy;
  inherit (lib)
    concatLists
    filterAttrs
    isAttrs
    mapAttrsToList
    ;

  isAspectExtension = name: value: hasAttr name den.aspects && isAttrs value;

  extensionsOf = parent: parent |> filterAttrs isAspectExtension;

  includeWhenActive =
    parent: extensionName: extension:
    policy.when (
      { hasAspect, ... }:
      hasAspect parent && hasAspect den.aspects.${extensionName}
    ) (policy.include extension);

  extensionPoliciesFor =
    parent:
    extensionsOf parent
    |> mapAttrsToList (extensionName: extension: includeWhenActive parent extensionName extension);

  aspectExtensionPolicies =
    den.aspects |> mapAttrsToList (_parentName: parent: extensionPoliciesFor parent) |> concatLists;
in
{
  den.schema.host.includes = aspectExtensionPolicies;
  den.schema.user.includes = aspectExtensionPolicies;
}
