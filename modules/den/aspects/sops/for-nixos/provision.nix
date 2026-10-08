{ lib, ... }:
{
  den.aspects.sops.for-nixos.provision =
    {
      name,
      path,
      mode ? "0600",
      owner ? null,
      group ? null,
      restartUnits ? [ ],
    }:
    {
      nixos.sops.secrets.${name} = {
        inherit mode path restartUnits;
      }
      // lib.optionalAttrs (owner != null) { inherit owner; }
      // lib.optionalAttrs (group != null) { inherit group; };
    };
}
