{ den, ... }:
{
  den.aspects.apex.provides.jarvahl.includes = [
    den.aspects.development
    den.batteries.primary-user
    (den.batteries.user-shell "zsh")
  ];
}
