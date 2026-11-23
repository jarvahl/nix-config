{ ... }:
{
  den.aspects.rg.hjem = { pkgs, ... }: {
    packages = [ pkgs.ripgrep ];
  };
}
