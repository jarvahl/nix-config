{ den, ... }:
{
  den.aspects.cargo.provides.nixos-user.includes = [
    den.batteries.primary-user
    (den.batteries.user-shell "zsh")
    den.aspects.development
  ];
}
