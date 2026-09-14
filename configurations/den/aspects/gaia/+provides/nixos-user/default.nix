{ den, ... }:
{
  den.aspects.gaia.provides.nixos-user = { ... }: {
    includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")
      den.aspects.development
    ];
  };
}
