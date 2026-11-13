{ ... }:

{
  den.aspects.fzf.hjem =
    { pkgs, ... }:
    {
      packages = [ pkgs.fzf ];
    };
}
