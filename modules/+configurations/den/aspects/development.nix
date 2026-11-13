{ den, ... }:
{
  den.aspects.development.includes = with den.aspects; [
    direnv
    git
    nvim
    worktrunk
  ];
}
