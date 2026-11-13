{ den, ... }:
{
  den.aspects.clipboard.includes = with den.aspects; [
    pbcopy
    pbpaste
  ];
}
